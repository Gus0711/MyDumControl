import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/data/services/mdns_discovery_service.dart';

/// Minimal DNS response builder (uncompressed names unless a pointer is
/// given) used to reproduce the answers captured from the lab controllers.
class _Packet {
  final List<int> _bytes = [];
  final List<List<int>> _an = [];
  final List<List<int>> _ar = [];
  final bool response;

  _Packet({this.response = true});

  static List<int> name(String n) {
    final out = <int>[];
    for (final label in n.split('.')) {
      final b = utf8.encode(label);
      out
        ..add(b.length)
        ..addAll(b);
    }
    out.add(0);
    return out;
  }

  static List<int> _u16(int v) => [(v >> 8) & 0xFF, v & 0xFF];

  static List<int> record(List<int> owner, int type, List<int> rdata) => [
        ...owner,
        ..._u16(type),
        ..._u16(0x8001),
        0, 0, 0x11, 0x94, // TTL
        ..._u16(rdata.length),
        ...rdata,
      ];

  static List<int> txt(List<String> entries) => [
        for (final e in entries) ...[utf8.encode(e).length, ...utf8.encode(e)],
      ];

  static List<int> srv(int port, String target) =>
      [0, 0, 0, 0, ..._u16(port), ...name(target)];

  static List<int> a(String ip) => ip.split('.').map(int.parse).toList();

  void answer(List<int> r) => _an.add(r);
  void additional(List<int> r) => _ar.add(r);

  Uint8List build() {
    _bytes
      ..clear()
      ..addAll([0, 0, response ? 0x84 : 0x00, 0x00])
      ..addAll(_u16(0)) // questions
      ..addAll(_u16(_an.length))
      ..addAll(_u16(0))
      ..addAll(_u16(_ar.length));
    for (final r in [..._an, ..._ar]) {
      _bytes.addAll(r);
    }
    return Uint8List.fromList(_bytes);
  }
}

/// Legacy ECLYPSE (`_dcconf._udp`): SRV/TXT/A in the additional section,
/// as answered by 192.168.1.7 (CHAUFFERIE).
Uint8List _dcconfPacket({String access = '80;443', String name = 'CHAUFFERIE', String ip = '192.168.1.7'}) {
  final p = _Packet();
  final instance = '$name._dcconf._udp.local';
  p.answer(_Packet.record(_Packet.name('_dcconf._udp.local'), 12, _Packet.name(instance)));
  p.additional(_Packet.record(_Packet.name(instance), 33, _Packet.srv(80, '$name.local')));
  p.additional(_Packet.record(
    _Packet.name(instance),
    16,
    _Packet.txt([
      'restUrl=/api/rest/v1/',
      'mac=38:ab:41:a3:c9:d8',
      'access=$access',
      'type=Eclypse',
      'vendor=Distech Controls',
    ]),
  ));
  p.additional(_Packet.record(_Packet.name('$name.local'), 1, _Packet.a(ip)));
  p.additional(_Packet.record(_Packet.name('$name.local'), 28, List.filled(16, 0xfe)));
  return p.build();
}

/// New generation ECLYPSE (`_eclypse._tcp`), everything in the answers, as
/// answered by 192.168.1.49 (ECLYPSE-A018ED).
Uint8List _eclypseTcpPacket() {
  final p = _Packet();
  const instance = 'ECLYPSE-A018ED._eclypse._tcp.local';
  p.answer(_Packet.record(_Packet.name('_eclypse._tcp.local'), 12, _Packet.name(instance)));
  p.answer(_Packet.record(
    _Packet.name(instance),
    16,
    _Packet.txt(['model=40016C0005820427', 'mac=38:7f:cd:a0:18:ed']),
  ));
  p.answer(_Packet.record(_Packet.name(instance), 33, _Packet.srv(443, 'ECLYPSE-A018ED.local')));
  p.answer(_Packet.record(_Packet.name('ECLYPSE-A018ED.local'), 28, List.filled(16, 0xfd)));
  p.answer(_Packet.record(_Packet.name('ECLYPSE-A018ED.local'), 1, _Packet.a('192.168.1.49')));
  return p.build();
}

void main() {
  test('query asks for a PTR with the QU (unicast response) bit', () {
    // Legacy ECLYPSE (_dcconf) only answer to the query source port when
    // the QU bit is set.
    final q = MdnsDiscoveryService.buildMdnsQuery('_dcconf._udp.local');
    expect(q.sublist(4, 6), [0, 1]); // one question
    expect(q.sublist(12, q.length - 4), _Packet.name('_dcconf._udp.local'));
    expect(q.sublist(q.length - 4), [0x00, 0x0C, 0x80, 0x01]);
  });

  group('MdnsDiscoveryService.parseMdnsPacket', () {
    test('legacy _dcconf answer: reads the additional section and TXT', () {
      final device = MdnsDiscoveryService.parseMdnsPacket(_dcconfPacket(), '192.168.1.7')!;

      expect(device.name, 'CHAUFFERIE');
      expect(device.host, 'CHAUFFERIE.local');
      expect(device.ipAddress, '192.168.1.7');
      expect(device.serviceType, '_dcconf._udp');
      expect(device.port, 80); // SRV port
      expect(device.txtRecords['resturl'], '/api/rest/v1/');
      expect(device.macAddress, '38:ab:41:a3:c9:d8');
      expect(device.vendor, 'Distech Controls');
      expect(device.deviceType, 'Eclypse');
      expect(device.advertisedApiVersion, 'V1');
      expect(device.model, isNull);
      expect(device.firmwareVersion, isNull);
      // access=80;443 -> HTTPS on 443, not the SRV port 80
      expect(device.httpPort, 80);
      expect(device.httpsPort, 443);
      expect(device.prefersHttps, isTrue);
      expect(device.connectionPort, 443);
      expect(device.address, '192.168.1.7');
    });

    test('access=-1;443 means HTTP disabled', () {
      final device = MdnsDiscoveryService.parseMdnsPacket(
          _dcconfPacket(access: '-1;443', name: 'ECLYPSE-8D17B7', ip: '192.168.1.87'), '192.168.1.87')!;
      expect(device.name, 'ECLYPSE-8D17B7');
      expect(device.httpPort, isNull);
      expect(device.httpsPort, 443);
      expect(device.prefersHttps, isTrue);
      expect(device.connectionPort, 443);
    });

    test('HTTPS disabled falls back to HTTP', () {
      final device = MdnsDiscoveryService.parseMdnsPacket(_dcconfPacket(access: '8080;-1'), '192.168.1.7')!;
      expect(device.prefersHttps, isFalse);
      expect(device.connectionPort, 8080);
    });

    test('new generation _eclypse._tcp answer: model and HTTPS port', () {
      final device = MdnsDiscoveryService.parseMdnsPacket(_eclypseTcpPacket(), '192.168.1.49')!;
      expect(device.name, 'ECLYPSE-A018ED');
      expect(device.serviceType, '_eclypse._tcp');
      expect(device.ipAddress, '192.168.1.49');
      expect(device.port, 443);
      expect(device.model, '40016C0005820427');
      expect(device.macAddress, '38:7f:cd:a0:18:ed');
      expect(device.advertisedApiVersion, isNull);
      expect(device.prefersHttps, isTrue);
      expect(device.connectionPort, 443);
    });

    test('firmware is read when a device advertises it', () {
      final p = _Packet();
      const instance = 'X._eclypse._tcp.local';
      p.answer(_Packet.record(_Packet.name('_eclypse._tcp.local'), 12, _Packet.name(instance)));
      p.answer(_Packet.record(_Packet.name(instance), 16, _Packet.txt(['Firmware=1.23.4', 'Model=ECY-600'])));
      final device = MdnsDiscoveryService.parseMdnsPacket(p.build(), '10.0.0.5')!;
      expect(device.firmwareVersion, '1.23.4');
      expect(device.model, 'ECY-600');
      // No SRV / A: defaults
      expect(device.ipAddress, '10.0.0.5');
      expect(device.connectionPort, 443);
    });

    test('compressed names are resolved', () {
      // Header (12) + PTR record whose owner is at offset 12
      final ptrOwner = _Packet.name('_dcconf._udp.local');
      final instanceLabel = [...utf8.encode('CTA_NORD')];
      // PTR rdata: label "CTA_NORD" + pointer to offset 12
      final ptrRdata = [instanceLabel.length, ...instanceLabel, 0xC0, 12];
      final instanceOffset = 12 + ptrOwner.length + 10; // start of PTR rdata
      final srvOwner = [0xC0, instanceOffset];
      final bytes = <int>[
        0, 0, 0x84, 0, 0, 0, 0, 1, 0, 0, 0, 2,
        ..._Packet.record(ptrOwner, 12, ptrRdata),
        ..._Packet.record(srvOwner, 33, _Packet.srv(80, 'CTA_NORD.local')),
        ..._Packet.record(srvOwner, 16, _Packet.txt(['access=80;443', 'mac=f8:36:9b:a4:45:a1'])),
      ];
      final device = MdnsDiscoveryService.parseMdnsPacket(Uint8List.fromList(bytes), '192.168.1.6')!;
      expect(device.name, 'CTA_NORD');
      expect(device.host, 'CTA_NORD.local');
      expect(device.ipAddress, '192.168.1.6');
      expect(device.macAddress, 'f8:36:9b:a4:45:a1');
      expect(device.connectionPort, 443);
    });

    test('ignores queries, non ECLYPSE services and garbage', () {
      final query = _Packet(response: false)
        ..answer(_Packet.record(_Packet.name('_eclypse._tcp.local'), 12, _Packet.name('A._eclypse._tcp.local')));
      expect(MdnsDiscoveryService.parseMdnsPacket(query.build(), '1.2.3.4'), isNull);

      final other = _Packet()
        ..answer(_Packet.record(_Packet.name('_http._tcp.local'), 12, _Packet.name('Printer._http._tcp.local')))
        ..additional(_Packet.record(_Packet.name('Printer._http._tcp.local'), 33, _Packet.srv(80, 'printer.local')))
        ..additional(_Packet.record(_Packet.name('Printer._http._tcp.local'), 16, _Packet.txt(['model=LaserJet'])));
      expect(MdnsDiscoveryService.parseMdnsPacket(other.build(), '1.2.3.4'), isNull);

      expect(MdnsDiscoveryService.parseMdnsPacket(Uint8List.fromList([1, 2, 3]), '1.2.3.4'), isNull);
      // Truncated packet must not throw
      final truncated = _dcconfPacket();
      expect(
        () => MdnsDiscoveryService.parseMdnsPacket(Uint8List.sublistView(truncated, 0, 60), '1.2.3.4'),
        returnsNormally,
      );
    });
  });

  group('MdnsDiscoveryService.parseTxtRecord', () {
    test('parses key=value strings, lower-cases keys', () {
      final txt = MdnsDiscoveryService.parseTxtRecord(Uint8List.fromList(
        _Packet.txt(['restUrl=/api/rest/v1/', 'MAC=aa:bb', 'flag', 'empty=', 'eq=a=b']),
      ));
      expect(txt, {
        'resturl': '/api/rest/v1/',
        'mac': 'aa:bb',
        'flag': '',
        'empty': '',
        'eq': 'a=b',
      });
    });

    test('keeps the first occurrence and skips empty strings', () {
      final txt = MdnsDiscoveryService.parseTxtRecord(Uint8List.fromList([
        0,
        ..._Packet.txt(['model=A', 'model=B']),
      ]));
      expect(txt, {'model': 'A'});
    });

    test('stops on a truncated string', () {
      final txt = MdnsDiscoveryService.parseTxtRecord(Uint8List.fromList([
        ..._Packet.txt(['mac=aa']),
        20, 0x61, 0x62,
      ]));
      expect(txt, {'mac': 'aa'});
    });
  });

  group('EclypseDevice', () {
    test('advertised API version from restUrl', () {
      EclypseDevice d(String url) =>
          EclypseDevice(name: 'x', host: 'x', port: 80, txtRecords: {'resturl': url});
      expect(d('/api/rest/v1/').advertisedApiVersion, 'V1');
      expect(d('/api/rest/v2').advertisedApiVersion, 'V2');
      expect(d('/api/rest/').advertisedApiVersion, isNull);
    });

    test('without TXT access, the SRV port decides', () {
      expect(EclypseDevice(name: 'x', host: 'x', port: 443).prefersHttps, isTrue);
      expect(EclypseDevice(name: 'x', host: 'x', port: 80).prefersHttps, isFalse);
      expect(EclypseDevice(name: 'x', host: 'x', port: 80).connectionPort, 80);
    });
  });
}
