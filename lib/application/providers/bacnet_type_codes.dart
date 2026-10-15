import '../../data/services/bacnet/bacnet_constants.dart';
import '../../domain/models/bacnet_object.dart';

/// Convertit un BacnetObjectType en code numérique BACnet.
/// Exhaustive switch: adding an enum value forces a mapping here.
int bacnetObjectTypeCode(BacnetObjectType type) {
  switch (type) {
    case BacnetObjectType.analogInput:
      return BacnetObjectTypeCode.analogInput;
    case BacnetObjectType.analogOutput:
      return BacnetObjectTypeCode.analogOutput;
    case BacnetObjectType.analogValue:
      return BacnetObjectTypeCode.analogValue;
    case BacnetObjectType.binaryInput:
      return BacnetObjectTypeCode.binaryInput;
    case BacnetObjectType.binaryOutput:
      return BacnetObjectTypeCode.binaryOutput;
    case BacnetObjectType.binaryValue:
      return BacnetObjectTypeCode.binaryValue;
    case BacnetObjectType.multiStateInput:
      return BacnetObjectTypeCode.multiStateInput;
    case BacnetObjectType.multiStateOutput:
      return BacnetObjectTypeCode.multiStateOutput;
    case BacnetObjectType.multiStateValue:
      return BacnetObjectTypeCode.multiStateValue;
    case BacnetObjectType.schedule:
      return BacnetObjectTypeCode.schedule;
    case BacnetObjectType.calendar:
      return BacnetObjectTypeCode.calendar;
    case BacnetObjectType.trendLog:
      return BacnetObjectTypeCode.trendLog;
    case BacnetObjectType.notificationClass:
      return BacnetObjectTypeCode.notificationClass;
    case BacnetObjectType.device:
      return BacnetObjectTypeCode.device;
  }
}

/// Point BACnet parsé depuis un pointRef "shortName:instance" (ex: "AV:5")
typedef ParsedBacnetPointRef = ({
  String pointRef,
  BacnetObjectType type,
  int typeCode,
  int instance,
});

/// Parse un pointRef "shortName:instance". Retourne null si invalide.
ParsedBacnetPointRef? parseBacnetPointRef(String pointRef) {
  final parts = pointRef.split(':');
  if (parts.length != 2) return null;
  final type = BacnetObjectType.fromShortName(parts[0]);
  final instance = int.tryParse(parts[1]);
  if (type == null || instance == null) return null;
  return (pointRef: pointRef, type: type, typeCode: bacnetObjectTypeCode(type), instance: instance);
}
