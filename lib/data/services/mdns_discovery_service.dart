import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../../core/utils/logger.dart';

/// Information d'un appareil ECLYPSE découvert via mDNS
class EclypseDevice {
  final String name;
  final String host;
  final int port;
  final String? ipAddress;
  final Map<String, String> txtRecords;

  EclypseDevice({
    required this.name,
    required this.host,
    required this.port,
    this.ipAddress,
    this.txtRecords = const {},
  });

  @override
  String toString() => 'EclypseDevice($name, $host:$port, ip: $ipAddress)';
}

/// Service de découverte mDNS pour les automates ECLYPSE Distech
/// Implémentation manuelle compatible Windows
class MdnsDiscoveryService {
  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _subscription; // Pour cleanup propre

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

    try {
      // Créer le socket UDP
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0, // Port dynamique
        reuseAddress: true,
      );

      // Joindre le groupe multicast
      try {
        _socket!.joinMulticast(InternetAddress(mdnsAddress));
      } catch (e) {
        logger.w('Could not join multicast group: $e');
      }

      // Écouter les réponses avec référence pour cleanup
      _subscription = _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
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
        }
      });

      // Envoyer la requête mDNS pour _eclypse._tcp.local
      final query = _buildMdnsQuery(eclypseServiceType);
      _socket!.send(query, InternetAddress(mdnsAddress), mdnsPort);
      logger.d('mDNS query sent for $eclypseServiceType');

      // Envoyer aussi pour _dcconf._udp.local
      final query2 = _buildMdnsQuery('_dcconf._udp.local');
      _socket!.send(query2, InternetAddress(mdnsAddress), mdnsPort);

      // Attendre les réponses
      await Future.delayed(timeout);

    } catch (e) {
      logger.e('mDNS discovery error: $e');
    } finally {
      // Cleanup propre
      await _subscription?.cancel();
      _subscription = null;
      _socket?.close();
      _socket = null;
    }

    logger.i('mDNS discovery completed: ${devices.length} ECLYPSE found');
    return devices;
  }

  /// Construit une requête DNS pour un type de service
  Uint8List _buildMdnsQuery(String serviceType) {
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

    // Class: IN (1) with QU bit set (0x8001 for unicast response requested)
    builder.addByte(0x00);
    builder.addByte(0x01);

    return builder.toBytes();
  }

  /// Parse une réponse mDNS
  EclypseDevice? _parseMdnsResponse(Uint8List data, InternetAddress sourceAddress) {
    if (data.length < 12) return null;

    // Vérifier que c'est une réponse (bit QR = 1)
    final flags = (data[2] << 8) | data[3];
    if ((flags & 0x8000) == 0) return null; // Pas une réponse

    final answerCount = (data[6] << 8) | data[7];
    if (answerCount == 0) return null;

    // Parser les réponses pour extraire les infos
    String? deviceName;
    String? targetHost;
    int port = 443;
    String? ipAddress = sourceAddress.address;

    int offset = 12;

    // Skip questions
    final questionCount = (data[4] << 8) | data[5];
    for (int i = 0; i < questionCount && offset < data.length; i++) {
      offset = _skipName(data, offset);
      offset += 4; // Type + Class
    }

    // Parse answers
    for (int i = 0; i < answerCount && offset < data.length - 10; i++) {
      final nameEnd = _skipName(data, offset);
      // final name = _readName(data, offset); // Pour debug
      offset = nameEnd;

      if (offset + 10 > data.length) break;

      final type = (data[offset] << 8) | data[offset + 1];
      offset += 2;
      // final classCode = (data[offset] << 8) | data[offset + 1];
      offset += 2;
      // final ttl = (data[offset] << 24) | (data[offset + 1] << 16) | (data[offset + 2] << 8) | data[offset + 3];
      offset += 4;
      final rdLength = (data[offset] << 8) | data[offset + 1];
      offset += 2;

      if (offset + rdLength > data.length) break;

      switch (type) {
        case 12: // PTR
          final ptrName = _readName(data, offset);
          if (ptrName.contains('_eclypse') || ptrName.contains('_dcconf')) {
            // Extraire le nom de l'appareil (partie avant ._eclypse)
            final parts = ptrName.split('._');
            if (parts.isNotEmpty) {
              deviceName = parts[0];
            }
          }
          break;
        case 33: // SRV
          if (offset + 6 <= data.length) {
            // final priority = (data[offset] << 8) | data[offset + 1];
            // final weight = (data[offset + 2] << 8) | data[offset + 3];
            port = (data[offset + 4] << 8) | data[offset + 5];
            targetHost = _readName(data, offset + 6);
          }
          break;
        case 1: // A (IPv4)
          if (rdLength == 4) {
            ipAddress = '${data[offset]}.${data[offset + 1]}.${data[offset + 2]}.${data[offset + 3]}';
          }
          break;
      }

      offset += rdLength;
    }

    // Si on a trouvé un appareil ECLYPSE
    if (deviceName != null || (targetHost != null && targetHost.isNotEmpty)) {
      return EclypseDevice(
        name: deviceName ?? targetHost ?? 'ECLYPSE',
        host: targetHost ?? sourceAddress.address,
        port: port,
        ipAddress: ipAddress,
      );
    }

    return null;
  }

  /// Lit un nom DNS compressé
  String _readName(Uint8List data, int offset) {
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
  int _skipName(Uint8List data, int offset) {
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
    _subscription?.cancel();
    _subscription = null;
    _socket?.close();
    _socket = null;
  }
}
