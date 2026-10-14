import 'package:flutter_test/flutter_test.dart';
import 'package:myglobaldc/data/services/bacnet/bacnet_constants.dart';
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
}
