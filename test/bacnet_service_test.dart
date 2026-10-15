import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_constants.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_decoder.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_network.dart';
import 'package:myglobaldc/data/services/bacnet_service.dart';

/// BVLC Original-Unicast + NPDU without routing around an APDU
Uint8List frame(List<int> apdu) {
  final length = 6 + apdu.length;
  return Uint8List.fromList([0x81, 0x0A, length >> 8, length & 0xFF, 0x01, 0x00, ...apdu]);
}

/// Minimal BACnet device on a loopback address, scripted by [onDatagram]
class FakeDevice {
  final RawDatagramSocket socket;
  final List<Datagram> received = [];
  void Function(Datagram d)? onDatagram;

  FakeDevice._(this.socket) {
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      Datagram? d;
      while ((d = socket.receive()) != null) {
        received.add(d!);
        onDatagram?.call(d);
      }
    });
  }

  static Future<FakeDevice> bind([String ip = '127.0.0.1']) async =>
      FakeDevice._(await RawDatagramSocket.bind(InternetAddress(ip), 0));

  int get port => socket.port;
  String get host => socket.address.address;

  void send(Datagram to, List<int> bytes) => socket.send(bytes, to.address, to.port);

  /// Confirmed requests only (APDU type 0)
  List<Datagram> get requests => received.where((d) => d.data.length > 9 && (d.data[6] & 0xF0) == 0x00).toList();

  void close() => socket.close();
}

int invokeIdOf(Datagram d) => d.data[8];

/// ReadProperty-ACK for device:1 / object-name = 'X'
List<int> objectNameAck(int invokeId, String name) => [
      0x30, invokeId, 0x0C,
      0x0C, 0x02, 0x00, 0x00, 0x01, 0x19, 0x4D,
      0x3E, 0x75, name.length + 1, 0x00, ...name.codeUnits, 0x3F,
    ];

const iAmDevice1234 = [0x10, 0x00, 0xC4, 0x02, 0x00, 0x04, 0xD2, 0x22, 0x05, 0xC4, 0x91, 0x00, 0x21, 0x0F];

Future<BacnetResponse> readName(BacnetService service, FakeDevice device) => service.readProperty(
      host: device.host,
      port: device.port,
      objectType: BacnetObjectTypeCode.device,
      objectInstance: 1,
      propertyId: BacnetPropertyId.objectName,
    );

void main() {
  late BacnetService service;
  final fakes = <FakeDevice>[];

  Future<FakeDevice> fake([String ip = '127.0.0.1']) async {
    final f = await FakeDevice.bind(ip);
    fakes.add(f);
    return f;
  }

  setUp(() {
    service = BacnetService(timeout: const Duration(milliseconds: 300), retries: 1);
  });

  tearDown(() {
    service.dispose();
    for (final f in fakes) {
      f.close();
    }
    fakes.clear();
  });

  test('concurrent init() calls share one socket (A1)', () async {
    await Future.wait([service.init(), service.init(), service.init()]);
    expect(service.actualPort, isNotNull);
  });

  test('47808 already shared by another socket: dynamic port, replies still received', () async {
    // Another BACnet tool (or a second instance of the app) that opened
    // 47808 with SO_REUSEADDR. A non-exclusive bind would share the port,
    // but on Windows unicast replies keep going to the first socket.
    RawDatagramSocket? other;
    try {
      other = await RawDatagramSocket.bind(InternetAddress.anyIPv4, BacnetService.standardBacnetPort, reuseAddress: true);
    } on SocketException {
      // Already held exclusively by something else: same situation
    }
    try {
      final device = await fake();
      device.onDatagram = (d) => device.send(d, frame(objectNameAck(invokeIdOf(d), 'AHU')));
      final r = await readName(service, device);
      expect(service.isUsingStandardPort, isFalse);
      expect(r.value, 'AHU');
    } finally {
      other?.close();
    }
  });

  test('47808 held on an interface IP (YABE): dynamic port', () async {
    // YABE binds <interface IP>:47808: more specific than our 0.0.0.0:47808,
    // it would receive every unicast reply sent to that interface.
    final iface = (await BacnetNetwork.listIpv4Interfaces())
        .where((i) => !BacnetNetwork.isVirtualInterface(i.name) && !i.address.startsWith('127.'))
        .firstOrNull;
    if (iface == null) return markTestSkipped('no physical IPv4 interface');
    final ip = InternetAddress(iface.address);
    RawDatagramSocket? other;
    try {
      other = await RawDatagramSocket.bind(ip, BacnetService.standardBacnetPort, reuseAddress: false);
    } on SocketException {
      // Already held by another program: same situation
    }
    try {
      await service.init();
      expect(service.isUsingStandardPort, isFalse);
    } finally {
      other?.close();
    }
  }, skip: !Platform.isWindows);

  test('a lost request is retried with the same invoke ID (A9)', () async {
    final device = await fake();
    device.onDatagram = (d) {
      if (device.requests.length == 2) device.send(d, frame(objectNameAck(invokeIdOf(d), 'AHU')));
    };
    final r = await readName(service, device);
    expect(r.isSuccess, isTrue);
    expect(r.value, 'AHU');
    expect(device.requests, hasLength(2));
    expect(invokeIdOf(device.requests[0]), invokeIdOf(device.requests[1]));
  });

  test('no answer gives a timeout response after the retries (A11)', () async {
    final device = await fake();
    final r = await readName(service, device);
    expect(r.type, BacnetResponseType.timeout);
    expect(r.isError, isTrue);
    expect(r.isDeviceError, isFalse);
    expect(device.requests, hasLength(2));
  });

  test('RPM timeout does not cascade into one ReadProperty per property (A11)', () async {
    final device = await fake();
    final result = await service.testConnection(host: device.host, port: device.port, deviceId: 1);
    // No answer is a failure, not a device without a name
    expect(result.success, isFalse);
    expect(result.deviceName, isNull);
    // 1 RPM + 1 retry, no ReadProperty fallback
    expect(device.requests, hasLength(2));
    expect(device.requests.every((d) => d.data[9] == ConfirmedService.readPropertyMultiple), isTrue);
  });

  test('RPM rejected: falls back to ReadProperty (A11)', () async {
    final device = await fake();
    device.onDatagram = (d) {
      if (d.data.length < 10 || (d.data[6] & 0xF0) != 0) return;
      final id = invokeIdOf(d);
      if (d.data[9] == ConfirmedService.readPropertyMultiple) {
        device.send(d, frame([0x60, id, 0x09])); // Reject unrecognized-service
      } else {
        device.send(d, frame(objectNameAck(id, 'DEV')));
      }
    };
    final result = await service.testConnection(host: device.host, port: device.port, deviceId: 1);
    expect(result.success, isTrue);
    expect(result.deviceName, 'DEV');
  });

  test('segmented ComplexACK is reassembled and acknowledged (A3)', () async {
    final device = await fake();
    final payload = [
      0x0C, 0x02, 0x00, 0x00, 0x01, 0x19, 0x4C, 0x3E,
      0xC4, 0x02, 0x00, 0x00, 0x01,
      0xC4, 0x00, 0x00, 0x00, 0x07,
      0xC4, 0x05, 0x00, 0x00, 0x02,
      0x3F,
    ];
    final acks = <List<int>>[];
    device.onDatagram = (d) {
      final apdu = d.data.sublist(6);
      if ((apdu[0] & 0xF0) == 0x00) {
        // First segment, proposed window 4
        device.send(d, frame([0x3C, apdu[2], 0x00, 0x04, 0x0C, ...payload.sublist(0, 12)]));
      } else if ((apdu[0] & 0xF0) == 0x40) {
        acks.add(apdu);
        if (apdu[2] == 0) {
          device.send(d, frame([0x38, apdu[1], 0x01, 0x04, 0x0C, ...payload.sublist(12)]));
        }
      }
    };
    final r = await service.readProperty(
      host: device.host,
      port: device.port,
      objectType: BacnetObjectTypeCode.device,
      objectInstance: 1,
      propertyId: BacnetPropertyId.objectList,
    );
    expect(r.type, BacnetResponseType.readPropertyAck);
    expect(r.value, [
      {'type': 8, 'instance': 1},
      {'type': 0, 'instance': 7},
      {'type': 20, 'instance': 2},
    ]);
    // Wait for the last SegmentACK to arrive
    await Future.delayed(const Duration(milliseconds: 50));
    final id = invokeIdOf(device.requests.first);
    expect(acks, [
      [0x40, id, 0x00, 0x01],
      [0x40, id, 0x01, 0x01],
    ]);
  });

  test('object-list too large: read element by element after Abort (A3)', () async {
    final device = await fake();
    device.onDatagram = (d) {
      final apdu = d.data.sublist(6);
      if ((apdu[0] & 0xF0) != 0x00) return;
      final id = apdu[2];
      if (apdu[3] == ConfirmedService.readProperty && apdu.length == 11) {
        device.send(d, frame([0x71, id, 0x04])); // Abort segmentation-not-supported
      } else if (apdu[3] == ConfirmedService.readProperty) {
        final index = apdu[12];
        final value = index == 0
            ? [0x21, 0x02]
            : [0xC4, 0x00, 0x00, 0x00, index]; // analog-input:<index>
        device.send(d, frame([
          0x30, id, 0x0C, 0x0C, 0x02, 0x00, 0x00, 0x01, 0x19, 0x4C, 0x29, index, 0x3E, ...value, 0x3F,
        ]));
      } else {
        device.send(d, frame([0x50, id, apdu[3], 0x91, 0x01, 0x91, 0x1F])); // Error unknown-object
      }
    };
    final objects = await service.discoverObjects(host: device.host, port: device.port, deviceId: 1);
    // Both analog inputs are discovered (properties could not be read: RPM
    // and ReadProperty return Error, so the objects are skipped) -> check
    // the requests instead
    expect(objects, isEmpty);
    final indexes = device.requests
        .where((d) => d.data[9] == ConfirmedService.readProperty && d.data.length == 19)
        .map((d) => d.data[18])
        .toList();
    expect(indexes, unorderedEquals([0, 1, 2]));
    final rpmTargets = device.requests.where((d) => d.data[9] == ConfirmedService.readPropertyMultiple).map((d) => d.data[14]).toSet();
    expect(rpmTargets, {1, 2});
  });

  test('refreshMultiplePointValues groups several objects in one RPM (A10)', () async {
    final device = await fake();
    device.onDatagram = (d) {
      final id = invokeIdOf(d);
      device.send(d, frame([
        0x30, id, 0x0E,
        for (final instance in [1, 2, 3]) ...[
          0x0C, 0x00, 0x00, 0x00, instance, 0x1E,
          0x29, 0x55, 0x4E, 0x44, 0x41, 0xA0 + instance, 0x00, 0x00, 0x4F,
          0x29, 0x6F, 0x4E, 0x82, 0x04, 0x80, 0x4F, // status-flags: in-alarm
          0x29, 0x75, 0x4E, 0x91, 0x3E, 0x4F, // units 62 (degrees-celsius)
          0x29, 0x51, 0x4E, 0x10, 0x4F, // out-of-service false
          0x1F,
        ],
      ]));
    };
    final results = await service.refreshMultiplePointValues(
      host: device.host,
      port: device.port,
      points: [
        for (final i in [1, 2, 3]) (objectType: 0, objectInstance: i, isCommandable: false, isInput: true),
      ],
    );
    expect(device.requests, hasLength(1));
    expect(results.keys, unorderedEquals(['0:1', '0:2', '0:3']));
    expect(results['0:2']!.presentValue, 20.25); // 0x41A20000
    expect(results['0:2']!.inAlarm, isTrue);
    expect(results['0:2']!.outOfService, isFalse);
  });

  test('groupPointsForRpm respects the APDU budget', () {
    final points = [
      for (int i = 0; i < 30; i++) (objectType: 2, objectInstance: i, isCommandable: true, isInput: false),
    ];
    final groups = BacnetService.groupPointsForRpm(points);
    expect(groups.length, greaterThan(1));
    expect(groups.expand((g) => g).length, 30);
    for (final g in groups) {
      expect(g.length * 130, lessThanOrEqualTo(1200));
    }
  });

  test('rebind fails pending requests immediately (A13)', () async {
    final slow = BacnetService(timeout: const Duration(seconds: 5));
    try {
      final device = await fake();
      final future = readName(slow, device);
      await Future.delayed(const Duration(milliseconds: 50));
      final sw = Stopwatch()..start();
      await slow.rebindToInterface(null);
      final r = await future;
      expect(sw.elapsed, lessThan(const Duration(seconds: 1)));
      expect(r.isSuccess, isFalse);
      expect(r.type, isNot(BacnetResponseType.timeout));
    } finally {
      slow.dispose();
    }
  });

  test('whoIs finds a device already seen by a previous whoIs (A5)', () async {
    final device = await fake();
    device.onDatagram = (d) => device.send(d, frame(iAmDevice1234));
    final first = await service.whoIs(host: device.host, port: device.port, timeout: const Duration(milliseconds: 200));
    final second = await service.whoIs(host: device.host, port: device.port, timeout: const Duration(milliseconds: 200));
    expect(first.map((d) => d.deviceId), [1234]);
    expect(second.map((d) => d.deviceId), [1234]);
    expect(second.single.port, device.port);
  });

  group('Linux loopback aliases', () {
    test('response from another address is ignored (A9)', () async {
      final device = await fake('127.0.0.1');
      final spoofer = await fake('127.0.0.2');
      device.onDatagram = (d) {
        final id = invokeIdOf(d);
        spoofer.send(d, frame(objectNameAck(id, 'EVIL')));
        Timer(const Duration(milliseconds: 30), () => device.send(d, frame(objectNameAck(id, 'GOOD'))));
      };
      final r = await readName(service, device);
      expect(r.value, 'GOOD');
    });

    test('Forwarded-NPDU I-Am uses the origin address (A4)', () async {
      // Device at 127.200.0.1: 2nd octet >= 128 was read as a network
      // layer message when the NPDU offset was wrong
      final device = await fake('127.200.0.1');
      final bbmd = await fake('127.0.0.2');
      device.onDatagram = (d) {
        final npdu = [0x01, 0x00, ...iAmDevice1234];
        bbmd.send(d, [
          0x81, 0x04, 0x00, 10 + npdu.length,
          127, 200, 0, 1, device.port >> 8, device.port & 0xFF,
          ...npdu,
        ]);
      };
      final devices = await service.whoIs(host: device.host, port: device.port, timeout: const Duration(milliseconds: 200));
      expect(devices, hasLength(1));
      expect(devices.single.address.address, '127.200.0.1');
      expect(devices.single.port, device.port);
    });
  }, skip: Platform.isLinux ? false : 'needs 127.0.0.0/8 loopback aliases');
}
