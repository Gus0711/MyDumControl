import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_constants.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_decoder.dart';

/// Wraps an APDU in BVLC Original-Unicast-NPDU + NPDU (no routing).
Uint8List frame(List<int> apdu, {List<int> npdu = const [0x01, 0x00], int bvlcFunction = 0x0A}) {
  final length = 4 + npdu.length + apdu.length;
  return Uint8List.fromList([0x81, bvlcFunction, length >> 8, length & 0xFF, ...npdu, ...apdu]);
}

/// ReadProperty-ACK of analog-value:1 / object-name with [valueBytes] in [3]
List<int> readPropertyAck(List<int> valueBytes, {int propertyId = 0x4D}) => [
      0x30, 0x01, 0x0C, // ComplexACK, invokeId 1, ReadProperty
      0x0C, 0x00, 0x80, 0x00, 0x01, // [0] analog-value:1
      0x19, propertyId, // [1] property
      0x3E, ...valueBytes, 0x3F,
    ];

/// One BACnetLogRecord: [0] date+time, [1] logDatum, [2] status-flags
List<int> logRecord({required List<int> date, required List<int> time, required List<int> datum}) => [
      0x0E, 0xA4, ...date, 0xB4, ...time, 0x0F,
      0x1E, ...datum, 0x1F,
      0x2A, 0x04, 0x00,
    ];

/// ReadRange-ACK of trend-log:1 / log-buffer
List<int> readRangeAck({required int flags, required List<List<int>> records, int firstSeq = 10}) => [
      0x30, 0x01, 0x1A, // ComplexACK, invokeId 1, ReadRange
      0x0C, 0x05, 0x00, 0x00, 0x01, // [0] trend-log:1
      0x19, 0x83, // [1] log-buffer (131)
      0x3A, 0x05, flags, // [3] result flags (5 unused bits)
      0x49, records.length, // [4] item count
      0x5E, for (final r in records) ...r, 0x5F,
      0x69, firstSeq, // [6] first sequence number
    ];

void main() {
  group('CharacterString (A8)', () {
    test('UTF-8 accents are decoded', () {
      final text = utf8.encode('Température °C');
      final r = BacnetDecoder.decode(frame(readPropertyAck([0x75, text.length + 1, 0x00, ...text])));
      expect(r.type, BacnetResponseType.readPropertyAck);
      expect(r.value, 'Température °C');
    });

    test('invalid UTF-8 with charset 0 falls back to ISO 8859-1', () {
      expect(BacnetDecoder.decodeCharacterString(0, [0x43, 0x68, 0x61, 0x75, 0x64, 0x69, 0xE8, 0x72, 0x65]), 'Chaudière');
    });

    test('UCS-2 (4), ISO 8859-1 (5) and UCS-4 (3)', () {
      expect(BacnetDecoder.decodeCharacterString(4, [0x00, 0xE9, 0x00, 0x74, 0x00, 0xE9]), 'été');
      expect(BacnetDecoder.decodeCharacterString(5, [0xB0, 0x43]), '°C');
      expect(BacnetDecoder.decodeCharacterString(3, [0x00, 0x00, 0x00, 0x41, 0x00, 0x00, 0x00, 0xE9]), 'Aé');
    });
  });

  group('ReadRange result flags (A6)', () {
    final record = logRecord(
      date: [126, 10, 15, 4], // 2026-10-15
      time: [12, 30, 0, 0],
      datum: [0x2C, 0x41, 0xAC, 0x00, 0x00], // [2] real 21.5
    );

    test('more-items is bit 2 (0x20), first-item bit 0 (0x80)', () {
      final more = BacnetDecoder.decode(frame(readRangeAck(flags: 0x20, records: [record]))).value as ReadRangeResult;
      expect(more.moreItems, isTrue);
      expect(more.firstItem, isFalse);
      expect(more.lastItem, isFalse);
      expect(more.firstSequenceNumber, 10);

      final first = BacnetDecoder.decode(frame(readRangeAck(flags: 0xC0, records: [record]))).value as ReadRangeResult;
      expect(first.firstItem, isTrue);
      expect(first.lastItem, isTrue);
      expect(first.moreItems, isFalse);
    });

    test('log record value and timestamp', () {
      final r = BacnetDecoder.decode(frame(readRangeAck(flags: 0, records: [record]))).value as ReadRangeResult;
      expect(r.records, hasLength(1));
      expect(r.records.first.timestamp, DateTime(2026, 10, 15, 12, 30));
      expect(r.records.first.value, closeTo(21.5, 1e-6));
    });
  });

  group('Log records (A21)', () {
    test('record with wildcard date is skipped, not stamped with now()', () {
      final bad = logRecord(date: [0xFF, 0xFF, 0xFF, 0xFF], time: [0, 0, 0, 0], datum: [0x2C, 0x41, 0xAC, 0x00, 0x00]);
      final good = logRecord(date: [126, 1, 2, 5], time: [3, 4, 5, 0], datum: [0x49, 0x01]); // [4] unsigned 1
      final r = BacnetDecoder.decode(frame(readRangeAck(flags: 0, records: [bad, good]))).value as ReadRangeResult;
      expect(r.records, hasLength(1));
      expect(r.records.first.timestamp, DateTime(2026, 1, 2, 3, 4, 5));
      expect(r.records.first.value, 1);
    });

    test('failure [8] datum is skipped without desynchronising the next record', () {
      final failure = logRecord(date: [126, 1, 2, 5], time: [0, 0, 0, 0], datum: [0x8E, 0x91, 0x01, 0x91, 0x1F, 0x8F]);
      final real = logRecord(date: [126, 1, 2, 5], time: [0, 15, 0, 0], datum: [0x2C, 0x3F, 0x80, 0x00, 0x00]); // 1.0
      final r = BacnetDecoder.decode(frame(readRangeAck(flags: 0, records: [failure, real]))).value as ReadRangeResult;
      expect(r.records, hasLength(2));
      expect(r.records[0].value, isNull);
      expect(r.records[1].value, 1.0);
      expect(r.records[1].timestamp, DateTime(2026, 1, 2, 0, 15));
    });
  });

  group('ReadPropertyMultiple (A19)', () {
    test('property access error [5] is reported, Null value is kept', () {
      final apdu = [
        0x30, 0x01, 0x0E, // ComplexACK RPM
        0x0C, 0x00, 0x00, 0x00, 0x01, // [0] analog-input:1
        0x1E,
        0x29, 0x55, 0x4E, 0x44, 0x41, 0xAC, 0x00, 0x00, 0x4F, // present-value 21.5
        0x29, 0x75, 0x5E, 0x91, 0x02, 0x91, 0x20, 0x5F, // units: error property / unknown-property
        0x29, 0x1C, 0x4E, 0x00, 0x4F, // description: Null
        0x1F,
      ];
      final r = BacnetDecoder.decode(frame(apdu));
      final props = r.multipleResults!.single.properties;
      expect(props, hasLength(3));
      expect(props[0].value, closeTo(21.5, 1e-6));
      expect(props[1].propertyId, BacnetPropertyId.units);
      expect(props[1].error, 'class=2, code=32');
      expect(props[2].propertyId, BacnetPropertyId.description);
      expect(props[2].value, isNull);
      expect(props[2].error, isNull);
    });
  });

  group('ReadProperty constructed value (A20)', () {
    test('log-device-object-property is decoded as a structure', () {
      final r = BacnetDecoder.decode(frame(readPropertyAck(
        [0x0C, 0x00, 0x80, 0x00, 0x05, 0x19, 0x55], // [0] analog-value:5, [1] present-value
        propertyId: 0x84,
      )));
      expect(r.value, isA<Map>());
      expect((r.value as Map)['objectIdentifier'], {'type': 2, 'instance': 5});
      expect((r.value as Map)['propertyIdentifier'], 85);
    });
  });

  group('NPDU / BVLC (A4, A17)', () {
    // I-Am device 5, max APDU 1476, segmented-both, vendor 15
    const iAm = [0x10, 0x00, 0xC4, 0x02, 0x00, 0x00, 0x05, 0x22, 0x05, 0xC4, 0x91, 0x00, 0x21, 0x0F];

    test('Forwarded-NPDU: NPDU read at offset 10 and origin address exposed', () {
      // Origin 192.168.1.10:47808 -> data[5] = 168 (looks like a network
      // layer message if the NPDU control were read at the wrong offset)
      final data = Uint8List.fromList([
        0x81, 0x04, 0x00, 4 + 6 + 2 + iAm.length,
        192, 168, 1, 10, 0xBA, 0xC0,
        0x01, 0x00, ...iAm,
      ]);
      final f = BacnetDecoder.parseFrame(data)!;
      expect(f.isNetworkLayerMessage, isFalse);
      expect(f.originAddress, '192.168.1.10');
      expect(f.originPort, 47808);
      expect(f.apduOffset, 12);
      final r = BacnetDecoder.decode(data);
      expect(r.type, BacnetResponseType.iAm);
      expect(r.objectInstance, 5);
    });

    test('routed I-Am exposes SNET / SADR', () {
      final data = frame(iAm, npdu: [0x01, 0x08, 0x00, 0x05, 0x01, 0x07], bvlcFunction: 0x0B);
      final f = BacnetDecoder.parseFrame(data)!;
      expect(f.npdu.sourceNetwork, 5);
      expect(f.npdu.sourceMac, [7]);
      expect(BacnetDecoder.decode(data).objectInstance, 5);
    });

    test('DNET + SNET: hop count comes after the source specifier', () {
      final data = frame(iAm, npdu: [0x01, 0x28, 0x00, 0x09, 0x00, 0x00, 0x05, 0x01, 0x07, 0xFF], bvlcFunction: 0x0B);
      final f = BacnetDecoder.parseFrame(data)!;
      expect(f.npdu.sourceNetwork, 5);
      expect(f.npdu.sourceMac, [7]);
      expect(BacnetDecoder.decode(data).objectInstance, 5);
    });
  });

  group('Segmentation (A3)', () {
    test('segment header and reassembly of a ReadProperty-ACK', () {
      // object-list of device:1 with 3 object identifiers
      final payload = [
        0x0C, 0x02, 0x00, 0x00, 0x01, 0x19, 0x4C, 0x3E,
        0xC4, 0x02, 0x00, 0x00, 0x01, // device:1
        0xC4, 0x00, 0x00, 0x00, 0x07, // analog-input:7
        0xC4, 0x05, 0x00, 0x00, 0x02, // trend-log:2
        0x3F,
      ];
      final seg0 = frame([0x3C, 0x07, 0x00, 0x04, 0x0C, ...payload.sublist(0, 12)]);
      final seg1 = frame([0x38, 0x07, 0x01, 0x04, 0x0C, ...payload.sublist(12)]);

      final h0 = BacnetDecoder.parseSegmentHeader(seg0, 6)!;
      expect(h0.invokeId, 7);
      expect(h0.sequenceNumber, 0);
      expect(h0.proposedWindowSize, 4);
      expect(h0.serviceChoice, ConfirmedService.readProperty);
      expect(h0.moreFollows, isTrue);
      final h1 = BacnetDecoder.parseSegmentHeader(seg1, 6)!;
      expect(h1.sequenceNumber, 1);
      expect(h1.moreFollows, isFalse);

      final r = BacnetDecoder.decodeReassembledComplexAck(
        invokeId: 7,
        serviceChoice: h0.serviceChoice,
        payload: [...seg0.sublist(h0.payloadOffset), ...seg1.sublist(h1.payloadOffset)],
      );
      expect(r.type, BacnetResponseType.readPropertyAck);
      expect(r.invokeId, 7);
      expect(r.value, [
        {'type': 8, 'instance': 1},
        {'type': 0, 'instance': 7},
        {'type': 20, 'instance': 2},
      ]);
    });

    test('unsegmented ComplexACK is not a segment', () {
      expect(BacnetDecoder.parseSegmentHeader(frame(readPropertyAck([0x21, 0x01])), 6), isNull);
    });
  });

  test('truncated APDU returns an error instead of throwing (A18)', () {
    expect(BacnetDecoder.decode(frame([0x50, 0x01])).isError, isTrue);
  });
}
