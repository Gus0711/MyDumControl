import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'package:logger/logger.dart';

import 'bacnet/bacnet_constants.dart';
import 'bacnet/bacnet_encoder.dart';
import 'bacnet/bacnet_decoder.dart';
import 'bacnet/bacnet_network.dart';
import '../../domain/models/bacnet_object.dart';
import '../../domain/models/network_interface_choice.dart';

// Re-export pour usage externe
export 'bacnet/bacnet_encoder.dart' show ReadRangeType, BacnetTimeValue, BacnetDailySchedule, BacnetWeeklySchedule, ScheduleValueTag;
export 'bacnet/bacnet_decoder.dart'
    show TrendLogRecordData, ReadRangeResult, DecodedTimeValue, DecodedDailySchedule, DecodedWeeklySchedule, BacnetScheduleDecoder;

final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

/// Résultat d'un test de connexion BACnet
class BacnetConnectionResult {
  final bool success;
  final int? deviceId;
  final String? deviceName;
  final String? vendorName;
  final String? modelName;
  final String? errorMessage;

  BacnetConnectionResult({required this.success, this.deviceId, this.deviceName, this.vendorName, this.modelName, this.errorMessage});
}

/// Service BACnet/IP en Dart pur
/// Supporte ReadProperty, WriteProperty, ReadPropertyMultiple, Who-Is
class BacnetService {
  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _socketSubscription;
  int _invokeId = 0;

  /// Pending confirmed requests, keyed by "peerIp#invokeId"
  final Map<String, _PendingRequest> _pendingRequests = {};

  /// Per-device limit of simultaneous confirmed requests
  final Map<String, _Semaphore> _deviceSemaphores = {};
  static const int maxConcurrentRequestsPerDevice = 4;

  /// Retries after a timeout (ASHRAE 135 Number_Of_APDU_Retries)
  final int _retries;

  final Duration _timeout;
  bool _isInitialized = false;

  /// Shared future of the init in progress (concurrent callers await it)
  Future<void>? _initFuture;

  // Multi-homing : interface réseau sélectionnée
  NetworkInterfaceChoice? _boundInterface;

  // Détection conflits Device ID
  final Map<int, IAmInfo> _seenDevices = {};
  final _conflictController = StreamController<DeviceIdConflict>.broadcast();

  /// Every I-Am received, without de-duplication (used by whoIs)
  final _rawIAmController = StreamController<IAmInfo>.broadcast();

  /// Devices that rejected ReadPropertyMultiple (unrecognized-service)
  final Set<String> _rpmUnsupportedHosts = {};

  /// Short-lived object-list cache, keyed by "host:port:deviceId"
  final Map<String, ({DateTime readAt, List<_ObjectInfo> objects})> _objectListCache = {};
  static const Duration _objectListCacheTtl = Duration(minutes: 2);

  // Info port BACnet
  static const int standardBacnetPort = 47808;
  bool _isUsingStandardPort = false;
  int? _actualPort;

  BacnetService({Duration timeout = const Duration(seconds: 5), int retries = 1}) : _timeout = timeout, _retries = retries;

  /// Interface réseau actuellement utilisée (null = toutes)
  NetworkInterfaceChoice? get boundInterface => _boundInterface;

  /// Stream des conflits Device ID détectés
  Stream<DeviceIdConflict> get conflictStream => _conflictController.stream;

  /// Indique si le service utilise le port BACnet standard (47808)
  /// Si false, certains devices peuvent ne pas répondre
  bool get isUsingStandardPort => _isUsingStandardPort;

  /// Port UDP actuellement utilisé (null si pas initialisé)
  int? get actualPort => _actualPort;

  /// Initialise le socket UDP
  /// Utilise le port 47808 (BACnet standard) comme port source pour la découverte
  /// Certains devices ne répondent qu'aux requêtes venant de ce port
  /// [bindInterface] : Si spécifié, découverte limitée à cette interface réseau
  ///
  /// Concurrent calls share the same future; if the bind fails, every
  /// caller gets the error and the next call tries again.
  Future<void> init({NetworkInterfaceChoice? bindInterface}) {
    if (_isInitialized) return Future.value();
    final pending = _initFuture;
    if (pending != null) return pending;

    final future = _doInit(bindInterface);
    _initFuture = future;
    return future.whenComplete(() {
      if (identical(_initFuture, future)) _initFuture = null;
    });
  }

  Future<void> _doInit(NetworkInterfaceChoice? bindInterface) async {
    // Linux/macOS/Android: a socket bound to a unicast IP does not receive
    // datagrams sent to the broadcast address (I-Am replies are often
    // broadcast). Bind on 0.0.0.0 and use the selected interface only to
    // choose the broadcast addresses. Windows delivers broadcasts to a socket
    // bound to the interface IP, which also pins the outgoing interface.
    final bindOnInterfaceIp = bindInterface != null && Platform.isWindows;
    final bindAddress = bindOnInterfaceIp ? InternetAddress(bindInterface.address) : InternetAddress.anyIPv4;

    // Essayer d'abord le port BACnet standard 47808 (meilleure compatibilité)
    // Si déjà utilisé, fallback sur un port dynamique
    RawDatagramSocket socket;
    bool standardPort;
    try {
      socket = await RawDatagramSocket.bind(bindAddress, standardBacnetPort, reuseAddress: true);
      standardPort = true;
    } catch (e) {
      _logger.w('Could not bind to port $standardBacnetPort: $e. Using dynamic port.');
      socket = await RawDatagramSocket.bind(bindAddress, 0);
      standardPort = false;
      _logger.w('BACnet service using non-standard port ${socket.port} - some devices may not respond');
    }

    socket.broadcastEnabled = true; // Activer le broadcast pour Who-Is
    _socket = socket;
    _boundInterface = bindInterface;
    _isUsingStandardPort = standardPort;
    _actualPort = socket.port;
    _socketSubscription = socket.listen(_handleSocketEvent);
    _isInitialized = true;
    _logger.i(
      'BACnet service bound to ${bindAddress.address}:${socket.port} '
      '(interface: ${bindInterface?.address ?? "all"}), broadcast enabled',
    );
  }

  /// Ferme le socket et fait échouer les requêtes en attente
  Future<void> _closeSocket(String reason) async {
    // Let an init in progress finish so its socket is closed too
    final pendingInit = _initFuture;
    if (pendingInit != null) {
      try {
        await pendingInit;
      } catch (_) {
        // Init failed: nothing to close
      }
    }

    final subscription = _socketSubscription;
    _socketSubscription = null;
    _socket?.close();
    _socket = null;
    _isInitialized = false;
    _boundInterface = null;
    _isUsingStandardPort = false;
    _actualPort = null;
    _objectListCache.clear();
    _failAllPending(reason);
    await subscription?.cancel();
  }

  void _failAllPending(String reason) {
    final pending = _pendingRequests.values.toList();
    _pendingRequests.clear();
    for (final request in pending) {
      request.timer?.cancel();
      if (!request.completer.isCompleted) {
        request.completer.complete(BacnetResponse.error(reason));
      }
    }
  }

  /// Réinitialise le service sur une nouvelle interface réseau
  /// Note: Ne ferme pas les StreamControllers pour permettre aux listeners de continuer
  Future<void> rebindToInterface(NetworkInterfaceChoice? newInterface) async {
    _logger.i('Rebinding BACnet service to ${newInterface?.address ?? "all interfaces"}');

    // Fermer seulement le socket, pas les controllers
    await _closeSocket('Socket rebound to another interface');
    await init(bindInterface: newInterface);
  }

  /// Ferme le socket et libère les ressources
  void dispose() {
    final subscription = _socketSubscription;
    _socketSubscription = null;
    subscription?.cancel();
    _socket?.close();
    _socket = null;
    _isInitialized = false;
    _boundInterface = null;
    _isUsingStandardPort = false;
    _actualPort = null;
    _failAllPending('BACnet service disposed');
    _seenDevices.clear();
    _objectListCache.clear();
    for (final controller in [_iAmController, _rawIAmController, _routerController, _conflictController]) {
      if (!controller.isClosed) controller.close();
    }
    _logger.d('BACnet service disposed');
  }

  /// Réinitialise le cache des devices vus (avant une nouvelle découverte)
  void clearSeenDevices() {
    _seenDevices.clear();
    _logger.d('Cleared seen devices cache');
  }

  /// Vérifie que le service est initialisé
  void _ensureInitialized() {
    if (!_isInitialized || _socket == null) {
      throw StateError('BacnetService not initialized. Call init() first.');
    }
  }

  static String _requestKey(String ip, int invokeId) => '$ip#$invokeId';

  /// Allocates an invoke ID that is not in use for this peer
  int _nextInvokeId(String ip) {
    for (int i = 0; i < 256; i++) {
      _invokeId = (_invokeId + 1) & 0xFF;
      if (!_pendingRequests.containsKey(_requestKey(ip, _invokeId))) {
        return _invokeId;
      }
    }
    throw StateError('No free invoke ID for $ip');
  }

  // =========================================================================
  // Reception
  // =========================================================================

  void _handleSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;

    // Read every queued datagram (a burst of I-Am can queue several)
    while (true) {
      final socket = _socket;
      if (!_isInitialized || socket == null) return;
      final datagram = socket.receive();
      if (datagram == null) return;
      _handleDatagram(datagram);
    }
  }

  /// Gère un datagramme UDP entrant
  void _handleDatagram(Datagram datagram) {
    final data = datagram.data;

    // Filtre rapide: paquets trop courts ou non BACnet/IP
    if (data.length < 6 || data[0] != bvlcTypeBacnetIp) return;

    // 0x0a = Original-Unicast-NPDU, 0x0b = Original-Broadcast-NPDU,
    // 0x04 = Forwarded-NPDU (BBMD). Autres = gestion BVLC, ignorés
    final bvlcFunc = data[1];
    if (bvlcFunc != BvlcFunction.originalUnicastNpdu &&
        bvlcFunc != BvlcFunction.originalBroadcastNpdu &&
        bvlcFunc != BvlcFunction.forwardedNpdu) {
      return;
    }

    final BacnetFrame? frame;
    try {
      frame = BacnetDecoder.parseFrame(data);
    } catch (e) {
      _logger.d('Malformed BACnet frame from ${datagram.address.address}: $e');
      return;
    }
    if (frame == null) return;

    // A Forwarded-NPDU carries the address of the originating device
    final sourceAddress = frame.originAddress != null ? InternetAddress(frame.originAddress!) : datagram.address;
    final sourcePort = frame.originPort ?? datagram.port;

    if (frame.isNetworkLayerMessage) {
      _handleNetworkLayerMessage(data, frame.apduOffset, sourceAddress);
      return;
    }

    final apduOffset = frame.apduOffset;
    if (apduOffset >= data.length) return;
    final pduType = data[apduOffset] & 0xF0;

    if (pduType == ApduType.unconfirmedRequest) {
      try {
        final response = BacnetDecoder.decodeApdu(data, apduOffset);
        if (response.type == BacnetResponseType.iAm) {
          _logger.i('I-Am received from ${sourceAddress.address}:$sourcePort, deviceId: ${response.objectInstance}');
          _handleIAm(response, sourceAddress, sourcePort, frame.npdu);
        }
        // Autres unconfirmedRequests (COV, Who-Is relayés...) ignorés
      } catch (e) {
        _logger.d('Failed to decode unconfirmed request from ${sourceAddress.address}: $e');
      }
      return;
    }

    // Confirmed service responses: correlate on (source address, invokeId)
    if (pduType != ApduType.complexAck &&
        pduType != ApduType.simpleAck &&
        pduType != ApduType.error &&
        pduType != ApduType.reject &&
        pduType != ApduType.abort) {
      return;
    }
    if (apduOffset + 1 >= data.length) return;
    final invokeId = data[apduOffset + 1];
    final request = _pendingRequests[_requestKey(sourceAddress.address, invokeId)];
    if (request == null || request.completer.isCompleted) return;

    if (pduType == ApduType.complexAck && (data[apduOffset] & 0x08) != 0) {
      _handleSegment(request, data, apduOffset);
      return;
    }

    BacnetResponse response;
    try {
      response = BacnetDecoder.decodeApdu(data, apduOffset);
    } catch (e) {
      response = BacnetResponse.error('Malformed response: $e');
    }

    if (response.isError) {
      _logger.w(
        'BACnet error response: type=${response.type}, class=${response.errorClass}, code=${response.errorCode}, msg=${response.errorMessage}',
      );
    }

    // Abort out-of-resources: the device is busy, try again if allowed
    if (response.type == BacnetResponseType.abort && response.errorCode == _abortOutOfResources && request.attempts <= _retries) {
      _logger.d('Device busy (Abort out-of-resources), retrying invokeId $invokeId');
      _transmit(request);
      return;
    }

    _completeRequest(request, response);
  }

  static const int _abortOutOfResources = 9;

  /// Handles one segment of a segmented ComplexACK and sends the SegmentACK.
  /// The actual window size is 1: every segment is acknowledged.
  void _handleSegment(_PendingRequest request, Uint8List data, int apduOffset) {
    final header = BacnetDecoder.parseSegmentHeader(data, apduOffset);
    if (header == null) return;

    final socket = _socket;
    if (socket == null) return;

    if (request.segments == null) {
      if (header.sequenceNumber != 0) {
        return; // Wait for the first segment
      }
      request.segments = BytesBuilder(copy: false);
      request.segmentServiceChoice = header.serviceChoice;
      request.expectedSequence = 0;
    }

    final expected = request.expectedSequence;
    if (header.sequenceNumber != expected) {
      // Duplicate or out of order: NAK with the last segment received in order
      socket.send(
        BacnetEncoder.encodeSegmentAck(invokeId: header.invokeId, sequenceNumber: (expected - 1) & 0xFF, windowSize: 1, negative: true),
        request.address,
        request.port,
      );
      return;
    }

    request.segments!.add(data.sublist(header.payloadOffset));
    request.expectedSequence = (expected + 1) & 0xFF;
    socket.send(
      BacnetEncoder.encodeSegmentAck(invokeId: header.invokeId, sequenceNumber: header.sequenceNumber, windowSize: 1),
      request.address,
      request.port,
    );

    if (header.moreFollows) {
      // Wait for the next segment (restart the timeout)
      _armTimer(request);
      return;
    }

    final payload = request.segments!.takeBytes();
    _logger.d('Segmented response reassembled: ${payload.length} bytes, invokeId ${header.invokeId}');
    _completeRequest(
      request,
      BacnetDecoder.decodeReassembledComplexAck(
        invokeId: header.invokeId,
        serviceChoice: request.segmentServiceChoice ?? header.serviceChoice,
        payload: payload,
      ),
    );
  }

  /// Gère les Network Layer Messages (I-Am-Router-To-Network, etc.)
  /// [offset] is the position of the message type, right after the NPDU header.
  void _handleNetworkLayerMessage(Uint8List data, int offset, InternetAddress address) {
    if (offset >= data.length) return;

    final messageType = data[offset];

    // I-Am-Router-To-Network (0x01)
    if (messageType == NetworkLayerMessageType.iAmRouterToNetwork) {
      // Parse les numéros de réseau (2 bytes chacun)
      final networks = <int>[];
      int pos = offset + 1;
      while (pos + 1 < data.length) {
        final networkNumber = (data[pos] << 8) | data[pos + 1];
        networks.add(networkNumber);
        pos += 2;
      }

      if (networks.isNotEmpty && !_routerController.isClosed) {
        _logger.i('I-Am-Router-To-Network from ${address.address}: networks=$networks');
        _routerController.add(RouterInfo(address: address, networks: networks));
      }
    }
  }

  /// Gère les messages I-Am (pour la découverte)
  final _iAmController = StreamController<IAmInfo>.broadcast();

  /// I-Am of devices not seen since the last [clearSeenDevices], plus
  /// updates when a Device ID conflict is detected.
  Stream<IAmInfo> get iAmStream => _iAmController.stream;

  /// Gère les messages I-Am-Router-To-Network
  final _routerController = StreamController<RouterInfo>.broadcast();
  Stream<RouterInfo> get routerStream => _routerController.stream;

  void _handleIAm(BacnetResponse response, InternetAddress address, int port, NpduHeader npdu) {
    if (response.objectInstance == null) return;

    final deviceId = response.objectInstance!;
    final info = IAmInfo(address: address, deviceId: deviceId, port: port, networkNumber: npdu.sourceNetwork, macAddress: npdu.sourceMac);

    if (!_rawIAmController.isClosed) {
      _rawIAmController.add(info);
    }

    if (_iAmController.isClosed) {
      _logger.w('_handleIAm: iAmController is CLOSED! Cannot emit device $deviceId');
      return;
    }

    final existingDevice = _seenDevices[deviceId];

    if (existingDevice != null) {
      // Device ID déjà vu: ignorer les I-Am répétés d'une adresse connue
      if (existingDevice.knowsAddress(address)) return;

      // CONFLIT : Même deviceId, adresse IP différente
      _logger.w(
        'CONFLIT Device ID $deviceId: '
        '${existingDevice.address.address} ET ${address.address}',
      );

      final updatedDevice = existingDevice.withConflict(address);
      _seenDevices[deviceId] = updatedDevice;

      if (!_conflictController.isClosed) {
        _conflictController.add(
          DeviceIdConflict(
            deviceId: deviceId,
            firstAddress: existingDevice.address,
            secondAddress: address,
            allAddresses: updatedDevice.allAddresses,
          ),
        );
      }

      // Émettre aussi sur iAmStream pour mise à jour UI
      _iAmController.add(updatedDevice);
      return;
    }

    // Nouveau device
    _seenDevices[deviceId] = info;
    _logger.d('_handleIAm: Emitting new device $deviceId to iAmStream');
    _iAmController.add(info);
  }

  // =========================================================================
  // Emission / correlation
  // =========================================================================

  /// Sends a confirmed request and waits for its answer.
  ///
  /// [buildPacket] receives the invoke ID allocated for this peer. The
  /// request is resent with the same invoke ID after a timeout ([_retries]
  /// times). At most [maxConcurrentRequestsPerDevice] requests are in flight
  /// per device. Never throws: failures are returned as a [BacnetResponse]
  /// (type timeout when the device does not answer).
  Future<BacnetResponse> _sendConfirmed(String host, int port, Uint8List Function(int invokeId) buildPacket) async {
    try {
      await init();
      _ensureInitialized();
    } catch (e) {
      return BacnetResponse.error('BACnet socket not available: $e');
    }

    final InternetAddress address;
    try {
      address = InternetAddress(host);
    } catch (e) {
      return BacnetResponse.error('Invalid address $host: $e');
    }

    final semaphore = _deviceSemaphores.putIfAbsent(address.address, () => _Semaphore(maxConcurrentRequestsPerDevice));
    await semaphore.acquire();
    try {
      if (!_isInitialized || _socket == null) {
        return BacnetResponse.error('BACnet socket closed');
      }
      final invokeId = _nextInvokeId(address.address);
      final request = _PendingRequest(
        key: _requestKey(address.address, invokeId),
        invokeId: invokeId,
        packet: buildPacket(invokeId),
        address: address,
        port: port,
      );
      _pendingRequests[request.key] = request;
      _transmit(request);
      return await request.completer.future;
    } catch (e) {
      return BacnetResponse.error('Error sending request: $e');
    } finally {
      semaphore.release();
    }
  }

  void _transmit(_PendingRequest request) {
    final socket = _socket;
    if (socket == null) {
      _completeRequest(request, BacnetResponse.error('BACnet socket closed'));
      return;
    }
    request.attempts++;
    try {
      socket.send(request.packet, request.address, request.port);
      _logger.d(
        'BACnet request sent to ${request.address.address}:${request.port}, '
        'invokeId: ${request.invokeId}, attempt ${request.attempts}',
      );
    } catch (e) {
      _completeRequest(request, BacnetResponse.error('Error sending request: $e'));
      return;
    }
    _armTimer(request);
  }

  void _armTimer(_PendingRequest request) {
    request.timer?.cancel();
    request.timer = Timer(_timeout, () => _onTimeout(request));
  }

  void _onTimeout(_PendingRequest request) {
    if (request.completer.isCompleted) return;
    // Retry only if no segment has been received (otherwise the device's
    // transaction state machine is mid-way and a resend would be ambiguous)
    if (request.segments == null && request.attempts <= _retries) {
      _logger.w('BACnet timeout for invokeId ${request.invokeId} to ${request.address.address}, retrying');
      _transmit(request);
      return;
    }
    _logger.w(
      'BACnet TIMEOUT for invokeId: ${request.invokeId} to ${request.address.address} '
      '(after ${request.attempts} attempt(s) of ${_timeout.inSeconds}s)',
    );
    _completeRequest(request, BacnetResponse.timeout());
  }

  void _completeRequest(_PendingRequest request, BacnetResponse response) {
    request.timer?.cancel();
    // Remove only this request (the key may have been reused afterwards)
    if (identical(_pendingRequests[request.key], request)) {
      _pendingRequests.remove(request.key);
    }
    if (!request.completer.isCompleted) {
      request.completer.complete(response);
    }
  }

  // =========================================================================
  // Public API
  // =========================================================================

  /// Test de connexion BACnet
  /// Essaie de lire les propriétés du device object
  /// Optimisé: utilise ReadPropertyMultiple pour une seule requête au lieu de 3
  Future<BacnetConnectionResult> testConnection({required String host, required int port, int? deviceId}) async {
    await init();

    try {
      // Si deviceId n'est pas fourni, essayer de le trouver via Who-Is
      int? targetDeviceId = deviceId;

      if (targetDeviceId == null) {
        // Envoyer Who-Is et attendre I-Am
        final devices = await whoIs(host: host, port: port, timeout: const Duration(seconds: 3));

        if (devices.isNotEmpty) {
          targetDeviceId = devices.first.deviceId;
        } else {
          // Some devices do not answer a unicast Who-Is: read the
          // object-identifier of the wildcard device instance 4194303
          final idResult = await readProperty(
            host: host,
            port: port,
            objectType: BacnetObjectTypeCode.device,
            objectInstance: _wildcardDeviceInstance,
            propertyId: BacnetPropertyId.objectIdentifier,
          );
          final value = idResult.isSuccess ? idResult.value : null;
          if (value is Map && value['instance'] is int) {
            targetDeviceId = value['instance'] as int;
          }
        }

        if (targetDeviceId == null) {
          return BacnetConnectionResult(success: false, errorMessage: 'No BACnet device responded');
        }
      }

      // Lire les 3 propriétés en une seule requête (fallback ReadProperty si RPM refusé)
      final props = await _readPropertiesWithFallback(
        host: host,
        port: port,
        objectType: BacnetObjectTypeCode.device,
        objectInstance: targetDeviceId,
        propertyIds: [BacnetPropertyId.objectName, BacnetPropertyId.vendorName, BacnetPropertyId.modelName],
      );

      return BacnetConnectionResult(
        success: true,
        deviceId: targetDeviceId,
        deviceName: props?[BacnetPropertyId.objectName]?.toString(),
        vendorName: props?[BacnetPropertyId.vendorName]?.toString(),
        modelName: props?[BacnetPropertyId.modelName]?.toString(),
      );
    } catch (e) {
      return BacnetConnectionResult(success: false, errorMessage: e.toString());
    }
  }

  static const int _wildcardDeviceInstance = 4194303;

  /// Envoie Who-Is et collecte les I-Am
  ///
  /// Every I-Am received during [timeout] is considered (even from devices
  /// already discovered). For a unicast Who-Is, only answers coming from
  /// [host] are returned.
  Future<List<IAmInfo>> whoIs({
    required String host,
    required int port,
    int? lowLimit,
    int? highLimit,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    await init();

    // Détecter si c'est une adresse broadcast
    final broadcastAddresses = await _getLocalBroadcastAddresses();
    final isBroadcast = host == '255.255.255.255' || broadcastAddresses.contains(host);
    final address = InternetAddress(host);

    final devices = <IAmInfo>[];
    final subscription = _rawIAmController.stream.listen((device) {
      if (!isBroadcast && device.address.address != address.address) return;
      if (devices.any((d) => d.deviceId == device.deviceId)) return;
      devices.add(device);
    });

    try {
      // Construire et envoyer le paquet Who-Is
      final packet = BacnetEncoder.encodeWhoIsRequest(lowLimit: lowLimit, highLimit: highLimit, broadcast: isBroadcast);

      _socket!.send(packet, address, port);
      _logger.d('Who-Is sent to $host:$port (broadcast: $isBroadcast)');

      // Attendre les réponses
      await Future.delayed(timeout);

      return devices;
    } finally {
      await subscription.cancel();
    }
  }

  /// Découverte broadcast sur le réseau local
  /// Envoie Who-Is à toutes les adresses de broadcast détectées
  /// Amélioration:
  /// - Envois multiples avec délais pour maximiser les réponses
  /// - Découverte des routeurs BACnet et envoi Who-Is aux réseaux distants
  /// - Détection des conflits de Device ID
  Future<List<IAmInfo>> discoverLocalDevices({
    int port = 47808,
    Duration timeout = const Duration(seconds: 5),
    int sendCount = 3, // Nombre d'envois Who-Is
    Duration sendInterval = const Duration(milliseconds: 800), // Délai entre envois
  }) async {
    await init();

    // Réinitialiser le cache des devices vus pour la détection de conflits
    clearSeenDevices();

    final devices = <IAmInfo>[];
    final discoveredNetworks = <int>{};

    final deviceSubscription = iAmStream.listen((device) {
      // Mettre à jour ou ajouter le device (supporte les mises à jour avec conflits)
      final existingIndex = devices.indexWhere((d) => d.deviceId == device.deviceId);
      if (existingIndex != -1) {
        // Remplacer par la version mise à jour (avec conflits éventuels)
        devices[existingIndex] = device;
        _logger.d('Updated device ${device.deviceId} (conflicts: ${device.hasConflict})');
      } else {
        devices.add(device);
        _logger.i('Discovered device ${device.deviceId} at ${device.address.address}');
      }
    });

    final routerSubscription = routerStream.listen((router) {
      // Collecter les réseaux découverts via les routeurs
      for (final network in router.networks) {
        if (!discoveredNetworks.contains(network)) {
          discoveredNetworks.add(network);
          _logger.i('Discovered BACnet network $network via router ${router.address.address}');
        }
      }
    });

    try {
      // Obtenir les adresses de broadcast du réseau local
      final broadcastAddresses = await _getLocalBroadcastAddresses();
      _logger.i('Broadcast addresses: $broadcastAddresses');

      // 255.255.255.255 leaves through the default route only: when an
      // interface is selected on a 0.0.0.0 socket, stick to its broadcast
      final sendGlobalBroadcast = _boundInterface == null || Platform.isWindows;

      // === PHASE 1: Découverte des routeurs BACnet ===
      _logger.i('Phase 1: Discovering BACnet routers...');
      final whoIsRouterPacket = BacnetEncoder.encodeWhoIsRouterToNetwork();

      for (final broadcastAddr in broadcastAddresses) {
        try {
          final address = InternetAddress(broadcastAddr);
          _socket!.send(whoIsRouterPacket, address, port);
        } catch (e) {
          // Ignorer les erreurs
        }
      }
      if (sendGlobalBroadcast) {
        try {
          final globalBroadcast = InternetAddress('255.255.255.255');
          _socket!.send(whoIsRouterPacket, globalBroadcast, port);
        } catch (e) {
          // Ignorer
        }
      }

      // Attendre les réponses des routeurs
      await Future.delayed(const Duration(milliseconds: 500));
      _logger.i('Found ${discoveredNetworks.length} remote BACnet networks: $discoveredNetworks');

      // === PHASE 2: Who-Is broadcasts locaux ===
      _logger.i('Phase 2: Local Who-Is broadcasts...');

      // Construire les paquets Who-Is
      final packetGlobal = BacnetEncoder.encodeWhoIsRequest(broadcast: true);
      final packetWithRange = BacnetEncoder.encodeWhoIsRequest(
        broadcast: true,
        lowLimit: 0,
        highLimit: 4194303, // Max device ID BACnet
      );

      // Envoyer plusieurs fois avec délai
      for (int i = 0; i < sendCount; i++) {
        if (i > 0) {
          await Future.delayed(sendInterval);
        }

        _logger.d('Who-Is broadcast round ${i + 1}/$sendCount');

        final packet = (i % 2 == 0) ? packetGlobal : packetWithRange;

        for (final broadcastAddr in broadcastAddresses) {
          try {
            final address = InternetAddress(broadcastAddr);
            _socket!.send(packet, address, port);
          } catch (e) {
            _logger.w('Failed to send to $broadcastAddr: $e');
          }
        }

        if (sendGlobalBroadcast) {
          try {
            final globalBroadcast = InternetAddress('255.255.255.255');
            _socket!.send(packet, globalBroadcast, port);
          } catch (e) {
            _logger.w('Failed to send global broadcast: $e');
          }
        }
      }

      // === PHASE 3: Who-Is vers les réseaux distants découverts ===
      if (discoveredNetworks.isNotEmpty) {
        _logger.i('Phase 3: Who-Is to ${discoveredNetworks.length} remote networks...');

        for (final networkNumber in discoveredNetworks) {
          final networkWhoIs = BacnetEncoder.encodeWhoIsToNetwork(destinationNetwork: networkNumber, lowLimit: 0, highLimit: 4194303);

          for (final broadcastAddr in broadcastAddresses) {
            try {
              final address = InternetAddress(broadcastAddr);
              _socket!.send(networkWhoIs, address, port);
              _logger.d('Who-Is sent to network $networkNumber via $broadcastAddr');
            } catch (e) {
              // Ignorer
            }
          }

          // Petit délai entre chaque réseau
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }

      // Attendre les réponses
      await Future.delayed(timeout);

      _logger.i('Discovery completed: ${devices.length} devices found');
      return devices;
    } finally {
      await deviceSubscription.cancel();
      await routerSubscription.cancel();
    }
  }

  /// Récupère les adresses de broadcast
  /// Si une interface est sélectionnée, utilise uniquement son broadcast
  /// Sinon, retourne les broadcasts de toutes les interfaces physiques
  /// (loopback et ponts Docker/VM exclus). Sous Linux, le broadcast est
  /// calculé avec le vrai masque (`ip -o -4 addr`), sinon /24.
  Future<List<String>> _getLocalBroadcastAddresses() async {
    final interfaces = await BacnetNetwork.listIpv4Interfaces();

    // Si une interface spécifique est sélectionnée, utiliser uniquement son broadcast
    final bound = _boundInterface;
    if (bound != null) {
      final match = interfaces.where((i) => i.address == bound.address).toList();
      final broadcast = match.isNotEmpty ? match.first.broadcast : bound.broadcastAddress;
      _logger.d('Using bound interface broadcast: $broadcast');
      return [broadcast];
    }

    final broadcastAddresses = <String>[];
    for (final iface in interfaces) {
      if (BacnetNetwork.isVirtualInterface(iface.name)) continue;
      if (iface.address.startsWith('127.')) continue;
      if (!broadcastAddresses.contains(iface.broadcast)) {
        broadcastAddresses.add(iface.broadcast);
      }
    }

    // Fallback si aucune interface trouvée
    if (broadcastAddresses.isEmpty) {
      broadcastAddresses.add('255.255.255.255');
    }

    return broadcastAddresses;
  }

  /// Lit une propriété BACnet
  Future<BacnetResponse> readProperty({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    int? arrayIndex,
  }) async {
    await init();

    return _sendConfirmed(
      host,
      port,
      (invokeId) => BacnetEncoder.encodeReadPropertyRequest(
        invokeId: invokeId,
        objectType: objectType,
        objectInstance: objectInstance,
        propertyId: propertyId,
        arrayIndex: arrayIndex,
      ),
    );
  }

  /// Écrit une propriété BACnet
  Future<BacnetResponse> writeProperty({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    required dynamic value,
    int? priority,
    int? arrayIndex,
  }) async {
    await init();

    return _sendConfirmed(
      host,
      port,
      (invokeId) => BacnetEncoder.encodeWritePropertyRequest(
        invokeId: invokeId,
        objectType: objectType,
        objectInstance: objectInstance,
        propertyId: propertyId,
        value: value,
        priority: priority,
        arrayIndex: arrayIndex,
      ),
    );
  }

  /// Lit plusieurs propriétés d'un ou plusieurs objets
  Future<BacnetResponse> readPropertyMultiple({
    required String host,
    required int port,
    required List<ReadPropertyMultipleItem> items,
  }) async {
    await init();

    return _sendConfirmed(host, port, (invokeId) => BacnetEncoder.encodeReadPropertyMultipleRequest(invokeId: invokeId, items: items));
  }

  /// Découvre les objets d'un device BACnet
  /// Retourne une liste de BacnetObject avec les propriétés de base
  Future<List<BacnetObject>> discoverObjects({
    required String host,
    required int port,
    required int deviceId,
    List<int>? objectTypesFilter,
  }) async {
    await init();

    // 1. Lire la liste des objets (object-list)
    final objectList = await _readObjectList(host: host, port: port, deviceId: deviceId);
    if (objectList == null) {
      _logger.e('Failed to read object-list of device $deviceId on $host');
      return [];
    }

    // 2. Filtrer si nécessaire
    final filteredObjects = objectTypesFilter != null ? objectList.where((o) => objectTypesFilter.contains(o.type)).toList() : objectList;

    // 3. Lire les propriétés de chaque objet, en parallèle (le nombre de
    // requêtes simultanées par device est borné par _sendConfirmed)
    final objects = await Future.wait(
      filteredObjects.map((objInfo) async {
        try {
          return await _readObjectProperties(host: host, port: port, objectType: objInfo.type, objectInstance: objInfo.instance);
        } catch (e) {
          _logger.e('Error reading object ${objInfo.type}:${objInfo.instance}: $e');
          return null;
        }
      }),
    );

    return objects.whereType<BacnetObject>().toList();
  }

  /// Reads the object-list of a device.
  ///
  /// First as a whole (a large list arrives as a segmented response). If the
  /// device refuses (Abort segmentation-not-supported / buffer-overflow,
  /// Error, Reject), falls back to reading it element by element: index 0
  /// gives the length, then 1..N. Returns null if the device does not answer.
  /// The result is cached for a short time (discoverObjects, discoverTrendLogs
  /// and discoverSchedules all need it).
  Future<List<_ObjectInfo>?> _readObjectList({required String host, required int port, required int deviceId}) async {
    final cacheKey = '$host:$port:$deviceId';
    final cached = _objectListCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.readAt) < _objectListCacheTtl) {
      return cached.objects;
    }

    final whole = await readProperty(
      host: host,
      port: port,
      objectType: BacnetObjectTypeCode.device,
      objectInstance: deviceId,
      propertyId: BacnetPropertyId.objectList,
    );

    List<_ObjectInfo>? objects;
    if (whole.isSuccess) {
      objects = _parseObjectList(whole.value);
    } else if (whole.isDeviceError) {
      _logger.w('object-list read refused (${whole.errorMessage}), reading it element by element');
      objects = await _readObjectListByIndex(host: host, port: port, deviceId: deviceId);
    } else {
      _logger.e('Failed to read object-list: ${whole.errorMessage}');
    }

    if (objects != null) {
      _objectListCache[cacheKey] = (readAt: DateTime.now(), objects: objects);
    }
    return objects;
  }

  Future<List<_ObjectInfo>?> _readObjectListByIndex({required String host, required int port, required int deviceId}) async {
    final lengthResult = await readProperty(
      host: host,
      port: port,
      objectType: BacnetObjectTypeCode.device,
      objectInstance: deviceId,
      propertyId: BacnetPropertyId.objectList,
      arrayIndex: 0,
    );
    final length = lengthResult.isSuccess ? _toInt(lengthResult.value) : null;
    if (length == null) {
      _logger.e('Failed to read object-list length: ${lengthResult.errorMessage}');
      return null;
    }
    _logger.i('object-list has $length elements, reading them by index');

    final items = await Future.wait(
      List.generate(
        length,
        (i) => readProperty(
          host: host,
          port: port,
          objectType: BacnetObjectTypeCode.device,
          objectInstance: deviceId,
          propertyId: BacnetPropertyId.objectList,
          arrayIndex: i + 1,
        ),
      ),
    );

    final objects = <_ObjectInfo>[];
    int failures = 0;
    for (final item in items) {
      if (item.isSuccess) {
        objects.addAll(_parseObjectList(item.value));
      } else {
        failures++;
      }
    }
    if (failures > 0) {
      _logger.w('object-list: $failures of $length elements could not be read');
    }
    return objects;
  }

  /// Reads several properties of one object: ReadPropertyMultiple first,
  /// then one ReadProperty per property only if the device refused the RPM
  /// (Error/Reject/Abort). A timeout does not trigger the fallback (the
  /// device is unreachable, 1 + N more timeouts would only delay the
  /// failure). Returns null if nothing could be read.
  Future<Map<int, dynamic>?> _readPropertiesWithFallback({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
    required List<int> propertyIds,
  }) async {
    final hostKey = '$host:$port';
    if (!_rpmUnsupportedHosts.contains(hostKey)) {
      final rpm = await readPropertyMultiple(
        host: host,
        port: port,
        items: [ReadPropertyMultipleItem(objectType: objectType, objectInstance: objectInstance, propertyIds: propertyIds)],
      );

      final results = rpm.multipleResults;
      if (rpm.isSuccess && results != null && results.isNotEmpty) {
        return {for (final prop in results.first.properties) prop.propertyId: prop.value};
      }

      if (!rpm.isDeviceError && !rpm.isSuccess) {
        // Timeout / local error: no fallback cascade
        return null;
      }

      if (rpm.type == BacnetResponseType.reject && rpm.errorCode == _rejectUnrecognizedService) {
        _logger.w('$hostKey does not support ReadPropertyMultiple, using ReadProperty');
        _rpmUnsupportedHosts.add(hostKey);
      }
    }

    // Fallback: lire les propriétés une par une
    final properties = <int, dynamic>{};
    for (final propId in propertyIds) {
      final result = await readProperty(host: host, port: port, objectType: objectType, objectInstance: objectInstance, propertyId: propId);

      if (result.isSuccess) {
        properties[propId] = result.value;
      } else if (result.type == BacnetResponseType.timeout) {
        break; // Device unreachable: stop here
      }
    }

    return properties.isEmpty ? null : properties;
  }

  static const int _rejectUnrecognizedService = 9;

  /// Parse la valeur object-list en liste d'ObjectInfo
  List<_ObjectInfo> _parseObjectList(dynamic value) {
    final objects = <_ObjectInfo>[];

    _logger.d('_parseObjectList: input type=${value.runtimeType}');

    if (value is List) {
      _logger.d('_parseObjectList: list has ${value.length} items');
      for (int i = 0; i < value.length; i++) {
        final item = value[i];
        if (item is Map) {
          // Essayer différentes clés possibles
          final type = item['type'] ?? item['objectType'];
          final instance = item['instance'] ?? item['objectInstance'];
          if (i < 5 || type == 20) {
            _logger.d('_parseObjectList: item[$i] = $item -> type=$type, instance=$instance');
          }
          if (type != null && instance != null) {
            objects.add(_ObjectInfo(type: type as int, instance: instance as int));
          }
        } else {
          if (i < 5) {
            _logger.d('_parseObjectList: item[$i] is not a Map, it is ${item.runtimeType}: $item');
          }
        }
      }
    } else if (value is Map) {
      _logger.d('_parseObjectList: single map: $value');
      // Si c'est un seul objet (pas une liste)
      final type = value['type'] ?? value['objectType'];
      final instance = value['instance'] ?? value['objectInstance'];
      if (type != null && instance != null) {
        objects.add(_ObjectInfo(type: type as int, instance: instance as int));
      }
    } else {
      _logger.w('_parseObjectList: unexpected value type: ${value.runtimeType}');
    }

    _logger.d('_parseObjectList: parsed ${objects.length} objects');
    return objects;
  }

  /// Lit les propriétés d'un objet et crée un BacnetObject
  Future<BacnetObject?> _readObjectProperties({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
  }) async {
    // Propriétés à lire
    final propertyIds = [
      BacnetPropertyId.objectName,
      BacnetPropertyId.presentValue,
      BacnetPropertyId.description,
      BacnetPropertyId.units,
      BacnetPropertyId.outOfService,
      BacnetPropertyId.statusFlags, // Pour détecter les alarmes (in-alarm)
    ];

    // Ajouter les propriétés spécifiques aux types
    final bacnetType = _objectTypeCodeToBacnetType(objectType);
    if (bacnetType?.isBinary == true) {
      propertyIds.addAll([BacnetPropertyId.activeText, BacnetPropertyId.inactiveText]);
    } else if (bacnetType?.isMultiState == true) {
      propertyIds.add(BacnetPropertyId.stateText);
    }

    // Ajouter priority-array pour les objets commandables (détection forçage)
    if (bacnetType != null && bacnetType.isCommandable) {
      propertyIds.add(BacnetPropertyId.priorityArray);
    }

    final properties = await _readPropertiesWithFallback(
      host: host,
      port: port,
      objectType: objectType,
      objectInstance: objectInstance,
      propertyIds: propertyIds,
    );

    if (properties == null) return null;

    return _createBacnetObjectFromPropertiesMap(objectType: objectType, objectInstance: objectInstance, properties: properties);
  }

  /// Crée un BacnetObject depuis une map de propriétés
  BacnetObject _createBacnetObjectFromPropertiesMap({
    required int objectType,
    required int objectInstance,
    required Map<int, dynamic> properties,
  }) {
    final bacnetType = _objectTypeCodeToBacnetType(objectType);

    // Parser le priority-array pour détecter les forçages
    final priorityArray = properties[BacnetPropertyId.priorityArray];
    final overrideInfo = _parsePriorityArray(priorityArray);

    // Parser status-flags pour détecter les alarmes
    final statusFlags = properties[BacnetPropertyId.statusFlags];
    _logger.d('_createBacnetObject: ${BacnetObjectTypeCode.getName(objectType)}:$objectInstance, statusFlags=$statusFlags');
    final statusInfo = _parseStatusFlags(statusFlags);

    if (statusInfo.inAlarm) {
      _logger.i('_createBacnetObject: ALARM detected on ${BacnetObjectTypeCode.getName(objectType)}:$objectInstance');
    }

    return BacnetObject(
      type: bacnetType ?? BacnetObjectType.analogValue,
      instance: objectInstance,
      objectName: properties[BacnetPropertyId.objectName]?.toString() ?? '${BacnetObjectTypeCode.getName(objectType)}:$objectInstance',
      description: properties[BacnetPropertyId.description]?.toString(),
      presentValue: properties[BacnetPropertyId.presentValue],
      units: _parseUnit(properties[BacnetPropertyId.units]),
      outOfService: properties[BacnetPropertyId.outOfService] as bool?,
      activeText: properties[BacnetPropertyId.activeText]?.toString(),
      inactiveText: properties[BacnetPropertyId.inactiveText]?.toString(),
      stateText: _parseStateText(properties[BacnetPropertyId.stateText]),
      isOverridden: overrideInfo.isOverridden,
      overridePriority: overrideInfo.priority,
      overrideValue: overrideInfo.value,
      inAlarm: statusInfo.inAlarm,
    );
  }

  /// Parse le status-flags BACnet et retourne les infos d'état
  /// status-flags est un bitstring de 4 bits:
  /// - Bit 0: in-alarm
  /// - Bit 1: fault
  /// - Bit 2: overridden
  /// - Bit 3: out-of-service
  ({bool inAlarm, bool fault, bool overridden, bool outOfService}) _parseStatusFlags(dynamic statusFlags) {
    if (statusFlags == null) {
      return (inAlarm: false, fault: false, overridden: false, outOfService: false);
    }

    _logger.d('_parseStatusFlags: received ${statusFlags.runtimeType}: $statusFlags');

    // Format liste de booléens (le plus courant depuis notre décodeur)
    if (statusFlags is List) {
      return (
        inAlarm: statusFlags.isNotEmpty && statusFlags[0] == true,
        fault: statusFlags.length > 1 && statusFlags[1] == true,
        overridden: statusFlags.length > 2 && statusFlags[2] == true,
        outOfService: statusFlags.length > 3 && statusFlags[3] == true,
      );
    }

    // Format Map avec les clés nommées
    if (statusFlags is Map) {
      return (
        inAlarm: statusFlags['inAlarm'] == true || statusFlags['in-alarm'] == true || statusFlags[0] == true,
        fault: statusFlags['fault'] == true || statusFlags[1] == true,
        overridden: statusFlags['overridden'] == true || statusFlags[2] == true,
        outOfService: statusFlags['outOfService'] == true || statusFlags['out-of-service'] == true || statusFlags[3] == true,
      );
    }

    // Format entier (bitfield brut)
    if (statusFlags is int) {
      return (
        inAlarm: (statusFlags & 0x01) != 0, // Bit 0
        fault: (statusFlags & 0x02) != 0, // Bit 1
        overridden: (statusFlags & 0x04) != 0, // Bit 2
        outOfService: (statusFlags & 0x08) != 0, // Bit 3
      );
    }

    // Format String (ex: "0000" ou "{in-alarm=false, ...}")
    if (statusFlags is String) {
      final lower = statusFlags.toLowerCase();
      // Format bitstring "0000"
      if (RegExp(r'^[01]+$').hasMatch(statusFlags)) {
        final bits = statusFlags.split('').map((b) => b == '1').toList();
        return (
          inAlarm: bits.isNotEmpty && bits[0],
          fault: bits.length > 1 && bits[1],
          overridden: bits.length > 2 && bits[2],
          outOfService: bits.length > 3 && bits[3],
        );
      }
      // Format texte
      return (
        inAlarm: lower.contains('in-alarm=true') || lower.contains('inalarm=true'),
        fault: lower.contains('fault=true'),
        overridden: lower.contains('overridden=true'),
        outOfService: lower.contains('out-of-service=true') || lower.contains('outofservice=true'),
      );
    }

    _logger.d('_parseStatusFlags: unknown format ${statusFlags.runtimeType}: $statusFlags');
    return (inAlarm: false, fault: false, overridden: false, outOfService: false);
  }

  /// Parse le priority-array BACnet et retourne les infos de forçage
  /// Le priority-array est une liste de 16 valeurs (priorités 1-16)
  /// Si une valeur aux positions 1-15 (indices 0-14) n'est pas null, c'est un forçage
  ({bool isOverridden, int? priority, dynamic value}) _parsePriorityArray(dynamic priorityArray) {
    if (priorityArray == null) {
      return (isOverridden: false, priority: null, value: null);
    }

    // Format liste (le plus courant en BACnet natif)
    if (priorityArray is List) {
      for (int i = 0; i < 15 && i < priorityArray.length; i++) {
        final value = priorityArray[i];
        // Vérifier si la valeur n'est pas null
        if (value != null && !_isNullValue(value)) {
          return (
            isOverridden: true,
            priority: i + 1, // Priorité 1-15
            value: _extractPriorityValue(value),
          );
        }
      }
    }

    return (isOverridden: false, priority: null, value: null);
  }

  /// Vérifie si une valeur du priority-array représente "null" (pas de forçage)
  bool _isNullValue(dynamic value) {
    if (value == null) return true;
    if (value is Map) {
      // Format {"null": ...} ou {"type": "null"}
      if (value.containsKey('null')) return true;
      if (value['type'] == 'null' || value['type'] == 0) return true;
    }
    return false;
  }

  /// Extrait la valeur réelle d'une entrée du priority-array
  dynamic _extractPriorityValue(dynamic value) {
    if (value is Map) {
      // Formats possibles: {"real": 21.5}, {"unsigned": 1}, {"boolean": true}, etc.
      if (value.containsKey('real')) return value['real'];
      if (value.containsKey('unsigned')) return value['unsigned'];
      if (value.containsKey('boolean')) return value['boolean'];
      if (value.containsKey('enumerated')) return value['enumerated'];
      if (value.containsKey('value')) return value['value'];
      // Retourner la première valeur non-null trouvée
      for (final v in value.values) {
        if (v != null && v != 'Null') return v;
      }
    }
    return value;
  }

  /// Convertit un code de type d'objet en BacnetObjectType
  BacnetObjectType? _objectTypeCodeToBacnetType(int code) {
    switch (code) {
      case BacnetObjectTypeCode.analogInput:
        return BacnetObjectType.analogInput;
      case BacnetObjectTypeCode.analogOutput:
        return BacnetObjectType.analogOutput;
      case BacnetObjectTypeCode.analogValue:
        return BacnetObjectType.analogValue;
      case BacnetObjectTypeCode.binaryInput:
        return BacnetObjectType.binaryInput;
      case BacnetObjectTypeCode.binaryOutput:
        return BacnetObjectType.binaryOutput;
      case BacnetObjectTypeCode.binaryValue:
        return BacnetObjectType.binaryValue;
      case BacnetObjectTypeCode.multiStateInput:
        return BacnetObjectType.multiStateInput;
      case BacnetObjectTypeCode.multiStateOutput:
        return BacnetObjectType.multiStateOutput;
      case BacnetObjectTypeCode.multiStateValue:
        return BacnetObjectType.multiStateValue;
      case BacnetObjectTypeCode.schedule:
        return BacnetObjectType.schedule;
      case BacnetObjectTypeCode.calendar:
        return BacnetObjectType.calendar;
      case BacnetObjectTypeCode.trendLog:
        return BacnetObjectType.trendLog;
      case BacnetObjectTypeCode.device:
        return BacnetObjectType.device;
      default:
        return null;
    }
  }

  /// Parse state-text en liste de strings
  /// state-text is indexed by the multi-state value (1-based): empty labels
  /// keep their position, only trailing empty labels are dropped.
  List<String>? _parseStateText(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final result = value.map((e) => e?.toString() ?? '').toList();
      while (result.isNotEmpty && result.last.isEmpty) {
        result.removeLast();
      }
      return result.isEmpty ? null : result;
    }
    // Si c'est une seule chaîne, la retourner comme liste d'un élément
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return null;
  }

  /// Parse et convertit un code d'unité BACnet en symbole lisible
  /// Ex: 62 -> "°C", 95 -> "%", "DegreesCelsius" -> "°C"
  String? _parseUnit(dynamic value) {
    if (value == null) return null;
    final result = BacnetUnits.getUnitText(value);
    return result.isEmpty ? null : result;
  }

  /// Lit et rafraîchit la valeur d'un point
  Future<dynamic> refreshPointValue({required String host, required int port, required int objectType, required int objectInstance}) async {
    final result = await readProperty(
      host: host,
      port: port,
      objectType: objectType,
      objectInstance: objectInstance,
      propertyId: BacnetPropertyId.presentValue,
    );

    if (result.isSuccess) {
      return result.value;
    }

    throw Exception(result.errorMessage ?? 'Failed to read present-value');
  }

  /// Rafraîchit les valeurs de plusieurs points
  /// Retourne une Map avec objectId comme clé et les infos rafraîchies
  ///
  /// Points are grouped into ReadPropertyMultiple requests holding several
  /// objects (sized to fit in a 1476-byte APDU). If the device refuses a
  /// group (Error/Reject/Abort), its points are read one RPM per point. A
  /// group that times out is skipped (points missing from the result).
  /// [batchSize] is kept for compatibility and caps the objects per RPM.
  Future<Map<String, RefreshedPointData>> refreshMultiplePointValues({
    required String host,
    required int port,
    required List<({int objectType, int objectInstance, bool isCommandable, bool isInput})> points,
    int batchSize = 25,
  }) async {
    await init();

    final groups = groupPointsForRpm(points, maxObjects: batchSize);
    final results = <String, RefreshedPointData>{};

    final groupResults = await Future.wait(
      groups.map((group) async {
        try {
          return await _refreshPointGroup(host: host, port: port, group: group);
        } catch (e) {
          _logger.e('Error refreshing ${group.length} points: $e');
          return const <String, RefreshedPointData>{};
        }
      }),
    );
    for (final r in groupResults) {
      results.addAll(r);
    }

    return results;
  }

  /// Approximate size of the RPM answer for one point (bytes)
  static int _estimatedRpmResponseSize(({int objectType, int objectInstance, bool isCommandable, bool isInput}) p) {
    // object id + tags + present-value + status-flags + units (+ out-of-service)
    var size = 40;
    // priority-array: 16 entries, up to 5 bytes each with tags
    if (p.isCommandable) size += 90;
    if (p.isInput) size += 6;
    return size;
  }

  /// Splits [points] into groups whose RPM answer should fit in one
  /// unsegmented APDU (1476 bytes, with margin).
  static List<List<({int objectType, int objectInstance, bool isCommandable, bool isInput})>> groupPointsForRpm(
    List<({int objectType, int objectInstance, bool isCommandable, bool isInput})> points, {
    int maxObjects = 25,
    int maxResponseBytes = 1200,
  }) {
    final groups = <List<({int objectType, int objectInstance, bool isCommandable, bool isInput})>>[];
    var current = <({int objectType, int objectInstance, bool isCommandable, bool isInput})>[];
    var currentSize = 0;
    for (final p in points) {
      final size = _estimatedRpmResponseSize(p);
      if (current.isNotEmpty && (current.length >= maxObjects || currentSize + size > maxResponseBytes)) {
        groups.add(current);
        current = [];
        currentSize = 0;
      }
      current.add(p);
      currentSize += size;
    }
    if (current.isNotEmpty) groups.add(current);
    return groups;
  }

  List<int> _refreshPropertyIds(({int objectType, int objectInstance, bool isCommandable, bool isInput}) point) {
    return [
      BacnetPropertyId.presentValue,
      BacnetPropertyId.statusFlags, // Pour détecter les alarmes
      BacnetPropertyId.units, // Pour afficher les unités
      // priority-array pour les objets commandables (AO, BO, MSO, AV, BV, MSV)
      if (point.isCommandable) BacnetPropertyId.priorityArray,
      // out-of-service pour les entrées (AI, BI, MSI) - forçage via OOS
      if (point.isInput) BacnetPropertyId.outOfService,
    ];
  }

  Future<Map<String, RefreshedPointData>> _refreshPointGroup({
    required String host,
    required int port,
    required List<({int objectType, int objectInstance, bool isCommandable, bool isInput})> group,
  }) async {
    final results = <String, RefreshedPointData>{};

    final response = await readPropertyMultiple(
      host: host,
      port: port,
      items: [
        for (final point in group)
          ReadPropertyMultipleItem(
            objectType: point.objectType,
            objectInstance: point.objectInstance,
            propertyIds: _refreshPropertyIds(point),
          ),
      ],
    );

    if (response.isSuccess && response.multipleResults != null) {
      for (final point in group) {
        final objectResult = response.multipleResults!.where(
          (r) => r.objectType == point.objectType && r.objectInstance == point.objectInstance,
        );
        if (objectResult.isEmpty) continue;
        results['${point.objectType}:${point.objectInstance}'] = _toRefreshedPointData(point, objectResult.first.properties);
      }
      return results;
    }

    if (!response.isDeviceError) {
      _logger.w('refreshMultiplePointValues: no answer for ${group.length} points (${response.errorMessage})');
      return results;
    }

    if (group.length == 1) return results;

    // The device refused the grouped request (e.g. one unknown object makes
    // some devices reject the whole RPM): one request per point
    _logger.w('refreshMultiplePointValues: grouped RPM refused (${response.errorMessage}), reading points one by one');
    final single = await Future.wait(group.map((point) => _refreshPointGroup(host: host, port: port, group: [point])));
    for (final r in single) {
      results.addAll(r);
    }
    return results;
  }

  RefreshedPointData _toRefreshedPointData(
    ({int objectType, int objectInstance, bool isCommandable, bool isInput}) point,
    List<PropertyResult> props,
  ) {
    dynamic valueOf(int propertyId) {
      for (final prop in props) {
        if (prop.propertyId == propertyId) return prop.value;
      }
      return null;
    }

    final key = '${point.objectType}:${point.objectInstance}';

    // Status-flags (pour alarmes)
    final statusInfo = _parseStatusFlags(valueOf(BacnetPropertyId.statusFlags));
    if (statusInfo.inAlarm) {
      _logger.i('refreshMultiplePointValues: ALARM on $key');
    }

    // Priority-array (pour commandables)
    final overrideInfo = point.isCommandable
        ? _parsePriorityArray(valueOf(BacnetPropertyId.priorityArray))
        : (isOverridden: false, priority: null, value: null);

    // Out-of-service (pour entrées)
    final oos = point.isInput ? valueOf(BacnetPropertyId.outOfService) : null;

    return RefreshedPointData(
      presentValue: valueOf(BacnetPropertyId.presentValue),
      isOverridden: overrideInfo.isOverridden,
      overridePriority: overrideInfo.priority,
      overrideValue: overrideInfo.value,
      outOfService: oos is bool ? oos : null,
      inAlarm: statusInfo.inAlarm,
      units: _parseUnit(valueOf(BacnetPropertyId.units)),
    );
  }

  /// Écrit la valeur d'un point
  Future<void> writePointValue({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
    required dynamic value,
    int? priority,
  }) async {
    final result = await writeProperty(
      host: host,
      port: port,
      objectType: objectType,
      objectInstance: objectInstance,
      propertyId: BacnetPropertyId.presentValue,
      value: _toPresentValueDatatype(objectType, value),
      priority: priority,
    );

    if (!result.isSuccess) {
      throw Exception(result.errorMessage ?? 'Failed to write present-value');
    }
  }

  /// Converts a UI value to the datatype required by the present-value
  /// of the object type (ASHRAE 135): Real for analog, Enumerated for
  /// binary, Unsigned for multi-state. null (relinquish) is kept as is.
  static dynamic _toPresentValueDatatype(int objectType, dynamic value) {
    if (value == null) return null;
    switch (objectType) {
      case BacnetObjectTypeCode.analogInput:
      case BacnetObjectTypeCode.analogOutput:
      case BacnetObjectTypeCode.analogValue:
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? value;
        return value;
      case BacnetObjectTypeCode.binaryInput:
      case BacnetObjectTypeCode.binaryOutput:
      case BacnetObjectTypeCode.binaryValue:
        final bool active;
        if (value is bool) {
          active = value;
        } else if (value is num) {
          active = value != 0;
        } else {
          final lower = value.toString().toLowerCase();
          active = lower == 'active' || lower == 'true' || lower == '1' || lower == 'on';
        }
        return BacnetEnumerated(active ? 1 : 0);
      case BacnetObjectTypeCode.multiStateInput:
      case BacnetObjectTypeCode.multiStateOutput:
      case BacnetObjectTypeCode.multiStateValue:
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value) ?? value;
        return value;
      default:
        return value;
    }
  }

  // =========================================================================
  // TrendLog Support
  // =========================================================================

  /// Découvre les TrendLog d'un device BACnet
  Future<List<BacnetTrendLog>> discoverTrendLogs({required String host, required int port, required int deviceId}) async {
    await init();

    final trendLogs = <BacnetTrendLog>[];

    _logger.i('discoverTrendLogs: starting discovery on $host:$port, deviceId=$deviceId');

    // 1. Lire la liste des objets
    final objectList = await _readObjectList(host: host, port: port, deviceId: deviceId);
    if (objectList == null) {
      _logger.e('discoverTrendLogs: Failed to read object-list');
      return trendLogs;
    }
    _logger.i('discoverTrendLogs: parsed ${objectList.length} total objects');

    // Log tous les types d'objets trouvés
    final typeCount = <int, int>{};
    for (final obj in objectList) {
      typeCount[obj.type] = (typeCount[obj.type] ?? 0) + 1;
    }
    _logger.i('discoverTrendLogs: object types found: $typeCount');

    final trendLogObjects = objectList.where((o) => o.type == BacnetObjectTypeCode.trendLog).toList();

    _logger.i('discoverTrendLogs: Found ${trendLogObjects.length} TrendLog objects (type 20)');

    // 2. Lire les propriétés de chaque TrendLog (en parallèle, borné par device)
    final read = await Future.wait(
      trendLogObjects.map((obj) async {
        try {
          return await _readTrendLogProperties(host: host, port: port, objectInstance: obj.instance);
        } catch (e) {
          _logger.e('Error reading TrendLog ${obj.instance}: $e');
          return null;
        }
      }),
    );
    trendLogs.addAll(read.whereType<BacnetTrendLog>());

    return trendLogs;
  }

  /// Lit les propriétés d'un TrendLog
  Future<BacnetTrendLog?> _readTrendLogProperties({required String host, required int port, required int objectInstance}) async {
    // Propriétés à lire pour un TrendLog
    final propertyIds = [
      BacnetPropertyId.objectName,
      BacnetPropertyId.description,
      BacnetPropertyId.logDeviceObjectProperty,
      BacnetPropertyId.logInterval,
      BacnetPropertyId.bufferSize,
      BacnetPropertyId.recordCount,
      BacnetPropertyId.totalRecordCount, // Pour pagination bySequenceNumber
      BacnetPropertyId.enable,
    ];

    final properties = await _readPropertiesWithFallback(
      host: host,
      port: port,
      objectType: BacnetObjectTypeCode.trendLog,
      objectInstance: objectInstance,
      propertyIds: propertyIds,
    );

    if (properties == null) return null;

    return _createTrendLogFromPropertiesMap(objectInstance: objectInstance, properties: properties);
  }

  /// Crée un BacnetTrendLog depuis une map de propriétés
  BacnetTrendLog _createTrendLogFromPropertiesMap({required int objectInstance, required Map<int, dynamic> properties}) {
    _logger.d('_createTrendLogFromPropertiesMap: TrendLog $objectInstance, properties keys: ${properties.keys.toList()}');
    _logger.d('_createTrendLogFromPropertiesMap: all properties: $properties');

    // Parser log-device-object-property pour obtenir l'objet tracké
    final logDeviceObjectProperty = properties[BacnetPropertyId.logDeviceObjectProperty];
    _logger.d(
      '_createTrendLogFromPropertiesMap: logDeviceObjectProperty (propId=${BacnetPropertyId.logDeviceObjectProperty}) = $logDeviceObjectProperty (type: ${logDeviceObjectProperty.runtimeType})',
    );

    String? trackedObjectType;
    int? trackedObjectInstance;

    if (logDeviceObjectProperty != null) {
      final parsed = _parseLogDeviceObjectProperty(logDeviceObjectProperty);
      trackedObjectType = parsed.$1;
      trackedObjectInstance = parsed.$2;
      _logger.d('_createTrendLogFromPropertiesMap: parsed -> type=$trackedObjectType, instance=$trackedObjectInstance');
    }

    return BacnetTrendLog(
      instance: objectInstance,
      objectName: properties[BacnetPropertyId.objectName]?.toString() ?? 'Trend Log $objectInstance',
      description: properties[BacnetPropertyId.description]?.toString(),
      logDeviceObjectProperty: logDeviceObjectProperty?.toString(),
      trackedObjectType: trackedObjectType,
      trackedObjectInstance: trackedObjectInstance,
      logInterval: _toInt(properties[BacnetPropertyId.logInterval]),
      bufferSize: _toInt(properties[BacnetPropertyId.bufferSize]),
      recordCount: _toInt(properties[BacnetPropertyId.recordCount]),
      totalRecordCount: _toInt(properties[BacnetPropertyId.totalRecordCount]),
      enabled: properties[BacnetPropertyId.enable] as bool?,
    );
  }

  /// Parse la propriété log-device-object-property
  /// Format BACnet natif: {objectIdentifier: {type: X, instance: Y}, propertyIdentifier: Z, ...}
  (String?, int?) _parseLogDeviceObjectProperty(dynamic value) {
    _logger.d('_parseLogDeviceObjectProperty: input=$value (type=${value.runtimeType})');

    if (value == null) return (null, null);

    // Format Map (BACnet natif - depuis _decodeConstructedValue)
    if (value is Map) {
      _logger.d('_parseLogDeviceObjectProperty: Map keys=${value.keys.toList()}');

      // Essayer différentes clés possibles
      final objectId = value['objectIdentifier'] ?? value['object-identifier'] ?? value['context0'];
      _logger.d('_parseLogDeviceObjectProperty: objectId=$objectId (type=${objectId.runtimeType})');

      if (objectId is Map) {
        final typeCode = objectId['type'] ?? objectId['objectType'];
        final instance = objectId['instance'] ?? objectId['objectInstance'];
        _logger.d('_parseLogDeviceObjectProperty: typeCode=$typeCode, instance=$instance');

        if (typeCode != null && instance != null) {
          final typeName = BacnetObjectTypeCode.getName(typeCode as int);
          _logger.d('_parseLogDeviceObjectProperty: resolved -> typeName=$typeName, instance=$instance');
          return (typeName, instance as int);
        }
      }
    }

    // Format String (comme dans l'API V1)
    if (value is String) {
      // Format: "[Analog Value 454,Present Value,,]"
      final match = RegExp(r'\[([^,]+)\s+(\d+),').firstMatch(value);
      if (match != null) {
        final objectTypeRaw = match.group(1)?.trim();
        final objectInstance = int.tryParse(match.group(2) ?? '');
        if (objectTypeRaw != null && objectInstance != null) {
          final objectType = objectTypeRaw.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
          return (objectType, objectInstance);
        }
      }
    }

    _logger.w('_parseLogDeviceObjectProperty: could not parse value');
    return (null, null);
  }

  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Lit le buffer d'un TrendLog via ReadRange
  Future<BacnetResponse> readRange({
    required String host,
    required int port,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    ReadRangeType rangeType = ReadRangeType.all,
    int? referenceIndex,
    int? count,
    DateTime? referenceTime,
  }) async {
    await init();

    return _sendConfirmed(
      host,
      port,
      (invokeId) => BacnetEncoder.encodeReadRangeRequest(
        invokeId: invokeId,
        objectType: objectType,
        objectInstance: objectInstance,
        propertyId: propertyId,
        rangeType: rangeType,
        referenceIndex: referenceIndex,
        count: count,
        referenceTime: referenceTime,
      ),
    );
  }

  /// Lit le log-buffer d'un TrendLog (données les plus récentes)
  /// Utilise ReadRange bySequenceNumber avec count négatif pour pagination fiable
  ///
  /// [totalRecordCount] : Si fourni, évite une requête supplémentaire pour le lire.
  /// C'est le numéro de séquence du dernier record (= point de départ de la pagination).
  Future<List<TrendLogRecordData>> readTrendLogBuffer({
    required String host,
    required int port,
    required int trendLogInstance,
    int? maxRecords,
    int? totalRecordCount,
  }) async {
    _logger.i('readTrendLogBuffer: starting for TrendLog $trendLogInstance on $host:$port');

    // 1. Obtenir totalRecordCount si pas fourni (c'est le seqNum du dernier record)
    int? lastSeqNum = totalRecordCount;
    if (lastSeqNum == null) {
      _logger.d('readTrendLogBuffer: reading totalRecordCount property...');
      final trcResponse = await readProperty(
        host: host,
        port: port,
        objectType: BacnetObjectTypeCode.trendLog,
        objectInstance: trendLogInstance,
        propertyId: BacnetPropertyId.totalRecordCount,
      );

      if (trcResponse.isSuccess && trcResponse.value != null) {
        lastSeqNum = trcResponse.value is int ? trcResponse.value as int : int.tryParse(trcResponse.value.toString());
        _logger.i('readTrendLogBuffer: totalRecordCount=$lastSeqNum');
      }

      if (lastSeqNum == null || lastSeqNum == 0) {
        _logger.w('readTrendLogBuffer: totalRecordCount is null or 0, no records available');
        return [];
      }
    }

    // Liste pour collecter les records (on les ajoute au début à chaque itération)
    final allRecords = <TrendLogRecordData>[];

    // Paramètres de pagination
    const int chunkSize = 65; // Max records par requête (limite Distech)
    const int defaultMaxRecords = 1000; // ~10 jours à 15min d'intervalle
    final int recordsToRead = maxRecords ?? defaultMaxRecords;

    // Point de départ : le dernier record (seqNum le plus élevé)
    int referenceSeqNum = lastSeqNum;
    int iteration = 0;

    _logger.i('readTrendLogBuffer: using bySequenceNumber, starting from seqNum=$lastSeqNum, reading up to $recordsToRead records');

    while (allRecords.length < recordsToRead && referenceSeqNum > 0) {
      iteration++;
      final remaining = recordsToRead - allRecords.length;
      // Count négatif = lire vers le passé (records plus anciens)
      final requestCount = -remaining.clamp(1, chunkSize);
      final previousReference = referenceSeqNum;

      _logger.d('readTrendLogBuffer: iteration $iteration, referenceSeqNum=$referenceSeqNum, requesting $requestCount');

      final response = await readRange(
        host: host,
        port: port,
        objectType: BacnetObjectTypeCode.trendLog,
        objectInstance: trendLogInstance,
        propertyId: BacnetPropertyId.logBuffer,
        rangeType: ReadRangeType.bySequenceNumber,
        referenceIndex: referenceSeqNum,
        count: requestCount,
      );

      _logger.d('readTrendLogBuffer: response.type=${response.type}, isSuccess=${response.isSuccess}');

      if (!response.isSuccess) {
        _logger.e(
          'readTrendLogBuffer: Failed - ${response.errorMessage}, errorClass=${response.errorClass}, errorCode=${response.errorCode}',
        );
        break;
      }

      if (response.value is! ReadRangeResult) {
        _logger.e('readTrendLogBuffer: Unexpected value type: ${response.value?.runtimeType}');
        break;
      }

      final result = response.value as ReadRangeResult;
      _logger.i(
        'readTrendLogBuffer: received ${result.records.length} records, firstSeqNum=${result.firstSequenceNumber}, firstItem=${result.firstItem}, moreItems=${result.moreItems}',
      );

      if (result.records.isEmpty) {
        _logger.w('readTrendLogBuffer: no records returned, stopping');
        break;
      }

      // Avec count négatif, les records sont retournés du plus ancien au plus récent
      // (le referenceSeqNum est le DERNIER retourné, pas le premier)
      // On insère au début pour maintenir l'ordre chronologique
      allRecords.insertAll(0, result.records);

      // Mettre à jour le point de référence pour la prochaine itération
      // firstSequenceNumber = numéro de séquence du premier record retourné (le plus ancien)
      if (result.firstSequenceNumber != null && result.firstSequenceNumber! > 0) {
        // Prochain point de départ = juste avant le premier record qu'on vient de lire
        referenceSeqNum = result.firstSequenceNumber! - 1;
        _logger.d('readTrendLogBuffer: next referenceSeqNum=$referenceSeqNum');
      } else {
        // Pas de firstSequenceNumber, on estime basé sur le nombre de records reçus
        referenceSeqNum -= result.records.length;
        _logger.d('readTrendLogBuffer: estimated next referenceSeqNum=$referenceSeqNum (no firstSeqNum in response)');
      }

      // S'arrêter si on a atteint le début du buffer
      if (referenceSeqNum <= 0) {
        _logger.i('readTrendLogBuffer: reached beginning of buffer (seqNum <= 0)');
        break;
      }

      // first-item: the oldest record of the buffer is in this response.
      // Receiving fewer records than requested is NOT the end of the buffer:
      // the device may simply have filled its APDU.
      if (result.firstItem) {
        _logger.i('readTrendLogBuffer: first-item flag set, beginning of buffer reached');
        break;
      }

      // Safety: the reference must move backwards
      if (referenceSeqNum >= previousReference) {
        _logger.w('readTrendLogBuffer: sequence number did not decrease, stopping');
        break;
      }

      _logger.d('readTrendLogBuffer: total so far: ${allRecords.length}, continue: ${allRecords.length < recordsToRead}');
    }

    _logger.i('readTrendLogBuffer: completed with ${allRecords.length} total records over $iteration iterations');
    return allRecords;
  }

  // =========================================================================
  // Schedule Support
  // =========================================================================

  /// Découvre les schedules d'un device BACnet
  Future<List<BacnetScheduleInfo>> discoverSchedules({required String host, required int port, required int deviceId}) async {
    await init();

    final schedules = <BacnetScheduleInfo>[];

    _logger.i('discoverSchedules: starting discovery on $host:$port, deviceId=$deviceId');

    // 1. Lire la liste des objets et filtrer les schedules (type 17)
    final objectList = await _readObjectList(host: host, port: port, deviceId: deviceId);
    if (objectList == null) {
      _logger.e('discoverSchedules: Failed to read object-list');
      return schedules;
    }
    final scheduleObjects = objectList.where((o) => o.type == BacnetObjectTypeCode.schedule).toList();

    _logger.i('discoverSchedules: Found ${scheduleObjects.length} Schedule objects');

    // 2. Lire les propriétés de base de chaque schedule
    final read = await Future.wait(
      scheduleObjects.map((obj) async {
        try {
          return await readScheduleBasicInfo(host: host, port: port, scheduleInstance: obj.instance);
        } catch (e) {
          _logger.e('Error reading Schedule ${obj.instance}: $e');
          return null;
        }
      }),
    );
    schedules.addAll(read.whereType<BacnetScheduleInfo>());

    return schedules;
  }

  /// Lit les informations de base d'un schedule (sans le weekly-schedule complet)
  Future<BacnetScheduleInfo?> readScheduleBasicInfo({
    required String host,
    required int port,
    required int scheduleInstance,
    int? deviceId,
  }) async {
    await init();

    // Propriétés à lire - inclure list-of-object-property-references pour trouver l'objet cible
    final propertyIds = [
      BacnetPropertyId.objectName,
      BacnetPropertyId.description,
      BacnetPropertyId.presentValue,
      BacnetPropertyId.scheduleDefault,
      BacnetPropertyId.outOfService,
      BacnetPropertyId.stateText,
      BacnetPropertyId.listOfObjectPropertyReferences, // Pour récupérer les state-text de l'objet cible
    ];

    final propMap = await _readPropertiesWithFallback(
      host: host,
      port: port,
      objectType: BacnetObjectTypeCode.schedule,
      objectInstance: scheduleInstance,
      propertyIds: propertyIds,
    );

    if (propMap == null) {
      _logger.e('readScheduleBasicInfo: Failed to read properties for schedule $scheduleInstance');
      return null;
    }
    _logger.d('readScheduleBasicInfo: properties = $propMap');

    // Essayer de récupérer les state-text
    List<String>? stateTexts = _parseStateText(propMap[BacnetPropertyId.stateText]);
    _logger.d('readScheduleBasicInfo: stateTexts from schedule = $stateTexts');

    // Si pas de state-text sur le schedule, essayer de les récupérer depuis l'objet référencé
    if (stateTexts == null || stateTexts.isEmpty) {
      // D'abord essayer depuis le RPM
      var objRefs = propMap[BacnetPropertyId.listOfObjectPropertyReferences];
      _logger.d('readScheduleBasicInfo: list-of-object-property-references from RPM = $objRefs (${objRefs?.runtimeType})');

      // Si pas dans RPM, lire séparément avec ReadProperty
      if (objRefs == null) {
        _logger.d('readScheduleBasicInfo: trying to read list-of-object-property-references separately');
        final refResult = await readProperty(
          host: host,
          port: port,
          objectType: BacnetObjectTypeCode.schedule,
          objectInstance: scheduleInstance,
          propertyId: BacnetPropertyId.listOfObjectPropertyReferences,
        );
        if (refResult.isSuccess && refResult.value != null) {
          objRefs = refResult.value;
          _logger.d('readScheduleBasicInfo: list-of-object-property-references from ReadProperty = $objRefs (${objRefs?.runtimeType})');
        }
      }

      if (objRefs != null) {
        stateTexts = await _getStateTextsFromReferencedObject(host, port, objRefs);
        _logger.d('readScheduleBasicInfo: stateTexts from referenced object = $stateTexts');
      }

      // Si toujours pas de state-text, essayer les propriétés propriétaires Distech
      if ((stateTexts == null || stateTexts.isEmpty) && deviceId != null) {
        // Propriétés propriétaires Distech pour les state-texts
        // 1031, 1001, 1002 sont des propriétés propriétaires trouvées dans le schedule
        for (final propId in [1031, 1001, 1002]) {
          final propResult = await readProperty(
            host: host,
            port: port,
            objectType: BacnetObjectTypeCode.schedule,
            objectInstance: scheduleInstance,
            propertyId: propId,
          );
          if (propResult.isSuccess && propResult.value != null) {
            _logger.i('readScheduleBasicInfo: proprietary prop $propId = ${propResult.value} (${propResult.value.runtimeType})');
            // Essayer de parser comme state-text si c'est une liste de strings
            final parsed = _parseStateText(propResult.value);
            if (parsed != null && parsed.isNotEmpty) {
              _logger.i('readScheduleBasicInfo: found state-texts in prop $propId: $parsed');
              stateTexts = parsed;
              break;
            }
          }
        }

        // Si toujours pas trouvé, chercher par nom
        if (stateTexts == null || stateTexts.isEmpty) {
          final scheduleName = propMap[BacnetPropertyId.objectName]?.toString() ?? '';
          _logger.d('readScheduleBasicInfo: searching for multistate by schedule name "$scheduleName"');

          if (scheduleName.toLowerCase().contains('enum')) {
            stateTexts = await _findStateTextsFromMultistateByName(host, port, deviceId, 'enum');
          }
        }
      }
    }

    return BacnetScheduleInfo(
      instance: scheduleInstance,
      objectName: propMap[BacnetPropertyId.objectName]?.toString() ?? 'Schedule $scheduleInstance',
      description: propMap[BacnetPropertyId.description]?.toString(),
      presentValue: propMap[BacnetPropertyId.presentValue],
      scheduleDefault: propMap[BacnetPropertyId.scheduleDefault],
      outOfService: propMap[BacnetPropertyId.outOfService] as bool?,
      stateTexts: stateTexts,
    );
  }

  /// Cherche un objet Multi-state par son nom et retourne ses state-text
  Future<List<String>?> _findStateTextsFromMultistateByName(String host, int port, int deviceId, String searchName) async {
    _logger.d('_findStateTextsFromMultistateByName: searching for "$searchName" on device $deviceId');

    // Types Multi-state à chercher
    const multistateTypes = [
      BacnetObjectTypeCode.multiStateInput, // 13
      BacnetObjectTypeCode.multiStateOutput, // 14
      BacnetObjectTypeCode.multiStateValue, // 19
    ];

    final objects = await _readObjectList(host: host, port: port, deviceId: deviceId);
    if (objects == null) {
      _logger.d('_findStateTextsFromMultistateByName: could not read object list');
      return null;
    }

    // Filtrer les objets Multi-state
    final multistateObjects = objects.where((obj) => multistateTypes.contains(obj.type)).toList();
    _logger.d('_findStateTextsFromMultistateByName: found ${multistateObjects.length} multistate objects');

    // Chercher l'objet par son nom (noms lus par lots en parallèle)
    const chunkSize = 8;
    for (int i = 0; i < multistateObjects.length; i += chunkSize) {
      final chunk = multistateObjects.skip(i).take(chunkSize).toList();
      final names = await Future.wait(
        chunk.map(
          (obj) => readProperty(
            host: host,
            port: port,
            objectType: obj.type,
            objectInstance: obj.instance,
            propertyId: BacnetPropertyId.objectName,
          ),
        ),
      );

      for (int j = 0; j < chunk.length; j++) {
        final obj = chunk[j];
        final nameResult = names[j];

        if (nameResult.isSuccess && nameResult.value != null) {
          final objName = nameResult.value.toString();
          _logger.d('_findStateTextsFromMultistateByName: object ${obj.type}:${obj.instance} name="$objName"');

          if (objName.toLowerCase().contains(searchName.toLowerCase())) {
            _logger.i('_findStateTextsFromMultistateByName: found matching object "$objName" (${obj.type}:${obj.instance})');

            // Lire ses state-text
            final stateTextResult = await readProperty(
              host: host,
              port: port,
              objectType: obj.type,
              objectInstance: obj.instance,
              propertyId: BacnetPropertyId.stateText,
            );

            if (stateTextResult.isSuccess && stateTextResult.value != null) {
              final stateTexts = _parseStateText(stateTextResult.value);
              _logger.i('_findStateTextsFromMultistateByName: state-texts = $stateTexts');
              return stateTexts;
            }
          }
        }
      }
    }

    _logger.d('_findStateTextsFromMultistateByName: no matching object found');
    return null;
  }

  /// Récupère les state-text depuis un objet référencé par le schedule
  Future<List<String>?> _getStateTextsFromReferencedObject(String host, int port, dynamic objRefs) async {
    // list-of-object-property-references peut être:
    // - Une liste de BACnetDeviceObjectPropertyReference
    // - Un seul objet {objectType, instance, propertyId}
    // - Une liste de maps

    try {
      // Parser le premier objet référencé
      int? objectType;
      int? objectInstance;

      final firstRef = objRefs is List && objRefs.isNotEmpty ? objRefs.first : objRefs;
      if (firstRef is Map) {
        // {type, instance} or BACnetDeviceObjectPropertyReference {objectIdentifier: {type, instance}, ...}
        final id = firstRef['objectIdentifier'] is Map ? firstRef['objectIdentifier'] as Map : firstRef;
        objectType = id['type'] as int?;
        objectInstance = id['instance'] as int?;
      }

      if (objectType == null || objectInstance == null) {
        _logger.d('_getStateTextsFromReferencedObject: could not parse object reference');
        return null;
      }

      _logger.d('_getStateTextsFromReferencedObject: reading state-text from object type=$objectType instance=$objectInstance');

      // Lire le state-text de l'objet référencé
      final result = await readProperty(
        host: host,
        port: port,
        objectType: objectType,
        objectInstance: objectInstance,
        propertyId: BacnetPropertyId.stateText,
      );

      if (result.isSuccess && result.value != null) {
        return _parseStateText(result.value);
      }
    } catch (e) {
      _logger.e('_getStateTextsFromReferencedObject: error $e');
    }

    return null;
  }

  /// Lit le weekly-schedule complet d'un objet Schedule BACnet
  Future<DecodedWeeklySchedule?> readWeeklySchedule({required String host, required int port, required int scheduleInstance}) async {
    await init();

    _logger.i('readWeeklySchedule: reading schedule $scheduleInstance from $host:$port');

    // Lire la propriété weekly-schedule (123)
    final result = await readProperty(
      host: host,
      port: port,
      objectType: BacnetObjectTypeCode.schedule,
      objectInstance: scheduleInstance,
      propertyId: BacnetPropertyId.weeklySchedule,
    );

    if (!result.isSuccess) {
      _logger.e('readWeeklySchedule: Failed - ${result.errorMessage}');
      return null;
    }

    _logger.d('readWeeklySchedule: raw value type=${result.value.runtimeType}');

    // Vérifier si le décodeur a déjà retourné un DecodedWeeklySchedule
    DecodedWeeklySchedule decoded;
    if (result.value is DecodedWeeklySchedule) {
      // Déjà décodé par BacnetDecoder._decodeReadPropertyAck
      decoded = result.value as DecodedWeeklySchedule;
      _logger.d('readWeeklySchedule: value already decoded');
    } else {
      // Décoder le weekly-schedule depuis les données brutes
      decoded = BacnetScheduleDecoder.decodeWeeklySchedule(result.value);
      _logger.d('readWeeklySchedule: decoded from raw data');
    }

    _logger.i('readWeeklySchedule: decoded ${decoded.days.length} days');
    for (int i = 0; i < decoded.days.length; i++) {
      final day = decoded.days[i];
      _logger.d('  Day ${i + 1}: ${day.timeValues.length} transitions');
    }

    return decoded;
  }

  /// Lit un schedule complet (infos de base + weekly-schedule)
  Future<BacnetScheduleInfo?> readScheduleFull({
    required String host,
    required int port,
    required int scheduleInstance,
    int? deviceId,
  }) async {
    // Lire les infos de base
    final basicInfo = await readScheduleBasicInfo(host: host, port: port, scheduleInstance: scheduleInstance, deviceId: deviceId);

    if (basicInfo == null) return null;

    // Lire le weekly-schedule
    final weeklySchedule = await readWeeklySchedule(host: host, port: port, scheduleInstance: scheduleInstance);

    return BacnetScheduleInfo(
      instance: basicInfo.instance,
      objectName: basicInfo.objectName,
      description: basicInfo.description,
      weeklySchedule: weeklySchedule,
      presentValue: basicInfo.presentValue,
      scheduleDefault: basicInfo.scheduleDefault,
      stateTexts: basicInfo.stateTexts,
      outOfService: basicInfo.outOfService,
    );
  }

  /// Écrit le weekly-schedule complet d'un objet Schedule BACnet
  /// Utilise WriteProperty avec l'encodage correct des BACnetTimeValue
  Future<bool> writeWeeklySchedule({
    required String host,
    required int port,
    required int scheduleInstance,
    required BacnetWeeklySchedule weeklySchedule,
  }) async {
    await init();

    _logger.i('writeWeeklySchedule: writing to schedule $scheduleInstance on $host:$port');

    // Debug: log what we're trying to write
    for (int i = 0; i < 7; i++) {
      final day = weeklySchedule.days[i];
      if (day.timeValues.isNotEmpty) {
        _logger.d('writeWeeklySchedule: Day ${i + 1}: ${day.timeValues.length} transitions');
        for (final tv in day.timeValues) {
          _logger.d('  - ${tv.hour}:${tv.minute} = ${tv.value} (tag: ${tv.valueTag})');
        }
      }
    }

    final response = await _sendConfirmed(
      host,
      port,
      (invokeId) => BacnetEncoder.encodeWriteWeeklyScheduleRequest(
        invokeId: invokeId,
        scheduleInstance: scheduleInstance,
        weeklySchedule: weeklySchedule,
      ),
    );

    if (response.isSuccess) {
      _logger.i('writeWeeklySchedule: Success');
      return true;
    } else {
      _logger.e('writeWeeklySchedule: Failed - ${response.errorMessage}');
      _logger.e('writeWeeklySchedule: error class=${response.errorClass}, code=${response.errorCode}');
      return false;
    }
  }

  /// Écrit un jour spécifique du weekly-schedule
  /// [dayIndex]: 1-7 (1=Lundi, 7=Dimanche)
  Future<bool> writeDailySchedule({
    required String host,
    required int port,
    required int scheduleInstance,
    required int dayIndex,
    required BacnetDailySchedule dailySchedule,
  }) async {
    await init();

    if (dayIndex < 1 || dayIndex > 7) {
      _logger.e('writeDailySchedule: Invalid dayIndex $dayIndex (must be 1-7)');
      return false;
    }

    _logger.i('writeDailySchedule: writing day $dayIndex to schedule $scheduleInstance');

    final response = await _sendConfirmed(
      host,
      port,
      (invokeId) => BacnetEncoder.encodeWriteDailyScheduleRequest(
        invokeId: invokeId,
        scheduleInstance: scheduleInstance,
        dayIndex: dayIndex,
        dailySchedule: dailySchedule,
      ),
    );

    if (response.isSuccess) {
      _logger.i('writeDailySchedule: Success for day $dayIndex');
      return true;
    } else {
      _logger.e('writeDailySchedule: Failed for day $dayIndex - ${response.errorMessage}');
      return false;
    }
  }
}

/// Info minimale d'un objet découvert
class _ObjectInfo {
  final int type;
  final int instance;

  _ObjectInfo({required this.type, required this.instance});
}

/// A confirmed request waiting for its answer
class _PendingRequest {
  final String key;
  final int invokeId;
  final Uint8List packet;
  final InternetAddress address;
  final int port;
  final Completer<BacnetResponse> completer = Completer<BacnetResponse>();
  Timer? timer;
  int attempts = 0;

  // Segmented ComplexACK reassembly
  BytesBuilder? segments;
  int? segmentServiceChoice;
  int expectedSequence = 0;

  _PendingRequest({required this.key, required this.invokeId, required this.packet, required this.address, required this.port});
}

/// Minimal async semaphore (FIFO)
class _Semaphore {
  final int maxCount;
  int _count = 0;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  _Semaphore(this.maxCount);

  Future<void> acquire() {
    if (_count < maxCount) {
      _count++;
      return Future.value();
    }
    final waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      // Hand the slot over to the next waiter
      _waiters.removeFirst().complete();
    } else if (_count > 0) {
      _count--;
    }
  }
}

/// Info d'un device répondant à Who-Is
class IAmInfo {
  final InternetAddress address;
  final int deviceId;

  /// UDP port the I-Am came from (origin port for a Forwarded-NPDU)
  final int port;

  /// Réseau BACnet d'origine (SNET, si le device est derrière un routeur)
  final int? networkNumber;

  /// Adresse MAC du device sur son réseau d'origine (SADR, si routé)
  final List<int>? macAddress;

  /// Liste des autres adresses ayant répondu avec le même deviceId (conflits)
  final List<InternetAddress> conflictingAddresses;

  /// Indique s'il y a un conflit de Device ID
  bool get hasConflict => conflictingAddresses.isNotEmpty;

  /// Adresse principale puis adresses en conflit, sans doublon
  List<InternetAddress> get allAddresses => [address, ...conflictingAddresses];

  IAmInfo({
    required this.address,
    required this.deviceId,
    this.port = 47808,
    this.networkNumber,
    this.macAddress,
    this.conflictingAddresses = const [],
  });

  /// True if [other] is the main address or an already known conflicting one
  bool knowsAddress(InternetAddress other) =>
      address.address == other.address || conflictingAddresses.any((a) => a.address == other.address);

  /// Crée une copie avec une adresse conflictuelle ajoutée (ignorée si déjà connue)
  IAmInfo withConflict(InternetAddress conflictAddress) {
    return IAmInfo(
      address: address,
      deviceId: deviceId,
      port: port,
      networkNumber: networkNumber,
      macAddress: macAddress,
      conflictingAddresses: knowsAddress(conflictAddress) ? conflictingAddresses : [...conflictingAddresses, conflictAddress],
    );
  }
}

/// Représente un conflit de Device ID détecté
class DeviceIdConflict {
  final int deviceId;
  final InternetAddress firstAddress;
  final InternetAddress secondAddress;
  final List<InternetAddress> allAddresses;
  final DateTime detectedAt;

  DeviceIdConflict({required this.deviceId, required this.firstAddress, required this.secondAddress, required this.allAddresses})
    : detectedAt = DateTime.now();

  @override
  String toString() =>
      'DeviceIdConflict(id=$deviceId, '
      'addresses=${allAddresses.map((a) => a.address).join(", ")})';
}

/// Info d'un routeur BACnet répondant à Who-Is-Router-To-Network
class RouterInfo {
  final InternetAddress address;
  final List<int> networks; // Liste des réseaux BACnet accessibles via ce routeur

  RouterInfo({required this.address, required this.networks});
}

/// Données rafraîchies d'un point BACnet
class RefreshedPointData {
  final dynamic presentValue;
  final bool isOverridden;
  final int? overridePriority;
  final dynamic overrideValue;
  final bool? outOfService;
  final bool inAlarm;
  final String? units;

  RefreshedPointData({
    this.presentValue,
    this.isOverridden = false,
    this.overridePriority,
    this.overrideValue,
    this.outOfService,
    this.inAlarm = false,
    this.units,
  });
}

/// Modèle pour un TrendLog BACnet découvert
class BacnetTrendLog {
  final int instance;
  final String objectName;
  final String? description;
  final String? logDeviceObjectProperty;
  final String? trackedObjectType;
  final int? trackedObjectInstance;
  final int? logInterval;
  final int? bufferSize;
  final int? recordCount;
  final int? totalRecordCount; // Numéro de séquence du dernier record (pour pagination)
  final bool? enabled;

  BacnetTrendLog({
    required this.instance,
    required this.objectName,
    this.description,
    this.logDeviceObjectProperty,
    this.trackedObjectType,
    this.trackedObjectInstance,
    this.logInterval,
    this.bufferSize,
    this.recordCount,
    this.totalRecordCount,
    this.enabled,
  });

  /// Clé pour le mapping: "objectType:objectInstance"
  String? get trackedObjectKey {
    if (trackedObjectType == null || trackedObjectInstance == null) {
      return null;
    }
    return '$trackedObjectType:$trackedObjectInstance';
  }
}

// =========================================================================
// Schedule BACnet Models
// =========================================================================

/// Informations complètes d'un schedule BACnet
class BacnetScheduleInfo {
  final int instance;
  final String objectName;
  final String? description;
  final DecodedWeeklySchedule? weeklySchedule;
  final dynamic presentValue;
  final dynamic scheduleDefault;
  final List<String>? stateTexts;
  final int? effectivePeriodStart; // En jours depuis 1900
  final int? effectivePeriodEnd;
  final bool? outOfService;

  BacnetScheduleInfo({
    required this.instance,
    required this.objectName,
    this.description,
    this.weeklySchedule,
    this.presentValue,
    this.scheduleDefault,
    this.stateTexts,
    this.effectivePeriodStart,
    this.effectivePeriodEnd,
    this.outOfService,
  });
}
