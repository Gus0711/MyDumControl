import 'dart:convert';
import 'dart:typed_data';
import 'bacnet_constants.dart';

/// Wraps an int so it is encoded as a BACnet Enumerated (tag 9)
/// instead of Unsigned (e.g. present-value of binary objects).
class BacnetEnumerated {
  final int value;
  const BacnetEnumerated(this.value);
}

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

  /// Byte 0 of a Confirmed-Request: PDU type 0, SEG=0, MOR=0,
  /// SA=1 (segmented-response-accepted).
  static const int confirmedRequestHeader = ApduType.confirmedRequest | 0x02;

  /// Byte 1 of a Confirmed-Request: max-segments-accepted = 7 (more than 64)
  /// in bits 6-4, max-APDU-length-accepted = 5 (1476 octets) in bits 3-0.
  static const int maxSegmentsAndApdu = 0x75;

  /// Writes the 4-byte header of a Confirmed-Request APDU
  static void _encodeConfirmedHeader(BytesBuilder builder, int invokeId, int serviceChoice) {
    builder.addByte(confirmedRequestHeader);
    builder.addByte(maxSegmentsAndApdu);
    builder.addByte(invokeId & 0xFF);
    builder.addByte(serviceChoice);
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

  /// Encode un paquet Who-Is-Router-To-Network (Network Layer Message)
  /// Utilisé pour découvrir les routeurs BACnet et les réseaux qu'ils desservent
  /// [networkNumber] optionnel: si fourni, demande spécifiquement le routeur vers ce réseau
  static Uint8List encodeWhoIsRouterToNetwork({int? networkNumber}) {
    final builder = BytesBuilder();

    // BVLC Header (broadcast)
    builder.addByte(bvlcTypeBacnetIp); // 0x81
    builder.addByte(BvlcFunction.originalBroadcastNpdu); // 0x0B
    // Length placeholder - will be updated
    builder.addByte(0x00);
    builder.addByte(0x00);

    // NPDU Header
    builder.addByte(npduVersion); // 0x01
    // Control: Network Layer Message, no destination/source specifier
    builder.addByte(NpduControl.networkLayerMessage); // 0x80

    // Network Layer Message Type: Who-Is-Router-To-Network
    builder.addByte(NetworkLayerMessageType.whoIsRouterToNetwork); // 0x00

    // Optional: specific network number to query
    if (networkNumber != null) {
      builder.addByte((networkNumber >> 8) & 0xFF);
      builder.addByte(networkNumber & 0xFF);
    }

    final packet = builder.toBytes();
    // Update length in BVLC header
    packet[2] = (packet.length >> 8) & 0xFF;
    packet[3] = packet.length & 0xFF;

    return packet;
  }

  /// Encode un paquet Who-Is avec destination réseau spécifique
  /// Utilisé pour envoyer Who-Is à un réseau BACnet distant via un routeur
  static Uint8List encodeWhoIsToNetwork({
    required int destinationNetwork,
    int? lowLimit,
    int? highLimit,
  }) {
    final apdu = _encodeWhoIsApdu(lowLimit: lowLimit, highLimit: highLimit);

    final builder = BytesBuilder();

    // BVLC Header (broadcast)
    builder.addByte(bvlcTypeBacnetIp); // 0x81
    builder.addByte(BvlcFunction.originalBroadcastNpdu); // 0x0B
    // Length placeholder
    builder.addByte(0x00);
    builder.addByte(0x00);

    // NPDU Header avec destination network
    builder.addByte(npduVersion); // 0x01
    // Control: destination specifier set
    builder.addByte(NpduControl.destinationSpecifier); // 0x20

    // DNET (destination network)
    builder.addByte((destinationNetwork >> 8) & 0xFF);
    builder.addByte(destinationNetwork & 0xFF);

    // DLEN = 0 means broadcast to all devices on that network
    builder.addByte(0x00);

    // Hop count
    builder.addByte(0xFF); // 255 hops max

    // APDU
    builder.add(apdu);

    final packet = builder.toBytes();
    // Update length
    packet[2] = (packet.length >> 8) & 0xFF;
    packet[3] = packet.length & 0xFF;

    return packet;
  }

  /// Encodes a SegmentACK sent by the client for a segmented ComplexACK.
  /// [negative] = NAK (segment out of order: ask for retransmission after
  /// [sequenceNumber]).
  static Uint8List encodeSegmentAck({
    required int invokeId,
    required int sequenceNumber,
    required int windowSize,
    bool negative = false,
  }) {
    final apdu = Uint8List.fromList([
      ApduType.segmentAck | (negative ? 0x02 : 0x00), // SRV = 0 (from client)
      invokeId & 0xFF,
      sequenceNumber & 0xFF,
      windowSize & 0xFF,
    ]);
    return _assemblePacket(apdu: apdu, expectingReply: false);
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

    // Confirmed Request header, ReadProperty = 12
    _encodeConfirmedHeader(builder, invokeId, ConfirmedService.readProperty);

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

    // Confirmed Request header, WriteProperty = 15
    _encodeConfirmedHeader(builder, invokeId, ConfirmedService.writeProperty);

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

    // Context tags [0] low limit and [1] high limit: the standard requires
    // both or none, a single limit would be an invalid request
    if (lowLimit != null && highLimit != null) {
      _encodeContextUnsigned(builder, 0, lowLimit);
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

    _encodeConfirmedHeader(builder, invokeId, ConfirmedService.readPropertyMultiple);

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
    } else if (value is BacnetEnumerated) {
      _encodeApplicationEnumerated(builder, value.value);
    } else if (value is int) {
      // Unsigned Integer (Signed Integer if negative)
      if (value < 0) {
        _encodeApplicationSigned(builder, value);
      } else {
        _encodeApplicationUnsigned(builder, value);
      }
    } else if (value is double) {
      // Real (float32)
      _encodeApplicationReal(builder, value);
    } else if (value is String) {
      // Character String
      _encodeApplicationCharacterString(builder, value);
    } else {
      throw ArgumentError.value(value, 'value', 'Unsupported BACnet application value type ${value.runtimeType}');
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

    _encodeConfirmedHeader(builder, invokeId, ConfirmedService.readRange); // 26

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

  // =========================================================================
  // Schedule Encoding Methods
  // =========================================================================

  /// Encode une heure BACnet (Application tag 11, 4 bytes)
  static void _encodeApplicationTime(BytesBuilder builder, int hour, int minute, int second, int hundredths) {
    builder.addByte(0xB4); // Application tag 11 (time), length 4
    builder.addByte(hour & 0xFF);
    builder.addByte(minute & 0xFF);
    builder.addByte(second & 0xFF);
    builder.addByte(hundredths & 0xFF);
  }

  /// Encode une valeur de schedule avec le bon application tag
  /// Supporte: null, boolean, unsigned, signed, real, enumerated
  static void _encodeScheduleValue(BytesBuilder builder, dynamic value, ScheduleValueTag? forceTag) {
    if (value == null) {
      // Null value - Application tag 0
      builder.addByte(0x00);
      return;
    }

    // Déterminer le tag à utiliser
    ScheduleValueTag tag;
    if (forceTag != null) {
      tag = forceTag;
    } else if (value is bool) {
      tag = ScheduleValueTag.boolean;
    } else if (value is double) {
      tag = ScheduleValueTag.real;
    } else if (value is int) {
      // Par défaut, utiliser enumerated pour les entiers (plus courant dans les schedules)
      tag = ScheduleValueTag.enumerated;
    } else {
      // Fallback: null
      builder.addByte(0x00);
      return;
    }

    switch (tag) {
      case ScheduleValueTag.nullValue:
        builder.addByte(0x00);
        break;

      case ScheduleValueTag.boolean:
        // Boolean: tag 1, valeur dans le tag byte lui-même
        final boolVal = value is bool ? value : (value == 1 || value == 'true');
        builder.addByte(boolVal ? 0x11 : 0x10);
        break;

      case ScheduleValueTag.unsigned:
        _encodeApplicationUnsigned(builder, value is int ? value : 0);
        break;

      case ScheduleValueTag.signed:
        _encodeApplicationSigned(builder, value is int ? value : 0);
        break;

      case ScheduleValueTag.real:
        final doubleVal = value is double ? value : (value is int ? value.toDouble() : 0.0);
        _encodeApplicationReal(builder, doubleVal);
        break;

      case ScheduleValueTag.enumerated:
        final intVal = value is int ? value : (value is bool ? (value ? 1 : 0) : 0);
        _encodeApplicationEnumerated(builder, intVal);
        break;
    }
  }

  /// Encode un BACnetTimeValue (paire time + value)
  static void _encodeTimeValue(BytesBuilder builder, BacnetTimeValue tv) {
    // Time (Application tag 11)
    _encodeApplicationTime(builder, tv.hour, tv.minute, tv.second, tv.hundredths);
    // Value (Any primitive type)
    _encodeScheduleValue(builder, tv.value, tv.valueTag);
  }

  /// Encode un WriteProperty pour le weekly-schedule d'un objet Schedule
  /// [dayIndex]: 1-7 pour un jour spécifique (1=Lundi), null pour tous les jours
  static Uint8List encodeWriteWeeklyScheduleRequest({
    required int invokeId,
    required int scheduleInstance,
    required BacnetWeeklySchedule weeklySchedule,
    int? dayIndex,
  }) {
    final builder = BytesBuilder();

    _encodeConfirmedHeader(builder, invokeId, ConfirmedService.writeProperty);

    // Context tag [0]: Object Identifier (Schedule object)
    _encodeContextObjectId(builder, 0, BacnetObjectTypeCode.schedule, scheduleInstance);

    // Context tag [1]: Property Identifier (weekly-schedule = 123)
    _encodeContextUnsigned(builder, 1, BacnetPropertyId.weeklySchedule);

    // Context tag [2]: Array Index (optionnel - pour écrire un jour spécifique)
    if (dayIndex != null && dayIndex >= 1 && dayIndex <= 7) {
      _encodeContextUnsigned(builder, 2, dayIndex);
    }

    // Context tag [3]: Property Value (opening tag)
    builder.addByte(0x3E);

    // BACnetDailySchedule ::= SEQUENCE { day-schedule [0] SEQUENCE OF BACnetTimeValue }
    // Each element of the array, including a single element written with
    // an array index, is wrapped in context tag [0] (0x0E ... 0x0F).
    final singleDay = dayIndex != null && dayIndex >= 1 && dayIndex <= 7;
    final days = singleDay ? [weeklySchedule.days[dayIndex - 1]] : weeklySchedule.days.take(7);
    for (final dailySchedule in days) {
      builder.addByte(0x0E); // Opening tag context 0
      for (final tv in dailySchedule.timeValues) {
        _encodeTimeValue(builder, tv);
      }
      builder.addByte(0x0F); // Closing tag context 0
    }

    // Context tag [3]: Closing tag
    builder.addByte(0x3F);

    return _assemblePacket(apdu: builder.toBytes(), expectingReply: true);
  }

  /// Encode un WriteProperty pour un jour spécifique du weekly-schedule
  static Uint8List encodeWriteDailyScheduleRequest({
    required int invokeId,
    required int scheduleInstance,
    required int dayIndex, // 1-7 (1=Lundi)
    required BacnetDailySchedule dailySchedule,
  }) {
    final weeklySchedule = BacnetWeeklySchedule.empty();
    // Remplacer le jour concerné
    final days = List<BacnetDailySchedule>.from(weeklySchedule.days);
    days[dayIndex - 1] = dailySchedule;

    return encodeWriteWeeklyScheduleRequest(
      invokeId: invokeId,
      scheduleInstance: scheduleInstance,
      weeklySchedule: BacnetWeeklySchedule(days: days),
      dayIndex: dayIndex,
    );
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

// =========================================================================
// Schedule Encoding Support
// =========================================================================

/// Représente une paire Time-Value BACnet pour les schedules
class BacnetTimeValue {
  /// Heure (heures 0-23)
  final int hour;
  /// Minutes (0-59)
  final int minute;
  /// Secondes (0-59)
  final int second;
  /// Centièmes de seconde (0-99)
  final int hundredths;
  /// Valeur à appliquer (bool, int pour enumerated, double pour real, ou null)
  final dynamic value;
  /// Type de valeur pour forcer l'encodage (optionnel)
  final ScheduleValueTag? valueTag;

  BacnetTimeValue({
    required this.hour,
    required this.minute,
    this.second = 0,
    this.hundredths = 0,
    required this.value,
    this.valueTag,
  });

  /// Crée depuis un time string "HH:mm:ss.cc" ou "HH:mm"
  factory BacnetTimeValue.fromTimeString(String time, dynamic value, {ScheduleValueTag? valueTag}) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    int second = 0;
    int hundredths = 0;
    if (parts.length > 2) {
      final secParts = parts[2].split('.');
      second = int.tryParse(secParts[0]) ?? 0;
      if (secParts.length > 1) {
        hundredths = int.tryParse(secParts[1].padRight(2, '0').substring(0, 2)) ?? 0;
      }
    }
    return BacnetTimeValue(
      hour: hour,
      minute: minute,
      second: second,
      hundredths: hundredths,
      value: value,
      valueTag: valueTag,
    );
  }

  /// Convertit en time string "HH:mm:ss.cc"
  String toTimeString() {
    return '${hour.toString().padLeft(2, '0')}:'
           '${minute.toString().padLeft(2, '0')}:'
           '${second.toString().padLeft(2, '0')}.'
           '${hundredths.toString().padLeft(2, '0')}';
  }
}

/// Tags pour les valeurs de schedule
enum ScheduleValueTag {
  nullValue,    // Tag 0
  boolean,      // Tag 1
  unsigned,     // Tag 2
  signed,       // Tag 3
  real,         // Tag 4
  enumerated,   // Tag 9
}

/// Planning journalier BACnet (liste de TimeValue)
class BacnetDailySchedule {
  final List<BacnetTimeValue> timeValues;

  BacnetDailySchedule({required this.timeValues});

  /// Crée un planning vide
  factory BacnetDailySchedule.empty() => BacnetDailySchedule(timeValues: []);
}

/// Planning hebdomadaire BACnet (7 jours: Lundi à Dimanche)
class BacnetWeeklySchedule {
  /// Liste de 7 DailySchedule (index 0 = Lundi, 6 = Dimanche)
  final List<BacnetDailySchedule> days;

  BacnetWeeklySchedule({required this.days}) : assert(days.length == 7);

  /// Crée un planning vide (7 jours vides)
  factory BacnetWeeklySchedule.empty() => BacnetWeeklySchedule(
    days: List.generate(7, (_) => BacnetDailySchedule.empty()),
  );
}
