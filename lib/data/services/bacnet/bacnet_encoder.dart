import 'dart:convert';
import 'dart:typed_data';
import 'bacnet_constants.dart';

/// Encodeur de paquets BACnet/IP
class BacnetEncoder {
  // =========================================================================
  // Méthode utilitaire pour l'assemblage des paquets
  // =========================================================================

  /// Assemble un paquet BACnet/IP complet (BVLC + NPDU + APDU)
  /// Réduit la duplication de code dans les méthodes d'encodage
  static Uint8List _assemblePacket({
    required Uint8List apdu,
    required bool expectingReply,
    bool broadcast = false,
  }) {
    final npdu = _encodeNpduUnicast(expectingReply: expectingReply);
    final totalLength = 4 + npdu.length + apdu.length;
    final bvlc = broadcast
        ? _encodeBvlcBroadcast(totalLength)
        : _encodeBvlcUnicast(totalLength);

    return (BytesBuilder()
          ..add(bvlc)
          ..add(npdu)
          ..add(apdu))
        .toBytes();
  }

  // =========================================================================
  // Public API
  // =========================================================================

  /// Encode un paquet BACnet/IP complet pour ReadProperty
  static Uint8List encodeReadPropertyRequest({
    required int invokeId,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    int? arrayIndex,
  }) {
    final apdu = _encodeReadPropertyApdu(
      invokeId: invokeId,
      objectType: objectType,
      objectInstance: objectInstance,
      propertyId: propertyId,
      arrayIndex: arrayIndex,
    );
    return _assemblePacket(apdu: apdu, expectingReply: true);
  }

  /// Encode un paquet BACnet/IP complet pour WriteProperty
  static Uint8List encodeWritePropertyRequest({
    required int invokeId,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    required dynamic value,
    int? priority,
    int? arrayIndex,
  }) {
    final apdu = _encodeWritePropertyApdu(
      invokeId: invokeId,
      objectType: objectType,
      objectInstance: objectInstance,
      propertyId: propertyId,
      value: value,
      priority: priority,
      arrayIndex: arrayIndex,
    );
    return _assemblePacket(apdu: apdu, expectingReply: true);
  }

  /// Encode un paquet Who-Is (broadcast ou unicast)
  static Uint8List encodeWhoIsRequest({
    int? lowLimit,
    int? highLimit,
    bool broadcast = true,
  }) {
    final apdu = _encodeWhoIsApdu(lowLimit: lowLimit, highLimit: highLimit);
    return _assemblePacket(
      apdu: apdu,
      expectingReply: false,
      broadcast: broadcast,
    );
  }

  /// Encode un paquet ReadPropertyMultiple
  static Uint8List encodeReadPropertyMultipleRequest({
    required int invokeId,
    required List<ReadPropertyMultipleItem> items,
  }) {
    final apdu = _encodeReadPropertyMultipleApdu(
      invokeId: invokeId,
      items: items,
    );
    return _assemblePacket(apdu: apdu, expectingReply: true);
  }

  // =========================================================================
  // BVLC Encoding
  // =========================================================================

  /// Encode le header BVLC pour unicast
  static Uint8List _encodeBvlcUnicast(int totalLength) {
    return Uint8List.fromList([
      bvlcTypeBacnetIp, // 0x81
      BvlcFunction.originalUnicastNpdu, // 0x0A
      (totalLength >> 8) & 0xFF,
      totalLength & 0xFF,
    ]);
  }

  /// Encode le header BVLC pour broadcast
  static Uint8List _encodeBvlcBroadcast(int totalLength) {
    return Uint8List.fromList([
      bvlcTypeBacnetIp, // 0x81
      BvlcFunction.originalBroadcastNpdu, // 0x0B
      (totalLength >> 8) & 0xFF,
      totalLength & 0xFF,
    ]);
  }

  // =========================================================================
  // NPDU Encoding
  // =========================================================================

  /// Encode le header NPDU pour unicast simple (pas de routage)
  static Uint8List _encodeNpduUnicast({required bool expectingReply}) {
    int control = NpduControl.priorityNormal;
    if (expectingReply) {
      control |= NpduControl.expectingReply;
    }

    return Uint8List.fromList([
      npduVersion, // 0x01
      control,
    ]);
  }

  // =========================================================================
  // APDU Encoding
  // =========================================================================

  /// Encode l'APDU pour ReadProperty
  static Uint8List _encodeReadPropertyApdu({
    required int invokeId,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    int? arrayIndex,
  }) {
    final builder = BytesBuilder();

    // PDU Type + flags: Confirmed Request, no segmentation
    // Bits: 0000 SEG MOR SA _
    // Pour une requête simple: 0x00
    builder.addByte(ApduType.confirmedRequest);

    // Max response segments accepted (0 = no segmentation)
    // Max APDU length accepted: 0x05 = 1476 octets
    builder.addByte(0x05);

    // Invoke ID
    builder.addByte(invokeId & 0xFF);

    // Service Choice: ReadProperty = 12
    builder.addByte(ConfirmedService.readProperty);

    // Context tag [0]: Object Identifier
    _encodeContextObjectId(builder, 0, objectType, objectInstance);

    // Context tag [1]: Property Identifier
    _encodeContextUnsigned(builder, 1, propertyId);

    // Context tag [2]: Property Array Index (optional)
    if (arrayIndex != null) {
      _encodeContextUnsigned(builder, 2, arrayIndex);
    }

    return builder.toBytes();
  }

  /// Encode l'APDU pour WriteProperty
  static Uint8List _encodeWritePropertyApdu({
    required int invokeId,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    required dynamic value,
    int? priority,
    int? arrayIndex,
  }) {
    final builder = BytesBuilder();

    // PDU Type: Confirmed Request
    builder.addByte(ApduType.confirmedRequest);

    // Max segments + Max APDU size
    builder.addByte(0x05);

    // Invoke ID
    builder.addByte(invokeId & 0xFF);

    // Service Choice: WriteProperty = 15
    builder.addByte(ConfirmedService.writeProperty);

    // Context tag [0]: Object Identifier
    _encodeContextObjectId(builder, 0, objectType, objectInstance);

    // Context tag [1]: Property Identifier
    _encodeContextUnsigned(builder, 1, propertyId);

    // Context tag [2]: Property Array Index (optional)
    if (arrayIndex != null) {
      _encodeContextUnsigned(builder, 2, arrayIndex);
    }

    // Context tag [3]: Property Value (opening tag)
    builder.addByte(0x3E); // Opening tag for context 3

    // Encode the value with its application tag
    _encodeApplicationValue(builder, value);

    builder.addByte(0x3F); // Closing tag for context 3

    // Context tag [4]: Priority (optional)
    if (priority != null && priority >= 1 && priority <= 16) {
      _encodeContextUnsigned(builder, 4, priority);
    }

    return builder.toBytes();
  }

  /// Encode l'APDU pour Who-Is
  static Uint8List _encodeWhoIsApdu({int? lowLimit, int? highLimit}) {
    final builder = BytesBuilder();

    // PDU Type: Unconfirmed Request
    builder.addByte(ApduType.unconfirmedRequest);

    // Service Choice: Who-Is = 8
    builder.addByte(UnconfirmedService.whoIs);

    // Context tag [0]: Device Instance Range Low Limit (optional)
    if (lowLimit != null) {
      _encodeContextUnsigned(builder, 0, lowLimit);
    }

    // Context tag [1]: Device Instance Range High Limit (optional)
    if (highLimit != null) {
      _encodeContextUnsigned(builder, 1, highLimit);
    }

    return builder.toBytes();
  }

  /// Encode l'APDU pour ReadPropertyMultiple
  static Uint8List _encodeReadPropertyMultipleApdu({
    required int invokeId,
    required List<ReadPropertyMultipleItem> items,
  }) {
    final builder = BytesBuilder();

    // PDU Type: Confirmed Request
    builder.addByte(ApduType.confirmedRequest);
    builder.addByte(0x05); // Max segments + Max APDU
    builder.addByte(invokeId & 0xFF);
    builder.addByte(ConfirmedService.readPropertyMultiple);

    // Encode each read access specification
    for (final item in items) {
      // Object Identifier (context tag 0)
      _encodeContextObjectId(builder, 0, item.objectType, item.objectInstance);

      // List of property references (opening tag 1)
      builder.addByte(0x1E); // Opening tag for context 1

      for (final propId in item.propertyIds) {
        // Property Identifier (context tag 0)
        _encodeContextUnsigned(builder, 0, propId);
      }

      builder.addByte(0x1F); // Closing tag for context 1
    }

    return builder.toBytes();
  }

  // =========================================================================
  // Context Tag Encoding
  // =========================================================================

  /// Encode un Object Identifier avec context tag
  static void _encodeContextObjectId(
    BytesBuilder builder,
    int contextTag,
    int objectType,
    int objectInstance,
  ) {
    // Context tag N, length 4
    builder.addByte((contextTag << 4) | 0x0C); // 0x0C = context tag + length 4

    // Object Identifier: type (10 bits) + instance (22 bits)
    final objectId = ((objectType & 0x3FF) << 22) | (objectInstance & 0x3FFFFF);
    builder.addByte((objectId >> 24) & 0xFF);
    builder.addByte((objectId >> 16) & 0xFF);
    builder.addByte((objectId >> 8) & 0xFF);
    builder.addByte(objectId & 0xFF);
  }

  /// Encode un unsigned integer avec context tag
  static void _encodeContextUnsigned(
    BytesBuilder builder,
    int contextTag,
    int value,
  ) {
    if (value < 0x100) {
      // 1 byte
      builder.addByte((contextTag << 4) | 0x09); // Context tag + length 1
      builder.addByte(value & 0xFF);
    } else if (value < 0x10000) {
      // 2 bytes
      builder.addByte((contextTag << 4) | 0x0A); // Context tag + length 2
      builder.addByte((value >> 8) & 0xFF);
      builder.addByte(value & 0xFF);
    } else if (value < 0x1000000) {
      // 3 bytes
      builder.addByte((contextTag << 4) | 0x0B); // Context tag + length 3
      builder.addByte((value >> 16) & 0xFF);
      builder.addByte((value >> 8) & 0xFF);
      builder.addByte(value & 0xFF);
    } else {
      // 4 bytes
      builder.addByte((contextTag << 4) | 0x0C); // Context tag + length 4
      builder.addByte((value >> 24) & 0xFF);
      builder.addByte((value >> 16) & 0xFF);
      builder.addByte((value >> 8) & 0xFF);
      builder.addByte(value & 0xFF);
    }
  }

  // =========================================================================
  // Application Tag Encoding
  // =========================================================================

  /// Encode une valeur avec son application tag
  static void _encodeApplicationValue(BytesBuilder builder, dynamic value) {
    if (value == null) {
      // Null
      builder.addByte(0x00);
    } else if (value is bool) {
      // Boolean
      builder.addByte(value ? 0x11 : 0x10);
    } else if (value is int) {
      // Unsigned Integer
      _encodeApplicationUnsigned(builder, value);
    } else if (value is double) {
      // Real (float32)
      _encodeApplicationReal(builder, value);
    } else if (value is String) {
      // Character String
      _encodeApplicationCharacterString(builder, value);
    } else {
      // Fallback: try as unsigned
      _encodeApplicationUnsigned(builder, value as int);
    }
  }

  /// Encode un unsigned integer avec application tag
  static void _encodeApplicationUnsigned(BytesBuilder builder, int value) {
    if (value < 0x100) {
      builder.addByte(0x21); // Application tag 2, length 1
      builder.addByte(value & 0xFF);
    } else if (value < 0x10000) {
      builder.addByte(0x22); // Application tag 2, length 2
      builder.addByte((value >> 8) & 0xFF);
      builder.addByte(value & 0xFF);
    } else if (value < 0x1000000) {
      builder.addByte(0x23); // Application tag 2, length 3
      builder.addByte((value >> 16) & 0xFF);
      builder.addByte((value >> 8) & 0xFF);
      builder.addByte(value & 0xFF);
    } else {
      builder.addByte(0x24); // Application tag 2, length 4
      builder.addByte((value >> 24) & 0xFF);
      builder.addByte((value >> 16) & 0xFF);
      builder.addByte((value >> 8) & 0xFF);
      builder.addByte(value & 0xFF);
    }
  }

  /// Encode un Real (float32) avec application tag
  static void _encodeApplicationReal(BytesBuilder builder, double value) {
    builder.addByte(0x44); // Application tag 4, length 4

    // Convert to IEEE 754 float32
    final bytes = ByteData(4);
    bytes.setFloat32(0, value, Endian.big);
    builder.add(bytes.buffer.asUint8List());
  }

  /// Encode une CharacterString avec application tag
  /// Utilise l'encodage UTF-8 pour supporter les caractères internationaux
  static void _encodeApplicationCharacterString(
    BytesBuilder builder,
    String value,
  ) {
    final utf8Bytes = utf8.encode(value); // Encodage UTF-8 correct
    final length = utf8Bytes.length + 1; // +1 for encoding byte

    if (length <= 4) {
      builder.addByte(0x70 | length); // Application tag 7, length
    } else if (length <= 253) {
      builder.addByte(0x75); // Application tag 7, extended length
      builder.addByte(length);
    } else {
      builder.addByte(0x75);
      builder.addByte(0xFE); // 2-byte length follows
      builder.addByte((length >> 8) & 0xFF);
      builder.addByte(length & 0xFF);
    }

    // Character encoding: 0 = UTF-8
    builder.addByte(0x00);
    builder.add(utf8Bytes);
  }

  /// Encode un Enumerated avec application tag
  static void _encodeApplicationEnumerated(BytesBuilder builder, int value) {
    if (value < 0x100) {
      builder.addByte(0x91); // Application tag 9, length 1
      builder.addByte(value & 0xFF);
    } else if (value < 0x10000) {
      builder.addByte(0x92); // Application tag 9, length 2
      builder.addByte((value >> 8) & 0xFF);
      builder.addByte(value & 0xFF);
    } else {
      builder.addByte(0x94); // Application tag 9, length 4
      builder.addByte((value >> 24) & 0xFF);
      builder.addByte((value >> 16) & 0xFF);
      builder.addByte((value >> 8) & 0xFF);
      builder.addByte(value & 0xFF);
    }
  }

  /// Encode un paquet ReadRange (pour les listes/logs)
  static Uint8List encodeReadRangeRequest({
    required int invokeId,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    int? arrayIndex,
    ReadRangeType rangeType = ReadRangeType.all,
    int? referenceIndex,
    int? count,
    DateTime? referenceTime,
  }) {
    final apdu = _encodeReadRangeApdu(
      invokeId: invokeId,
      objectType: objectType,
      objectInstance: objectInstance,
      propertyId: propertyId,
      arrayIndex: arrayIndex,
      rangeType: rangeType,
      referenceIndex: referenceIndex,
      count: count,
      referenceTime: referenceTime,
    );
    return _assemblePacket(apdu: apdu, expectingReply: true);
  }

  /// Encode l'APDU pour ReadRange
  static Uint8List _encodeReadRangeApdu({
    required int invokeId,
    required int objectType,
    required int objectInstance,
    required int propertyId,
    int? arrayIndex,
    ReadRangeType rangeType = ReadRangeType.all,
    int? referenceIndex,
    int? count,
    DateTime? referenceTime,
  }) {
    final builder = BytesBuilder();

    // PDU Type: Confirmed Request
    builder.addByte(ApduType.confirmedRequest);
    builder.addByte(0x05); // Max segments + Max APDU
    builder.addByte(invokeId & 0xFF);
    builder.addByte(ConfirmedService.readRange); // 26

    // Context tag [0]: Object Identifier
    _encodeContextObjectId(builder, 0, objectType, objectInstance);

    // Context tag [1]: Property Identifier
    _encodeContextUnsigned(builder, 1, propertyId);

    // Context tag [2]: Property Array Index (optional)
    if (arrayIndex != null) {
      _encodeContextUnsigned(builder, 2, arrayIndex);
    }

    // Range specification (contexts 3-6)
    switch (rangeType) {
      case ReadRangeType.byPosition:
        // Context [3]: By Position
        if (referenceIndex != null && count != null) {
          builder.addByte(0x3E); // Opening tag for context 3
          _encodeApplicationUnsigned(builder, referenceIndex);
          _encodeApplicationSigned(builder, count);
          builder.addByte(0x3F); // Closing tag
        }
        break;
      case ReadRangeType.bySequenceNumber:
        // Context [6]: By Sequence Number
        if (referenceIndex != null && count != null) {
          builder.addByte(0x6E); // Opening tag for context 6
          _encodeApplicationUnsigned(builder, referenceIndex);
          _encodeApplicationSigned(builder, count);
          builder.addByte(0x6F); // Closing tag
        }
        break;
      case ReadRangeType.byTime:
        // Context [7]: By Time
        if (referenceTime != null && count != null) {
          builder.addByte(0x7E); // Opening tag for context 7
          _encodeApplicationDateTime(builder, referenceTime);
          _encodeApplicationSigned(builder, count);
          builder.addByte(0x7F); // Closing tag
        }
        break;
      case ReadRangeType.all:
        // No range specification = read all
        break;
    }

    return builder.toBytes();
  }

  /// Encode un signed integer avec application tag
  static void _encodeApplicationSigned(BytesBuilder builder, int value) {
    if (value >= -128 && value <= 127) {
      builder.addByte(0x31); // Application tag 3, length 1
      builder.addByte(value & 0xFF);
    } else if (value >= -32768 && value <= 32767) {
      builder.addByte(0x32); // Application tag 3, length 2
      builder.addByte((value >> 8) & 0xFF);
      builder.addByte(value & 0xFF);
    } else {
      builder.addByte(0x34); // Application tag 3, length 4
      builder.addByte((value >> 24) & 0xFF);
      builder.addByte((value >> 16) & 0xFF);
      builder.addByte((value >> 8) & 0xFF);
      builder.addByte(value & 0xFF);
    }
  }

  /// Encode un DateTime BACnet (Date + Time)
  static void _encodeApplicationDateTime(BytesBuilder builder, DateTime dt) {
    // BACnet Date: year-1900, month, day, day-of-week
    builder.addByte(0xA4); // Application tag 10 (date), length 4
    builder.addByte((dt.year - 1900) & 0xFF);
    builder.addByte(dt.month & 0xFF);
    builder.addByte(dt.day & 0xFF);
    builder.addByte(dt.weekday & 0xFF); // 1=Monday ... 7=Sunday

    // BACnet Time: hour, minute, second, hundredths
    builder.addByte(0xB4); // Application tag 11 (time), length 4
    builder.addByte(dt.hour & 0xFF);
    builder.addByte(dt.minute & 0xFF);
    builder.addByte(dt.second & 0xFF);
    builder.addByte((dt.millisecond ~/ 10) & 0xFF);
  }
}

/// Types de plage pour ReadRange
enum ReadRangeType {
  all,              // Pas de spécification = tous
  byPosition,       // Context [3]: par position (index, count)
  bySequenceNumber, // Context [6]: par numéro de séquence
  byTime,           // Context [7]: par date/heure
}

/// Item pour ReadPropertyMultiple
class ReadPropertyMultipleItem {
  final int objectType;
  final int objectInstance;
  final List<int> propertyIds;

  ReadPropertyMultipleItem({
    required this.objectType,
    required this.objectInstance,
    required this.propertyIds,
  });
}
