import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_constants.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_decoder.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_encoder.dart';

/// Returns the bytes between opening tag 3 (0x3E) and closing tag 3 (0x3F).
List<int> _encodedValue(List<int> packet) {
  final start = packet.indexOf(0x3E);
  final end = packet.lastIndexOf(0x3F);
  return packet.sublist(start + 1, end);
}

List<int> _writePv(int objectType, dynamic value) =>
    _encodedValue(BacnetEncoder.encodeWritePropertyRequest(
      invokeId: 1,
      objectType: objectType,
      objectInstance: 1,
      propertyId: BacnetPropertyId.presentValue,
      value: value,
    ));

void main() {
  test('BacnetEnumerated is encoded with application tag 9', () {
    expect(_writePv(BacnetObjectTypeCode.binaryValue, const BacnetEnumerated(1)), [0x91, 0x01]);
    expect(_writePv(BacnetObjectTypeCode.binaryValue, const BacnetEnumerated(0)), [0x91, 0x00]);
  });

  test('double is encoded as Real (tag 4)', () {
    expect(_writePv(BacnetObjectTypeCode.analogValue, 21.5), [0x44, 0x41, 0xAC, 0x00, 0x00]);
  });

  test('int is encoded as Unsigned (tag 2) for multi-state', () {
    expect(_writePv(BacnetObjectTypeCode.multiStateValue, 3), [0x21, 0x03]);
  });

  test('ReadProperty: segmented-response-accepted, max-segments >64, max-APDU 1476 (A3)', () {
    final packet = BacnetEncoder.encodeReadPropertyRequest(
      invokeId: 1,
      objectType: BacnetObjectTypeCode.device,
      objectInstance: 1234,
      propertyId: BacnetPropertyId.objectName,
    );
    expect(packet, [
      0x81, 0x0A, 0x00, 0x11, // BVLC Original-Unicast, length 17
      0x01, 0x04, // NPDU, expecting reply
      0x02, 0x75, 0x01, 0x0C, // Confirmed-Request SA=1, >64 segments / 1476, invokeId 1, ReadProperty
      0x0C, 0x02, 0x00, 0x04, 0xD2, // [0] device:1234
      0x19, 0x4D, // [1] object-name
    ]);
  });

  test('ReadProperty with array index (object-list element by element)', () {
    final packet = BacnetEncoder.encodeReadPropertyRequest(
      invokeId: 2,
      objectType: BacnetObjectTypeCode.device,
      objectInstance: 1,
      propertyId: BacnetPropertyId.objectList,
      arrayIndex: 0,
    );
    expect(packet.sublist(6), [0x02, 0x75, 0x02, 0x0C, 0x0C, 0x02, 0x00, 0x00, 0x01, 0x19, 0x4C, 0x29, 0x00]);
  });

  test('every confirmed service announces segmented-response-accepted', () {
    final rpm = BacnetEncoder.encodeReadPropertyMultipleRequest(invokeId: 3, items: [
      ReadPropertyMultipleItem(objectType: 0, objectInstance: 1, propertyIds: [85]),
    ]);
    final rr = BacnetEncoder.encodeReadRangeRequest(
      invokeId: 4,
      objectType: BacnetObjectTypeCode.trendLog,
      objectInstance: 1,
      propertyId: BacnetPropertyId.logBuffer,
      rangeType: ReadRangeType.bySequenceNumber,
      referenceIndex: 100,
      count: -65,
    );
    final wp = BacnetEncoder.encodeWritePropertyRequest(
      invokeId: 5, objectType: 2, objectInstance: 1, propertyId: 85, value: 1.0);
    for (final p in [rpm, rr, wp]) {
      expect(p.sublist(6, 8), [0x02, 0x75]);
    }
    expect(rr.sublist(10), [0x0C, 0x05, 0x00, 0x00, 0x01, 0x19, 0x83, 0x6E, 0x21, 0x64, 0x31, 0xBF, 0x6F]);
  });

  test('SegmentACK (A3)', () {
    expect(BacnetEncoder.encodeSegmentAck(invokeId: 5, sequenceNumber: 3, windowSize: 1),
        [0x81, 0x0A, 0x00, 0x0A, 0x01, 0x00, 0x40, 0x05, 0x03, 0x01]);
    expect(BacnetEncoder.encodeSegmentAck(invokeId: 5, sequenceNumber: 3, windowSize: 1, negative: true).sublist(6),
        [0x42, 0x05, 0x03, 0x01]);
  });

  test('Who-Is: limits only when both are given (A24)', () {
    expect(BacnetEncoder.encodeWhoIsRequest(), [0x81, 0x0B, 0x00, 0x08, 0x01, 0x00, 0x10, 0x08]);
    expect(BacnetEncoder.encodeWhoIsRequest(lowLimit: 5), [0x81, 0x0B, 0x00, 0x08, 0x01, 0x00, 0x10, 0x08]);
    expect(BacnetEncoder.encodeWhoIsRequest(lowLimit: 5, highLimit: 300, broadcast: false),
        [0x81, 0x0A, 0x00, 0x0D, 0x01, 0x00, 0x10, 0x08, 0x09, 0x05, 0x1A, 0x01, 0x2C]);
  });

  test('unsupported value type throws instead of a cast error (A2)', () {
    expect(
      () => BacnetEncoder.encodeWritePropertyRequest(
          invokeId: 1, objectType: 2, objectInstance: 1, propertyId: 85, value: DateTime(2026)),
      throwsArgumentError,
    );
  });

  group('weekly-schedule (A7)', () {
    final monday = BacnetDailySchedule(timeValues: [
      BacnetTimeValue(hour: 8, minute: 0, value: 1),
      BacnetTimeValue(hour: 18, minute: 30, value: 0),
    ]);

    test('single day written with array index is wrapped in [0]', () {
      final packet = BacnetEncoder.encodeWriteDailyScheduleRequest(
        invokeId: 1,
        scheduleInstance: 1,
        dayIndex: 2,
        dailySchedule: monday,
      );
      expect(packet.sublist(6), [
        0x02, 0x75, 0x01, 0x0F, // WriteProperty
        0x0C, 0x04, 0x40, 0x00, 0x01, // [0] schedule:1
        0x19, 0x7B, // [1] weekly-schedule
        0x29, 0x02, // [2] array index 2
        0x3E,
        0x0E, // day-schedule [0]
        0xB4, 0x08, 0x00, 0x00, 0x00, 0x91, 0x01,
        0xB4, 0x12, 0x1E, 0x00, 0x00, 0x91, 0x00,
        0x0F,
        0x3F,
      ]);
    });

    test('full week encode / decode round trip', () {
      final week = BacnetWeeklySchedule(days: [
        monday,
        BacnetDailySchedule.empty(),
        BacnetDailySchedule(timeValues: [BacnetTimeValue(hour: 6, minute: 15, value: 21.5, valueTag: ScheduleValueTag.real)]),
        BacnetDailySchedule.empty(),
        BacnetDailySchedule.empty(),
        BacnetDailySchedule.empty(),
        BacnetDailySchedule(timeValues: [BacnetTimeValue(hour: 0, minute: 0, value: null)]),
      ]);
      final request = BacnetEncoder.encodeWriteWeeklyScheduleRequest(
        invokeId: 1,
        scheduleInstance: 1,
        weeklySchedule: week,
      );
      // Value of the WriteProperty = bytes between [3] opening/closing tags
      final open = request.indexOf(0x3E);
      final value = request.sublist(open + 1, request.length - 1);
      expect(request.last, 0x3F);

      // Same bytes as the property value of a ReadProperty-ACK
      final apdu = [
        0x30, 0x01, 0x0C,
        0x0C, 0x04, 0x40, 0x00, 0x01, 0x19, 0x7B,
        0x3E, ...value, 0x3F,
      ];
      final ack = Uint8List.fromList([0x81, 0x0A, 0x00, 6 + apdu.length, 0x01, 0x00, ...apdu]);
      final decoded = BacnetDecoder.decode(ack).value as DecodedWeeklySchedule;

      expect(decoded.days[0].timeValues.map((tv) => [tv.hour, tv.minute, tv.value, tv.valueTag]).toList(), [
        [8, 0, 1, 9],
        [18, 30, 0, 9],
      ]);
      expect(decoded.days[1].timeValues, isEmpty);
      expect(decoded.days[2].timeValues.single.value, closeTo(21.5, 1e-6));
      expect(decoded.days[2].timeValues.single.valueTag, 4);
      expect(decoded.days[6].timeValues.single.value, isNull);
    });
  });
}
