import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../core/utils/logger.dart';

/// Information d'un appareil ECLYPSE découvert via mDNS
///
/// Contenu réel des annonces (relevé sur le parc de test) :
/// - ECLYPSE « historiques » (`_dcconf._udp`) : SRV port 80, TXT
///   `restUrl=/api/rest/v1/`, `mac`, `access=<port http>;<port https>`
///   (-1 = désactivé), `type=Eclypse`, `vendor=Distech Controls`.
/// - ECLYPSE nouvelle génération (`_eclypse._tcp`) : SRV port 443, TXT
///   `model=<code produit>`, `mac`.
/// Aucune annonce ne contient la version du firmware.
class EclypseDevice {
  final String name;
  final String host;

  /// Port annoncé dans l'enregistrement SRV (80 pour `_dcconf`, qui ne
  /// reflète pas le port HTTPS : utiliser [connectionPort]).
  final int port;
  final String? ipAddress;
  final Map<String, String> txtRecords;

  /// Type de service mDNS qui a répondu (`_eclypse._tcp` ou `_dcconf._udp`).
  final String? serviceType;

  EclypseDevice({
    required this.name,
    required this.host,
    required this.port,
    this.ipAddress,
    this.txtRecords = const {},
    this.serviceType,
  });

  String? _txt(List<String> keys) {
    for (final key in keys) {
      final value = txtRecords[key];
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// Modèle ou code produit annoncé (TXT `model`), s'il est présent.
  String? get model => _txt(const ['model', 'product', 'md']);

  /// Version du firmware, si l'appareil l'annonce (non observé à ce jour).
  String? get firmwareVersion => _txt(const [
        'firmware',
        'firmwareversion',
        'fwversion',
        'fw',
        'swversion',
        'version',
      ]);

  String? get macAddress => _txt(const ['mac']);
  String? get vendor => _txt(const ['vendor']);
  String? get deviceType => _txt(const ['type']);

  /// URL REST annoncée (TXT `restUrl`), ex. `/api/rest/v1/`.
  String? get restUrl => _txt(const ['resturl']);

  /// Version d'API indiquée par `restUrl` ('V1' / 'V2'). Indicatif
  /// seulement : un ECLYPSE compatible V2 peut annoncer `/api/rest/v1/`.
  String? get advertisedApiVersion {
    final url = restUrl?.toLowerCase();
    if (url == null) return null;
    final match = RegExp(r'/v(\d+)\b').firstMatch(url);
    return match == null ? null : 'V${match.group(1)}';
  }

  /// Ports HTTP / HTTPS du TXT `access=<http>;<https>` (null si désactivé
  /// ou absent).
  (int?, int?) get _accessPorts {
    final access = _txt(const ['access']);
    if (access == null) return (null, null);
    final parts = access.split(';');
    int? parse(int i) {
      if (i >= parts.length) return null;
      final v = int.tryParse(parts[i].trim());
      return v != null && v > 0 && v <= 65535 ? v : null;
    }

    return (parse(0), parse(1));
  }

  int? get httpPort => _accessPorts.$1;
  int? get httpsPort => _accessPorts.$2;

  /// HTTPS sauf si l'appareil annonce HTTP seul.
  bool get prefersHttps {
    final (http, https) = _accessPorts;
    if (https != null) return true;
    if (http != null) return false;
    return port != 80;
  }

  /// Port à utiliser pour la connexion REST.
  int get connectionPort {
    final (http, https) = _accessPorts;
    if (https != null) return https;
    if (http != null) return http;
    if (port == 80) return 80;
    return port > 0 ? port : 443;
  }

  /// Adresse à utiliser pour la connexion (IP de préférence).
  String get address => ipAddress ?? host;

  @override
  String toString() => 'EclypseDevice($name, $host:$port, ip: $ipAddress, txt: $txtRecords)';
}

/// Service de découverte mDNS pour les automates ECLYPSE Distech
/// Implémentation manuelle compatible Windows
class MdnsDiscoveryService {
  final List<RawDatagramSocket> _sockets = [];
  final List<StreamSubscription<RawSocketEvent>> _subscriptions = []; // Pour cleanup propre

  /// Adresse multicast mDNS
  static const String mdnsAddress = '224.0.0.251';
  static const int mdnsPort = 5353;

  /// Types de services à rechercher
  static const String eclypseServiceType = '_eclypse._tcp.local';

  /// Découvre les appareils ECLYPSE sur le réseau local via mDNS
  Future<List<EclypseDevice>> discoverEclypseDevices({
    Duration timeout = const Duration(seconds: 5),
    void Function(EclypseDevice device)? onDeviceFound,
  }) async {
    final devices = <EclypseDevice>[];
    final deviceNames = <String>{};

    logger.i('Starting mDNS discovery for ECLYPSE devices...');

    void onDatagram(Datagram datagram) {
      try {
        final device = _parseMdnsResponse(datagram.data, datagram.address);
        if (device != null && !deviceNames.contains(device.name)) {
          deviceNames.add(device.name);
          devices.add(device);
          logger.i('Discovered ECLYPSE: ${device.name} at ${device.ipAddress}');
          onDeviceFound?.call(device);
        }
      } catch (e) {
        // Ignorer les paquets non parsables
      }
    }

    try {
      // Un socket par interface IPv4 : sous Windows (VPN, Tailscale,
      // plusieurs cartes) l'interface multicast par défaut n'est souvent pas
      // celle du réseau des automates. Les requêtes ont le bit QU, les
      // réponses reviennent donc en unicast sur le socket émetteur.
      final addresses = <InternetAddress>[InternetAddress.anyIPv4];
      try {
        final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback && !addr.address.startsWith('169.254.')) {
              addresses.add(addr);
            }
          }
        }
      } catch (e) {
        logger.w('mDNS: could not list network interfaces: $e');
      }

      final queries = [
        buildMdnsQuery(eclypseServiceType),
        buildMdnsQuery('_dcconf._udp.local'),
      ];

      for (final address in addresses) {
        try {
          final socket = await RawDatagramSocket.bind(address, 0, reuseAddress: true);
          _sockets.add(socket);
          try {
            socket.joinMulticast(InternetAddress(mdnsAddress));
          } catch (e) {
            // Non bloquant : les réponses QU arrivent en unicast
          }
          _subscriptions.add(socket.listen((event) {
            if (event == RawSocketEvent.read) {
              final datagram = socket.receive();
              if (datagram != null) onDatagram(datagram);
            }
          }));
          for (final query in queries) {
            socket.send(query, InternetAddress(mdnsAddress), mdnsPort);
          }
          logger.d('mDNS query sent from ${address.address}');
        } catch (e) {
          logger.w('mDNS: could not query from ${address.address}: $e');
        }
      }

      // Attendre les réponses
      await Future.delayed(timeout);
    } catch (e) {
      logger.e('mDNS discovery error: $e');
    } finally {
      stop();
    }

    logger.i('mDNS discovery completed: ${devices.length} ECLYPSE found');
    return devices;
  }

  /// Construit une requête DNS pour un type de service
  static Uint8List buildMdnsQuery(String serviceType) {
    final builder = BytesBuilder();

    // Header DNS
    builder.addByte(0x00); // Transaction ID (2 bytes)
    builder.addByte(0x00);
    builder.addByte(0x00); // Flags: Standard query
    builder.addByte(0x00);
    builder.addByte(0x00); // Questions: 1
    builder.addByte(0x01);
    builder.addByte(0x00); // Answer RRs: 0
    builder.addByte(0x00);
    builder.addByte(0x00); // Authority RRs: 0
    builder.addByte(0x00);
    builder.addByte(0x00); // Additional RRs: 0
    builder.addByte(0x00);

    // Question section - encode the service name
    final parts = serviceType.split('.');
    for (final part in parts) {
      builder.addByte(part.length);
      builder.add(part.codeUnits);
    }
    builder.addByte(0x00); // Null terminator

    // Type: PTR (12)
    builder.addByte(0x00);
    builder.addByte(0x0C);

    // Class: IN (1) with QU bit set (0x8001 for unicast response requested).
    // Sans le bit QU, les ECLYPSE historiques (_dcconf) ne répondent pas au
    // port source de la requête.
    builder.addByte(0x80);
    builder.addByte(0x01);

    return builder.toBytes();
  }

  EclypseDevice? _parseMdnsResponse(Uint8List data, InternetAddress sourceAddress) =>
      parseMdnsPacket(data, sourceAddress.address);

  /// Parse une réponse mDNS d'un ECLYPSE.
  ///
  /// Lit toutes les sections (réponses, autorité, additionnelles) : les
  /// ECLYPSE `_dcconf._udp` placent SRV, TXT et A dans la section
  /// additionnelle. Retourne null si le paquet n'annonce pas d'ECLYPSE.
  static EclypseDevice? parseMdnsPacket(Uint8List data, String sourceAddress) {
    if (data.length < 12) return null;

    // Vérifier que c'est une réponse (bit QR = 1)
    final flags = (data[2] << 8) | data[3];
    if ((flags & 0x8000) == 0) return null; // Pas une réponse

    final questionCount = (data[4] << 8) | data[5];
    final recordCount = ((data[6] << 8) | data[7]) +
        ((data[8] << 8) | data[9]) +
        ((data[10] << 8) | data[11]);
    if (recordCount == 0) return null;

    String? instanceName; // ex. CHAUFFERIE._dcconf._udp.local
    String? serviceType;
    String? targetHost;
    int? port;
    final txt = <String, String>{};
    final aRecords = <String, String>{}; // nom d'hôte -> IPv4

    int offset = 12;

    // Skip questions
    for (int i = 0; i < questionCount && offset < data.length; i++) {
      offset = _skipName(data, offset);
      offset += 4; // Type + Class
    }

    final records = <({String owner, int type, int start, int length})>[];
    for (int i = 0; i < recordCount && offset < data.length; i++) {
      final owner = _readName(data, offset);
      offset = _skipName(data, offset);
      if (offset + 10 > data.length) break;

      final type = (data[offset] << 8) | data[offset + 1];
      final rdLength = (data[offset + 8] << 8) | data[offset + 9];
      offset += 10; // type, class, ttl, rdlength
      if (offset + rdLength > data.length) break;

      records.add((owner: owner, type: type, start: offset, length: rdLength));
      offset += rdLength;
    }

    // PTR d'abord : il désigne l'instance dont on garde SRV et TXT
    for (final r in records) {
      if (r.type != 12) continue;
      final ptrName = _readName(data, r.start);
      final lower = ptrName.toLowerCase();
      if (lower.contains('._eclypse._tcp') || lower.contains('._dcconf._udp')) {
        instanceName = ptrName;
        serviceType = lower.contains('._eclypse._tcp') ? '_eclypse._tcp' : '_dcconf._udp';
        break;
      }
    }

    bool isInstance(String owner) =>
        instanceName == null || owner.toLowerCase() == instanceName.toLowerCase();

    for (final r in records) {
      switch (r.type) {
        case 33: // SRV
          if (r.length >= 6 && isInstance(r.owner) &&
              (instanceName != null || _isEclypseService(r.owner))) {
            port = (data[r.start + 4] << 8) | data[r.start + 5];
            targetHost = _readName(data, r.start + 6);
            instanceName ??= r.owner;
          }
          break;
        case 16: // TXT
          if (isInstance(r.owner) &&
              (instanceName != null || _isEclypseService(r.owner))) {
            txt.addAll(parseTxtRecord(data.sublist(r.start, r.start + r.length)));
          }
          break;
        case 1: // A (IPv4)
          if (r.length == 4) {
            aRecords[r.owner.toLowerCase()] =
                '${data[r.start]}.${data[r.start + 1]}.${data[r.start + 2]}.${data[r.start + 3]}';
          }
          break;
      }
    }

    if (instanceName == null) return null;
    serviceType ??= instanceName.toLowerCase().contains('._eclypse._tcp')
        ? '_eclypse._tcp'
        : '_dcconf._udp';

    // Nom de l'appareil : partie avant ._eclypse / ._dcconf
    final name = instanceName.split('._').first;
    final ipAddress = (targetHost != null ? aRecords[targetHost.toLowerCase()] : null) ??
        (aRecords.length == 1 ? aRecords.values.first : null) ??
        sourceAddress;

    return EclypseDevice(
      name: name.isNotEmpty ? name : (targetHost ?? 'ECLYPSE'),
      host: (targetHost != null && targetHost.isNotEmpty) ? targetHost : sourceAddress,
      port: port ?? 443,
      ipAddress: ipAddress,
      txtRecords: txt,
      serviceType: serviceType,
    );
  }

  static bool _isEclypseService(String name) {
    final lower = name.toLowerCase();
    return lower.contains('._eclypse._tcp') || lower.contains('._dcconf._udp');
  }

  /// Décode les données d'un enregistrement TXT (chaînes `clé=valeur`
  /// préfixées par leur longueur). Les clés sont mises en minuscules
  /// (insensibles à la casse, RFC 6763 §6.4).
  static Map<String, String> parseTxtRecord(Uint8List rdata) {
    final result = <String, String>{};
    var i = 0;
    while (i < rdata.length) {
      final length = rdata[i];
      i++;
      if (length == 0) continue;
      if (i + length > rdata.length) break;
      final entry = utf8.decode(rdata.sublist(i, i + length), allowMalformed: true);
      i += length;
      final eq = entry.indexOf('=');
      final key = (eq < 0 ? entry : entry.substring(0, eq)).trim().toLowerCase();
      if (key.isEmpty || result.containsKey(key)) continue; // 1re occurrence
      result[key] = eq < 0 ? '' : entry.substring(eq + 1);
    }
    return result;
  }

  /// Lit un nom DNS compressé
  static String _readName(Uint8List data, int offset) {
    final parts = <String>[];
    var currentOffset = offset;
    var maxJumps = 10;

    while (currentOffset < data.length && maxJumps > 0) {
      final length = data[currentOffset];

      if (length == 0) {
        break;
      }

      // Compression pointer
      if ((length & 0xC0) == 0xC0) {
        if (currentOffset + 1 >= data.length) break;
        final pointer = ((length & 0x3F) << 8) | data[currentOffset + 1];
        currentOffset = pointer;
        maxJumps--;
        continue;
      }

      currentOffset++;
      if (currentOffset + length > data.length) break;

      final part = String.fromCharCodes(data.sublist(currentOffset, currentOffset + length));
      parts.add(part);
      currentOffset += length;
    }

    return parts.join('.');
  }

  /// Skip un nom DNS et retourne l'offset après
  static int _skipName(Uint8List data, int offset) {
    while (offset < data.length) {
      final length = data[offset];
      if (length == 0) {
        return offset + 1;
      }
      if ((length & 0xC0) == 0xC0) {
        return offset + 2;
      }
      offset += length + 1;
    }
    return offset;
  }

  /// Arrête la découverte en cours
  void stop() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    for (final socket in _sockets) {
      socket.close();
    }
    _sockets.clear();
  }
}
