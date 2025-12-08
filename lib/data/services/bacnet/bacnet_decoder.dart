import 'dart:typed_data';
import 'bacnet_constants.dart';

/// Décodeur de paquets BACnet/IP
class BacnetDecoder {
  /// Décode un paquet BACnet/IP complet
  static BacnetResponse decode(Uint8List data) {
    if (data.length < 4) {
      return BacnetResponse.error('Packet too short');
    }

    int offset = 0;

    // 1. Décoder BVLC
    final bvlc = _decodeBvlc(data, offset);
    if (bvlc == null) {
      return BacnetResponse.error('Invalid BVLC header');
    }
    offset += 4;

    // Pour Forwarded-NPDU, skip l'adresse source (6 bytes)
    if (bvlc.function == BvlcFunction.forwardedNpdu) {
      offset += 6;
    }

    // 2. Décoder NPDU
    final npdu = _decodeNpdu(data, offset);
    if (npdu == null) {
      return BacnetResponse.error('Invalid NPDU header');
    }
    offset += npdu.headerLength;

    // Si c'est un message réseau, pas d'APDU
    if (npdu.isNetworkLayerMessage) {
      return BacnetResponse.error('Network layer message not supported');
    }

    // 3. Décoder APDU
    return _decodeApdu(data, offset);
  }

  // =========================================================================
  // BVLC Decoding
  // =========================================================================

  static BvlcHeader? _decodeBvlc(Uint8List data, int offset) {
    if (data[offset] != bvlcTypeBacnetIp) {
      return null;
    }

    return BvlcHeader(
      type: data[offset],
      function: data[offset + 1],
      length: (data[offset + 2] << 8) | data[offset + 3],
    );
  }

  // =========================================================================
  // NPDU Decoding
  // =========================================================================

  static NpduHeader? _decodeNpdu(Uint8List data, int offset) {
    if (offset >= data.length) return null;

    final version = data[offset];
    if (version != npduVersion) {
      return null;
    }

    final control = data[offset + 1];
    int headerLength = 2;

    // Skip destination specifier if present
    if ((control & NpduControl.destinationSpecifier) != 0) {
      if (offset + headerLength + 3 > data.length) return null;
      final dlen = data[offset + headerLength + 2];
      headerLength += 3 + dlen + 1; // DNET(2) + DLEN(1) + DADR(dlen) + HopCount(1)
    }

    // Skip source specifier if present
    if ((control & NpduControl.sourceSpecifier) != 0) {
      if (offset + headerLength + 3 > data.length) return null;
      final slen = data[offset + headerLength + 2];
      headerLength += 3 + slen; // SNET(2) + SLEN(1) + SADR(slen)
    }

    return NpduHeader(
      version: version,
      control: control,
      headerLength: headerLength,
      isNetworkLayerMessage: (control & NpduControl.networkLayerMessage) != 0,
    );
  }

  // =========================================================================
  // APDU Decoding
  // =========================================================================

  static BacnetResponse _decodeApdu(Uint8List data, int offset) {
    if (offset >= data.length) {
      return BacnetResponse.error('No APDU data');
    }

    final pduType = data[offset] & 0xF0;

    switch (pduType) {
      case ApduType.complexAck:
        return _decodeComplexAck(data, offset);
      case ApduType.simpleAck:
        return _decodeSimpleAck(data, offset);
      case ApduType.error:
        return _decodeError(data, offset);
      case ApduType.reject:
        return _decodeReject(data, offset);
      case ApduType.abort:
        return _decodeAbort(data, offset);
      case ApduType.unconfirmedRequest:
        return _decodeUnconfirmedRequest(data, offset);
      default:
        return BacnetResponse.error('Unknown PDU type: 0x${pduType.toRadixString(16)}');
    }
  }

  /// Décode un Complex ACK (réponse ReadProperty, etc.)
  static BacnetResponse _decodeComplexAck(Uint8List data, int offset) {
    // Complex ACK header: PDU type, Invoke ID, Service ACK Choice
    final invokeId = data[offset + 1];
    final serviceChoice = data[offset + 2];
    offset += 3;

    switch (serviceChoice) {
      case ConfirmedService.readProperty:
        return _decodeReadPropertyAck(data, offset, invokeId);
      case ConfirmedService.readPropertyMultiple:
        return _decodeReadPropertyMultipleAck(data, offset, invokeId);
      case ConfirmedService.readRange:
        return _decodeReadRangeAck(data, offset, invokeId);
      default:
        return BacnetResponse(
          type: BacnetResponseType.complexAck,
          invokeId: invokeId,
          serviceChoice: serviceChoice,
        );
    }
  }

  /// Décode un ReadProperty ACK
  static BacnetResponse _decodeReadPropertyAck(
    Uint8List data,
    int offset,
    int invokeId,
  ) {
    // Context tag [0]: Object Identifier
    final objectId = _decodeContextObjectId(data, offset, 0);
    if (objectId == null) {
      return BacnetResponse.error('Failed to decode object identifier');
    }
    offset = objectId.nextOffset;

    // Context tag [1]: Property Identifier
    final propertyId = _decodeContextUnsigned(data, offset, 1);
    if (propertyId == null) {
      return BacnetResponse.error('Failed to decode property identifier');
    }
    offset = propertyId.nextOffset;

    // Context tag [2]: Property Array Index (optional)
    int? arrayIndex;
    final maybeArrayIndex = _decodeContextUnsigned(data, offset, 2);
    if (maybeArrayIndex != null) {
      arrayIndex = maybeArrayIndex.value;
      offset = maybeArrayIndex.nextOffset;
    }

    // Context tag [3]: Property Value (opening tag)
    if (offset >= data.length || data[offset] != 0x3E) {
      return BacnetResponse.error('Missing property value opening tag');
    }
    offset++;

    // Check if this is a weekly-schedule (property 123) which has a special structure
    // Weekly-schedule: ARRAY[7] OF BACnetDailySchedule
    // Each BACnetDailySchedule is wrapped in context tag [0]
    dynamic finalValue;
    if (propertyId.value == 123 && offset < data.length && data[offset] == 0x0E) {
      // Parse weekly-schedule specially
      finalValue = _decodeWeeklyScheduleValue(data, offset);
      // Skip to closing tag
      while (offset < data.length && data[offset] != 0x3F) {
        offset++;
      }
    } else {
      // Decode ALL values until closing tag (0x3F)
      // This handles properties like object-list that contain multiple values
      final values = <dynamic>[];
      while (offset < data.length && data[offset] != 0x3F) {
        final valueResult = _decodeApplicationValue(data, offset);
        if (valueResult == null) {
          break;
        }
        values.add(valueResult.value);
        offset = valueResult.nextOffset;
      }

      // Return single value or list depending on count
      if (values.isEmpty) {
        finalValue = null;
      } else if (values.length == 1) {
        finalValue = values.first;
      } else {
        finalValue = values;
      }
    }

    return BacnetResponse(
      type: BacnetResponseType.readPropertyAck,
      invokeId: invokeId,
      objectType: objectId.objectType,
      objectInstance: objectId.objectInstance,
      propertyId: propertyId.value,
      arrayIndex: arrayIndex,
      value: finalValue,
    );
  }

  /// Décode un ReadPropertyMultiple ACK
  static BacnetResponse _decodeReadPropertyMultipleAck(
    Uint8List data,
    int offset,
    int invokeId,
  ) {
    final results = <ReadPropertyMultipleResult>[];

    while (offset < data.length) {
      // Context tag [0]: Object Identifier
      final objectId = _decodeContextObjectId(data, offset, 0);
      if (objectId == null) break;
      offset = objectId.nextOffset;

      // Opening tag [1]: List of results
      if (offset >= data.length || data[offset] != 0x1E) break;
      offset++;

      final objectResults = <PropertyResult>[];

      // Parse property results until closing tag
      while (offset < data.length && data[offset] != 0x1F) {
        // Context tag [2]: Property Identifier
        final propId = _decodeContextUnsigned(data, offset, 2);
        if (propId == null) break;
        offset = propId.nextOffset;

        // Context tag [3]: Property Array Index (optional)
        int? arrayIndex;
        final maybeIndex = _decodeContextUnsigned(data, offset, 3);
        if (maybeIndex != null) {
          arrayIndex = maybeIndex.value;
          offset = maybeIndex.nextOffset;
        }

        // Either [4] propertyValue or [5] propertyAccessError
        if (offset < data.length && data[offset] == 0x4E) {
          // Opening tag [4]: Property Value
          offset++;

          // Décoder TOUTES les valeurs jusqu'au closing tag (0x4F)
          // Ceci gère les propriétés comme state-text qui contiennent plusieurs valeurs
          final values = <dynamic>[];
          bool hasStructuredValue = false;

          while (offset < data.length && data[offset] != 0x4F) {
            final valueResult = _decodeApplicationValue(data, offset);
            if (valueResult != null) {
              values.add(valueResult.value);
              offset = valueResult.nextOffset;
            } else {
              // Si ce n'est pas une valeur simple, c'est probablement une structure construite
              // Décoder comme structure (pour log-device-object-property, etc.)
              final structResult = _decodeConstructedValue(data, offset, 0x4F);
              if (structResult != null) {
                values.add(structResult.value);
                offset = structResult.nextOffset;
                hasStructuredValue = true;
              } else {
                // Ne peut pas décoder, avancer d'un byte pour éviter boucle infinie
                offset++;
              }
            }
          }

          // Déterminer la valeur finale
          dynamic finalValue;
          if (values.isEmpty) {
            finalValue = null;
          } else if (values.length == 1) {
            finalValue = values.first;
          } else {
            finalValue = values;
          }

          if (finalValue != null || hasStructuredValue) {
            objectResults.add(PropertyResult(
              propertyId: propId.value,
              arrayIndex: arrayIndex,
              value: finalValue,
            ));
          }

          if (offset < data.length && data[offset] == 0x4F) {
            offset++; // Skip closing tag
          }
        } else if (offset < data.length && data[offset] == 0x5E) {
          // Opening tag [5]: Property Access Error
          offset++;
          // Skip error details for now
          while (offset < data.length && data[offset] != 0x5F) {
            offset++;
          }
          if (offset < data.length) offset++;
        }
      }

      if (offset < data.length && data[offset] == 0x1F) {
        offset++; // Skip closing tag
      }

      results.add(ReadPropertyMultipleResult(
        objectType: objectId.objectType,
        objectInstance: objectId.objectInstance,
        properties: objectResults,
      ));
    }

    return BacnetResponse(
      type: BacnetResponseType.readPropertyMultipleAck,
      invokeId: invokeId,
      multipleResults: results,
    );
  }

  /// Décode un Simple ACK
  static BacnetResponse _decodeSimpleAck(Uint8List data, int offset) {
    final invokeId = data[offset + 1];
    final serviceChoice = data[offset + 2];

    return BacnetResponse(
      type: BacnetResponseType.simpleAck,
      invokeId: invokeId,
      serviceChoice: serviceChoice,
    );
  }

  /// Décode une erreur BACnet
  static BacnetResponse _decodeError(Uint8List data, int offset) {
    final invokeId = data[offset + 1];
    final serviceChoice = data[offset + 2];
    offset += 3;

    int? errorClass;
    int? errorCode;

    // Error class (enumerated)
    if (offset < data.length) {
      final classResult = _decodeApplicationValue(data, offset);
      if (classResult != null && classResult.value is int) {
        errorClass = classResult.value as int;
        offset = classResult.nextOffset;
      }
    }

    // Error code (enumerated)
    if (offset < data.length) {
      final codeResult = _decodeApplicationValue(data, offset);
      if (codeResult != null && codeResult.value is int) {
        errorCode = codeResult.value as int;
      }
    }

    return BacnetResponse(
      type: BacnetResponseType.error,
      invokeId: invokeId,
      serviceChoice: serviceChoice,
      errorClass: errorClass,
      errorCode: errorCode,
      errorMessage: 'BACnet Error: class=$errorClass, code=$errorCode',
    );
  }

  /// Décode un Reject
  static BacnetResponse _decodeReject(Uint8List data, int offset) {
    final invokeId = data[offset + 1];
    final rejectReason = data[offset + 2];

    return BacnetResponse(
      type: BacnetResponseType.reject,
      invokeId: invokeId,
      errorCode: rejectReason,
      errorMessage: 'BACnet Reject: reason=$rejectReason',
    );
  }

  /// Décode un Abort
  static BacnetResponse _decodeAbort(Uint8List data, int offset) {
    final invokeId = data[offset + 1];
    final abortReason = data[offset + 2];

    return BacnetResponse(
      type: BacnetResponseType.abort,
      invokeId: invokeId,
      errorCode: abortReason,
      errorMessage: 'BACnet Abort: reason=$abortReason',
    );
  }

  /// Décode une Unconfirmed Request (I-Am, etc.)
  static BacnetResponse _decodeUnconfirmedRequest(Uint8List data, int offset) {
    final serviceChoice = data[offset + 1];
    offset += 2;

    if (serviceChoice == UnconfirmedService.iAm) {
      return _decodeIAm(data, offset);
    }

    return BacnetResponse(
      type: BacnetResponseType.unconfirmedRequest,
      serviceChoice: serviceChoice,
    );
  }

  /// Décode un I-Am
  static BacnetResponse _decodeIAm(Uint8List data, int offset) {
    // I-Am Device Identifier
    final objectIdResult = _decodeApplicationObjectId(data, offset);
    if (objectIdResult == null) {
      return BacnetResponse.error('Failed to decode I-Am device identifier');
    }

    return BacnetResponse(
      type: BacnetResponseType.iAm,
      objectType: objectIdResult.objectType,
      objectInstance: objectIdResult.objectInstance,
    );
  }

  /// Décode un ReadRange ACK (pour log-buffer, etc.)
  static BacnetResponse _decodeReadRangeAck(
    Uint8List data,
    int offset,
    int invokeId,
  ) {
    // Context tag [0]: Object Identifier
    final objectId = _decodeContextObjectId(data, offset, 0);
    if (objectId == null) {
      return BacnetResponse.error('Failed to decode object identifier in ReadRange ACK');
    }
    offset = objectId.nextOffset;

    // Context tag [1]: Property Identifier
    final propertyId = _decodeContextUnsigned(data, offset, 1);
    if (propertyId == null) {
      return BacnetResponse.error('Failed to decode property identifier');
    }
    offset = propertyId.nextOffset;

    // Context tag [2]: Property Array Index (optional)
    int? arrayIndex;
    final maybeArrayIndex = _decodeContextUnsigned(data, offset, 2);
    if (maybeArrayIndex != null) {
      arrayIndex = maybeArrayIndex.value;
      offset = maybeArrayIndex.nextOffset;
    }

    // Context tag [3]: Result Flags (BACnetResultFlags)
    int resultFlags = 0;
    if (offset < data.length && (data[offset] & 0xF0) == 0x30) {
      // Context 3 - result flags (bit string)
      final len = data[offset] & 0x07;
      offset++;
      if (len > 0 && offset + len <= data.length) {
        // Skip unused bits count and read flags
        if (len >= 2) {
          resultFlags = data[offset + 1];
        }
        offset += len;
      }
    }

    // Context tag [4]: Item Count
    int? itemCount;
    final maybeItemCount = _decodeContextUnsigned(data, offset, 4);
    if (maybeItemCount != null) {
      itemCount = maybeItemCount.value;
      offset = maybeItemCount.nextOffset;
    }

    // Context tag [5]: Item Data (opening tag 0x5E)
    final records = <TrendLogRecordData>[];
    if (offset < data.length && data[offset] == 0x5E) {
      offset++; // Skip opening tag

      // Parse each log record
      while (offset < data.length && data[offset] != 0x5F) {
        final record = _decodeLogRecord(data, offset);
        if (record != null) {
          records.add(record.record);
          offset = record.nextOffset;
        } else {
          // Skip unknown byte and continue
          offset++;
        }
      }

      if (offset < data.length && data[offset] == 0x5F) {
        offset++; // Skip closing tag
      }
    }

    // Context tag [6]: First Sequence Number (optional)
    int? firstSequenceNumber;
    final maybeFirstSeq = _decodeContextUnsigned(data, offset, 6);
    if (maybeFirstSeq != null) {
      firstSequenceNumber = maybeFirstSeq.value;
      offset = maybeFirstSeq.nextOffset;
    }

    return BacnetResponse(
      type: BacnetResponseType.readRangeAck,
      invokeId: invokeId,
      objectType: objectId.objectType,
      objectInstance: objectId.objectInstance,
      propertyId: propertyId.value,
      arrayIndex: arrayIndex,
      value: ReadRangeResult(
        itemCount: itemCount ?? records.length,
        firstSequenceNumber: firstSequenceNumber,
        moreItems: (resultFlags & 0x01) != 0,
        records: records,
      ),
    );
  }

  /// Décode un enregistrement de log (BACnetLogRecord)
  static _LogRecordResult? _decodeLogRecord(Uint8List data, int offset) {
    // Un BACnetLogRecord est une séquence avec:
    // [0] timestamp (BACnetDateTime)
    // [1] logDatum (CHOICE)
    // [2] statusFlags (optional)

    DateTime? timestamp;
    dynamic logValue;
    int? statusFlags;

    // Chercher le timestamp (context tag 0)
    if (offset < data.length && (data[offset] & 0xF8) == 0x08) {
      // Context 0 opening tag
      if (data[offset] == 0x0E) {
        offset++; // Skip opening tag

        // Decode BACnetDateTime (Date + Time)
        final dateResult = _decodeApplicationDate(data, offset);
        if (dateResult != null) {
          offset = dateResult.nextOffset;
          final timeResult = _decodeApplicationTime(data, offset);
          if (timeResult != null) {
            offset = timeResult.nextOffset;
            timestamp = DateTime(
              dateResult.year,
              dateResult.month,
              dateResult.day,
              timeResult.hour,
              timeResult.minute,
              timeResult.second,
              timeResult.hundredths * 10,
            );
          }
        }

        // Skip to closing tag
        while (offset < data.length && data[offset] != 0x0F) {
          offset++;
        }
        if (offset < data.length) offset++; // Skip closing tag
      }
    }

    // Chercher logDatum (context tag 1)
    // logDatum est un CHOICE avec des context tags internes:
    // [0] log-status, [1] boolean, [2] real, [3] enum, [4] unsigned, [5] signed, etc.
    if (offset < data.length && data[offset] == 0x1E) {
      offset++; // Skip opening tag

      // Parse the CHOICE - le premier octet indique le type de valeur
      if (offset < data.length) {
        final tagByte = data[offset];
        // Context tag: bit 3 = 1 (class = context)
        // Format: [tag number (4 bits)] [class (1 bit)] [P/C (1 bit)] [length/type (2 bits)]
        // Pour context primitive: tag << 4 | 0x08 | length (si length < 5)
        final isContext = (tagByte & 0x08) != 0;

        if (isContext) {
          final tagNumber = tagByte >> 4;
          final lenOrType = tagByte & 0x07;

          // Déterminer la longueur
          int len;
          int dataStart;
          if (lenOrType == 5) {
            // Extended length
            if (offset + 1 < data.length) {
              len = data[offset + 1];
              dataStart = offset + 2;
            } else {
              len = 0;
              dataStart = offset + 1;
            }
          } else {
            len = lenOrType;
            dataStart = offset + 1;
          }

          // Décoder selon le type (tagNumber dans le CHOICE)
          switch (tagNumber) {
            case 0: // log-status (BIT STRING)
              // Skip for now
              offset = dataStart + len;
              break;
            case 1: // boolean-value
              if (len == 1 && dataStart < data.length) {
                logValue = data[dataStart] != 0;
              }
              offset = dataStart + len;
              break;
            case 2: // real-value (IEEE 754 float)
              if (len == 4 && dataStart + 4 <= data.length) {
                final bytes = ByteData.sublistView(
                  Uint8List.fromList(data.sublist(dataStart, dataStart + 4)));
                logValue = bytes.getFloat32(0, Endian.big);
              }
              offset = dataStart + len;
              break;
            case 3: // enumerated-value
              if (dataStart + len <= data.length) {
                int enumVal = 0;
                for (int i = 0; i < len; i++) {
                  enumVal = (enumVal << 8) | data[dataStart + i];
                }
                logValue = enumVal;
              }
              offset = dataStart + len;
              break;
            case 4: // unsigned-value
              if (dataStart + len <= data.length) {
                int unsignedVal = 0;
                for (int i = 0; i < len; i++) {
                  unsignedVal = (unsignedVal << 8) | data[dataStart + i];
                }
                logValue = unsignedVal;
              }
              offset = dataStart + len;
              break;
            case 5: // signed-value (INTEGER)
              if (dataStart + len <= data.length) {
                int signedVal = 0;
                for (int i = 0; i < len; i++) {
                  signedVal = (signedVal << 8) | data[dataStart + i];
                }
                // Handle sign extension
                if (len > 0 && (data[dataStart] & 0x80) != 0) {
                  signedVal = signedVal - (1 << (len * 8));
                }
                logValue = signedVal;
              }
              offset = dataStart + len;
              break;
            case 7: // null-value
              logValue = null;
              offset = dataStart + len;
              break;
            case 9: // time-change (REAL)
              if (len == 4 && dataStart + 4 <= data.length) {
                final bytes = ByteData.sublistView(
                  Uint8List.fromList(data.sublist(dataStart, dataStart + 4)));
                logValue = bytes.getFloat32(0, Endian.big);
              }
              offset = dataStart + len;
              break;
            default:
              // Unknown type, skip
              offset = dataStart + len;
          }
        }
      }

      // Skip to closing tag 0x1F
      while (offset < data.length && data[offset] != 0x1F) {
        offset++;
      }
      if (offset < data.length) offset++; // Skip closing tag
    }

    // Chercher statusFlags (context tag 2, optional)
    if (offset < data.length && (data[offset] & 0xF8) == 0x28) {
      final len = data[offset] & 0x07;
      offset++;
      if (len > 0 && offset + len <= data.length) {
        if (len >= 2) {
          statusFlags = data[offset + 1];
        }
        offset += len;
      }
    }

    if (timestamp == null && logValue == null) {
      return null;
    }

    return _LogRecordResult(
      record: TrendLogRecordData(
        timestamp: timestamp ?? DateTime.now(),
        value: logValue,
        statusFlags: statusFlags,
      ),
      nextOffset: offset,
    );
  }

  /// Décode une date BACnet (Application tag 10)
  static _DateResult? _decodeApplicationDate(Uint8List data, int offset) {
    if (offset >= data.length) return null;

    final tagByte = data[offset];
    if ((tagByte >> 4) != ApplicationTag.date) return null;

    offset++;
    if (offset + 4 > data.length) return null;

    return _DateResult(
      year: data[offset] + 1900,
      month: data[offset + 1],
      day: data[offset + 2],
      weekday: data[offset + 3],
      nextOffset: offset + 4,
    );
  }

  /// Décode une heure BACnet (Application tag 11)
  static _TimeResult? _decodeApplicationTime(Uint8List data, int offset) {
    if (offset >= data.length) return null;

    final tagByte = data[offset];
    if ((tagByte >> 4) != ApplicationTag.time) return null;

    offset++;
    if (offset + 4 > data.length) return null;

    return _TimeResult(
      hour: data[offset],
      minute: data[offset + 1],
      second: data[offset + 2],
      hundredths: data[offset + 3],
      nextOffset: offset + 4,
    );
  }

  // =========================================================================
  // Context Tag Decoding
  // =========================================================================

  /// Décode un Object Identifier avec context tag
  static ObjectIdResult? _decodeContextObjectId(
    Uint8List data,
    int offset,
    int expectedTag,
  ) {
    if (offset >= data.length) return null;

    final tagByte = data[offset];
    final tagNumber = (tagByte >> 4) & 0x0F;
    final lengthOrType = tagByte & 0x0F;

    // Vérifier que c'est le bon tag et que c'est un context tag
    if (tagNumber != expectedTag) return null;
    if ((tagByte & 0x08) == 0) return null; // Doit être context tag

    // Length should be 4 for object identifier
    final length = lengthOrType & 0x07;
    if (length != 4) return null;

    offset++;

    // Decode object identifier
    final objectId = (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];

    final objectType = (objectId >> 22) & 0x3FF;
    final objectInstance = objectId & 0x3FFFFF;

    return ObjectIdResult(
      objectType: objectType,
      objectInstance: objectInstance,
      nextOffset: offset + 4,
    );
  }

  /// Décode un unsigned integer avec context tag
  static UnsignedResult? _decodeContextUnsigned(
    Uint8List data,
    int offset,
    int expectedTag,
  ) {
    if (offset >= data.length) return null;

    final tagByte = data[offset];
    final tagNumber = (tagByte >> 4) & 0x0F;

    if (tagNumber != expectedTag) return null;
    if ((tagByte & 0x08) == 0) return null; // Doit être context tag

    final length = tagByte & 0x07;
    offset++;

    if (offset + length > data.length) return null;

    int value = 0;
    for (int i = 0; i < length; i++) {
      value = (value << 8) | data[offset + i];
    }

    return UnsignedResult(value: value, nextOffset: offset + length);
  }

  // =========================================================================
  // Application Tag Decoding
  // =========================================================================

  /// Décode une valeur avec application tag
  static ValueResult? _decodeApplicationValue(Uint8List data, int offset) {
    if (offset >= data.length) return null;

    final tagByte = data[offset];

    // Check for context closing tag
    if ((tagByte & 0x0F) == 0x0F) {
      return null; // Closing tag, no value
    }

    final tagNumber = (tagByte >> 4) & 0x0F;
    final isContextTag = (tagByte & 0x08) != 0;

    if (isContextTag) {
      // Context tag - skip for now or handle specially
      return null;
    }

    int length = tagByte & 0x07;
    offset++;

    // Extended length
    if (length == 5) {
      if (offset >= data.length) return null;
      length = data[offset];
      offset++;
      if (length == 254) {
        if (offset + 2 > data.length) return null;
        length = (data[offset] << 8) | data[offset + 1];
        offset += 2;
      } else if (length == 255) {
        if (offset + 4 > data.length) return null;
        length = (data[offset] << 24) |
            (data[offset + 1] << 16) |
            (data[offset + 2] << 8) |
            data[offset + 3];
        offset += 4;
      }
    }

    dynamic value;

    switch (tagNumber) {
      case ApplicationTag.nullValue:
        value = null;
        break;

      case ApplicationTag.boolean:
        value = (tagByte & 0x01) == 1;
        length = 0; // Boolean value is in the tag byte
        break;

      case ApplicationTag.unsignedInt:
        value = _decodeUnsigned(data, offset, length);
        break;

      case ApplicationTag.signedInt:
        value = _decodeSigned(data, offset, length);
        break;

      case ApplicationTag.real:
        if (length == 4 && offset + 4 <= data.length) {
          final bytes = ByteData.sublistView(data, offset, offset + 4);
          value = bytes.getFloat32(0, Endian.big);
        }
        break;

      case ApplicationTag.double_:
        if (length == 8 && offset + 8 <= data.length) {
          final bytes = ByteData.sublistView(data, offset, offset + 8);
          value = bytes.getFloat64(0, Endian.big);
        }
        break;

      case ApplicationTag.characterString:
        if (length > 0 && offset + length <= data.length) {
          // First byte is encoding (0 = UTF-8)
          final encoding = data[offset];
          if (encoding == 0) {
            value = String.fromCharCodes(data.sublist(offset + 1, offset + length));
          } else {
            value = String.fromCharCodes(data.sublist(offset + 1, offset + length));
          }
        }
        break;

      case ApplicationTag.enumerated:
        value = _decodeUnsigned(data, offset, length);
        break;

      case ApplicationTag.bitString:
        // BACnet BitString: premier octet = nombre de bits inutilisés dans le dernier octet
        // Octets suivants = les bits (MSB first)
        if (length > 0 && offset + length <= data.length) {
          final unusedBits = data[offset];
          final bitBytes = data.sublist(offset + 1, offset + length);

          // Convertir en liste de booléens
          final bits = <bool>[];
          for (int i = 0; i < bitBytes.length; i++) {
            final byte = bitBytes[i];
            // Nombre de bits à lire dans cet octet
            int bitsToRead = 8;
            if (i == bitBytes.length - 1) {
              bitsToRead = 8 - unusedBits;
            }
            // Lire les bits du MSB au LSB
            for (int j = 7; j >= 8 - bitsToRead; j--) {
              bits.add((byte & (1 << j)) != 0);
            }
          }
          value = bits;
        }
        break;

      case ApplicationTag.objectIdentifier:
        if (length == 4 && offset + 4 <= data.length) {
          final objectId = (data[offset] << 24) |
              (data[offset + 1] << 16) |
              (data[offset + 2] << 8) |
              data[offset + 3];
          final objType = (objectId >> 22) & 0x3FF;
          final objInstance = objectId & 0x3FFFFF;
          value = {'type': objType, 'instance': objInstance};
        }
        break;

      default:
        // Unknown tag, skip
        break;
    }

    return ValueResult(value: value, nextOffset: offset + length);
  }

  /// Décode un Object Identifier avec application tag
  static ObjectIdResult? _decodeApplicationObjectId(Uint8List data, int offset) {
    if (offset >= data.length) return null;

    final tagByte = data[offset];
    final tagNumber = (tagByte >> 4) & 0x0F;

    if (tagNumber != ApplicationTag.objectIdentifier) return null;

    offset++;

    if (offset + 4 > data.length) return null;

    final objectId = (data[offset] << 24) |
        (data[offset + 1] << 16) |
        (data[offset + 2] << 8) |
        data[offset + 3];

    return ObjectIdResult(
      objectType: (objectId >> 22) & 0x3FF,
      objectInstance: objectId & 0x3FFFFF,
      nextOffset: offset + 4,
    );
  }

  /// Décode un unsigned integer
  static int _decodeUnsigned(Uint8List data, int offset, int length) {
    int value = 0;
    for (int i = 0; i < length && offset + i < data.length; i++) {
      value = (value << 8) | data[offset + i];
    }
    return value;
  }

  /// Décode un signed integer
  static int _decodeSigned(Uint8List data, int offset, int length) {
    if (length == 0 || offset + length > data.length) return 0;

    int value = 0;
    bool negative = (data[offset] & 0x80) != 0;

    for (int i = 0; i < length; i++) {
      value = (value << 8) | data[offset + i];
    }

    if (negative) {
      // Sign extend
      value = value - (1 << (length * 8));
    }

    return value;
  }

  /// Décode une valeur construite (structure avec context tags)
  /// Utilisé pour les types comme BACnetDeviceObjectPropertyReference
  static ValueResult? _decodeConstructedValue(Uint8List data, int offset, int closingTag) {
    final result = <String, dynamic>{};

    while (offset < data.length && data[offset] != closingTag) {
      final tagByte = data[offset];

      // Vérifier si c'est un context tag
      final isContextTag = (tagByte & 0x08) != 0;
      if (!isContextTag) {
        // Essayer de décoder comme valeur application
        final appValue = _decodeApplicationValue(data, offset);
        if (appValue != null) {
          offset = appValue.nextOffset;
          // Ajouter sans clé spécifique
          result['value'] = appValue.value;
        } else {
          offset++;
        }
        continue;
      }

      final tagNumber = (tagByte >> 4) & 0x0F;
      final lengthOrType = tagByte & 0x07;

      // Vérifier si c'est un opening tag (0xXE)
      if ((tagByte & 0x0F) == 0x0E) {
        // Opening tag pour une structure imbriquée
        offset++;
        final closingTagForNested = (tagNumber << 4) | 0x0F;
        final nestedResult = _decodeConstructedValue(data, offset, closingTagForNested);
        if (nestedResult != null) {
          result['context$tagNumber'] = nestedResult.value;
          offset = nestedResult.nextOffset;
        }
        // Skip closing tag
        if (offset < data.length && data[offset] == closingTagForNested) {
          offset++;
        }
        continue;
      }

      // Vérifier si c'est un closing tag (0xXF)
      if ((tagByte & 0x0F) == 0x0F) {
        break;
      }

      // Context tag avec valeur directe
      int length = lengthOrType;
      offset++;

      // Extended length
      if (length == 5) {
        if (offset >= data.length) break;
        length = data[offset];
        offset++;
      }

      if (offset + length > data.length) break;

      // Décoder selon le numéro de context tag
      dynamic value;

      if (length == 4) {
        // Probablement un Object Identifier
        final objectId = (data[offset] << 24) |
            (data[offset + 1] << 16) |
            (data[offset + 2] << 8) |
            data[offset + 3];
        final objType = (objectId >> 22) & 0x3FF;
        final objInstance = objectId & 0x3FFFFF;
        value = {'type': objType, 'instance': objInstance};
      } else if (length <= 4) {
        // Probablement un unsigned int
        value = _decodeUnsigned(data, offset, length);
      } else {
        // Données brutes
        value = data.sublist(offset, offset + length);
      }

      // Nommer le champ selon le context tag
      // Pour BACnetDeviceObjectPropertyReference:
      // [0] = objectIdentifier
      // [1] = propertyIdentifier
      // [2] = propertyArrayIndex (optional)
      // [3] = deviceIdentifier (optional)
      switch (tagNumber) {
        case 0:
          result['objectIdentifier'] = value;
          break;
        case 1:
          result['propertyIdentifier'] = value;
          break;
        case 2:
          result['propertyArrayIndex'] = value;
          break;
        case 3:
          result['deviceIdentifier'] = value;
          break;
        default:
          result['context$tagNumber'] = value;
      }

      offset += length;
    }

    if (result.isEmpty) {
      return null;
    }

    return ValueResult(value: result, nextOffset: offset);
  }

  // =========================================================================
  // Schedule Decoding Support - Internal Methods
  // =========================================================================

  /// Décode un weekly-schedule depuis les bytes bruts BACnet
  /// Format: ARRAY[7] OF BACnetDailySchedule
  /// Chaque DailySchedule est encapsulé dans context tag [0]
  static DecodedWeeklySchedule _decodeWeeklyScheduleValue(Uint8List data, int offset) {
    final days = <DecodedDailySchedule>[];
    final endOffset = data.length;

    // Parse jusqu'à 7 jours
    while (offset < endOffset && days.length < 7) {
      // Chercher opening tag context 0 (0x0E)
      if (data[offset] == 0x0E) {
        offset++; // Skip opening tag

        final timeValues = <DecodedTimeValue>[];

        // Parser les TimeValues jusqu'au closing tag (0x0F)
        while (offset < endOffset && data[offset] != 0x0F) {
          // Vérifier si c'est un time tag (Application tag 11 = 0xB4)
          if ((data[offset] & 0xF0) == 0xB0) {
            final tvResult = _decodeTimeValueFromBytesInternal(data, offset);
            if (tvResult != null) {
              timeValues.add(tvResult.timeValue);
              offset = tvResult.nextOffset;
            } else {
              offset++; // Skip byte inconnu
            }
          } else {
            offset++; // Skip byte inconnu
          }
        }

        // Skip closing tag
        if (offset < endOffset && data[offset] == 0x0F) {
          offset++;
        }

        days.add(DecodedDailySchedule(timeValues: timeValues));
      } else if (data[offset] == 0x3F) {
        // Closing tag du property value - fin
        break;
      } else {
        offset++; // Skip byte inconnu
      }
    }

    // Remplir les jours manquants
    while (days.length < 7) {
      days.add(DecodedDailySchedule(timeValues: []));
    }

    return DecodedWeeklySchedule(days: days);
  }

  /// Décode un TimeValue depuis des bytes bruts (méthode interne)
  static ({DecodedTimeValue timeValue, int nextOffset})? _decodeTimeValueFromBytesInternal(
    Uint8List data,
    int offset,
  ) {
    if (offset >= data.length) return null;

    // Time: Application tag 11 (0xB4 = tag 11, length 4)
    final timeTag = data[offset];
    if ((timeTag & 0xF0) != 0xB0) return null; // Not a time tag

    offset++;
    if (offset + 4 > data.length) return null;

    final hour = data[offset];
    final minute = data[offset + 1];
    final second = data[offset + 2];
    final hundredths = data[offset + 3];
    offset += 4;

    // Value: Any application tag
    if (offset >= data.length) return null;

    final valueTag = data[offset];
    final tagNumber = (valueTag >> 4) & 0x0F;
    dynamic value;

    switch (tagNumber) {
      case 0: // Null
        value = null;
        offset++;
        break;

      case 1: // Boolean
        value = (valueTag & 0x01) == 1;
        offset++;
        break;

      case 2: // Unsigned
      case 9: // Enumerated
        final length = valueTag & 0x07;
        offset++;
        if (offset + length <= data.length) {
          int intVal = 0;
          for (int i = 0; i < length; i++) {
            intVal = (intVal << 8) | data[offset + i];
          }
          value = intVal;
          offset += length;
        }
        break;

      case 3: // Signed
        final length = valueTag & 0x07;
        offset++;
        if (offset + length <= data.length) {
          int intVal = 0;
          bool negative = (data[offset] & 0x80) != 0;
          for (int i = 0; i < length; i++) {
            intVal = (intVal << 8) | data[offset + i];
          }
          if (negative) {
            intVal = intVal - (1 << (length * 8));
          }
          value = intVal;
          offset += length;
        }
        break;

      case 4: // Real (float32)
        offset++;
        if (offset + 4 <= data.length) {
          final bytes = ByteData.sublistView(data, offset, offset + 4);
          value = bytes.getFloat32(0, Endian.big);
          offset += 4;
        }
        break;

      default:
        // Unknown tag, skip based on length
        final length = valueTag & 0x07;
        offset += 1 + length;
    }

    return (
      timeValue: DecodedTimeValue(
        hour: hour,
        minute: minute,
        second: second,
        hundredths: hundredths,
        value: value,
        valueTag: tagNumber,
      ),
      nextOffset: offset,
    );
  }
}

// =========================================================================
// Result Classes
// =========================================================================

/// Header BVLC décodé
class BvlcHeader {
  final int type;
  final int function;
  final int length;

  BvlcHeader({
    required this.type,
    required this.function,
    required this.length,
  });
}

/// Header NPDU décodé
class NpduHeader {
  final int version;
  final int control;
  final int headerLength;
  final bool isNetworkLayerMessage;

  NpduHeader({
    required this.version,
    required this.control,
    required this.headerLength,
    required this.isNetworkLayerMessage,
  });
}

/// Types de réponse BACnet
enum BacnetResponseType {
  readPropertyAck,
  readPropertyMultipleAck,
  readRangeAck,
  simpleAck,
  complexAck,
  error,
  reject,
  abort,
  iAm,
  unconfirmedRequest,
  parseError,
}

/// Réponse BACnet décodée
class BacnetResponse {
  final BacnetResponseType type;
  final int? invokeId;
  final int? serviceChoice;
  final int? objectType;
  final int? objectInstance;
  final int? propertyId;
  final int? arrayIndex;
  final dynamic value;
  final int? errorClass;
  final int? errorCode;
  final String? errorMessage;
  final List<ReadPropertyMultipleResult>? multipleResults;

  BacnetResponse({
    required this.type,
    this.invokeId,
    this.serviceChoice,
    this.objectType,
    this.objectInstance,
    this.propertyId,
    this.arrayIndex,
    this.value,
    this.errorClass,
    this.errorCode,
    this.errorMessage,
    this.multipleResults,
  });

  factory BacnetResponse.error(String message) {
    return BacnetResponse(
      type: BacnetResponseType.parseError,
      errorMessage: message,
    );
  }

  bool get isSuccess =>
      type == BacnetResponseType.readPropertyAck ||
      type == BacnetResponseType.readPropertyMultipleAck ||
      type == BacnetResponseType.readRangeAck ||
      type == BacnetResponseType.simpleAck ||
      type == BacnetResponseType.complexAck ||
      type == BacnetResponseType.iAm;

  bool get isError =>
      type == BacnetResponseType.error ||
      type == BacnetResponseType.reject ||
      type == BacnetResponseType.abort ||
      type == BacnetResponseType.parseError;
}

/// Résultat du décodage d'un Object Identifier
class ObjectIdResult {
  final int objectType;
  final int objectInstance;
  final int nextOffset;

  ObjectIdResult({
    required this.objectType,
    required this.objectInstance,
    required this.nextOffset,
  });
}

/// Résultat du décodage d'un unsigned
class UnsignedResult {
  final int value;
  final int nextOffset;

  UnsignedResult({required this.value, required this.nextOffset});
}

/// Résultat du décodage d'une valeur
class ValueResult {
  final dynamic value;
  final int nextOffset;

  ValueResult({required this.value, required this.nextOffset});
}

/// Résultat d'une propriété dans ReadPropertyMultiple
class PropertyResult {
  final int propertyId;
  final int? arrayIndex;
  final dynamic value;
  final String? error;

  PropertyResult({
    required this.propertyId,
    this.arrayIndex,
    this.value,
    this.error,
  });
}

/// Résultat d'un objet dans ReadPropertyMultiple
class ReadPropertyMultipleResult {
  final int objectType;
  final int objectInstance;
  final List<PropertyResult> properties;

  ReadPropertyMultipleResult({
    required this.objectType,
    required this.objectInstance,
    required this.properties,
  });
}

/// Résultat d'un ReadRange
class ReadRangeResult {
  final int itemCount;
  final int? firstSequenceNumber;
  final bool moreItems;
  final List<TrendLogRecordData> records;

  ReadRangeResult({
    required this.itemCount,
    this.firstSequenceNumber,
    this.moreItems = false,
    required this.records,
  });
}

/// Données d'un enregistrement de trend log
class TrendLogRecordData {
  final DateTime timestamp;
  final dynamic value;
  final int? statusFlags;

  TrendLogRecordData({
    required this.timestamp,
    this.value,
    this.statusFlags,
  });
}

/// Résultat interne pour le parsing de log record
class _LogRecordResult {
  final TrendLogRecordData record;
  final int nextOffset;

  _LogRecordResult({required this.record, required this.nextOffset});
}

/// Résultat interne pour le parsing de date
class _DateResult {
  final int year;
  final int month;
  final int day;
  final int weekday;
  final int nextOffset;

  _DateResult({
    required this.year,
    required this.month,
    required this.day,
    required this.weekday,
    required this.nextOffset,
  });
}

/// Résultat interne pour le parsing de time
class _TimeResult {
  final int hour;
  final int minute;
  final int second;
  final int hundredths;
  final int nextOffset;

  _TimeResult({
    required this.hour,
    required this.minute,
    required this.second,
    required this.hundredths,
    required this.nextOffset,
  });
}

// =========================================================================
// Schedule Decoding Support - Public Classes
// =========================================================================

/// Résultat du décodage d'un BACnetTimeValue
class DecodedTimeValue {
  final int hour;
  final int minute;
  final int second;
  final int hundredths;
  final dynamic value;
  final int valueTag; // Application tag utilisé pour la valeur

  DecodedTimeValue({
    required this.hour,
    required this.minute,
    required this.second,
    required this.hundredths,
    required this.value,
    required this.valueTag,
  });

  /// Convertit en time string "HH:mm:ss.cc"
  String get timeString =>
      '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}:'
      '${second.toString().padLeft(2, '0')}.'
      '${hundredths.toString().padLeft(2, '0')}';
}

/// Résultat du décodage d'un DailySchedule
class DecodedDailySchedule {
  final List<DecodedTimeValue> timeValues;

  DecodedDailySchedule({required this.timeValues});

  factory DecodedDailySchedule.empty() => DecodedDailySchedule(timeValues: []);
}

/// Résultat du décodage d'un WeeklySchedule complet
class DecodedWeeklySchedule {
  /// 7 jours (index 0 = Lundi, 6 = Dimanche)
  final List<DecodedDailySchedule> days;

  DecodedWeeklySchedule({required this.days}) : assert(days.length == 7);

  factory DecodedWeeklySchedule.empty() => DecodedWeeklySchedule(
    days: List.generate(7, (_) => DecodedDailySchedule.empty()),
  );
}

/// Extension du décodeur pour les schedules
class BacnetScheduleDecoder {
  /// Décode un WeeklySchedule depuis les données brutes
  /// [data]: Les bytes de la propriété weekly-schedule (après le property value tag)
  static DecodedWeeklySchedule decodeWeeklySchedule(dynamic rawValue) {
    // Si c'est une liste (7 éléments pour 7 jours)
    if (rawValue is List) {
      final days = <DecodedDailySchedule>[];

      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        if (dayIndex < rawValue.length) {
          final dayData = rawValue[dayIndex];
          days.add(_decodeDailyScheduleFromData(dayData));
        } else {
          days.add(DecodedDailySchedule.empty());
        }
      }

      return DecodedWeeklySchedule(days: days);
    }

    // Si c'est un Map (format alternatif)
    if (rawValue is Map) {
      final days = <DecodedDailySchedule>[];

      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final dayKey = dayIndex.toString();
        final dayData = rawValue[dayKey] ?? rawValue['day$dayIndex'];
        if (dayData != null) {
          days.add(_decodeDailyScheduleFromData(dayData));
        } else {
          days.add(DecodedDailySchedule.empty());
        }
      }

      return DecodedWeeklySchedule(days: days);
    }

    // Format inconnu, retourner vide
    return DecodedWeeklySchedule.empty();
  }

  /// Décode un DailySchedule depuis les données brutes
  static DecodedDailySchedule _decodeDailyScheduleFromData(dynamic dayData) {
    if (dayData == null) {
      return DecodedDailySchedule.empty();
    }

    final timeValues = <DecodedTimeValue>[];

    // Si c'est une liste de TimeValues
    if (dayData is List) {
      for (final tvData in dayData) {
        final tv = _decodeTimeValueFromData(tvData);
        if (tv != null) {
          timeValues.add(tv);
        }
      }
    }
    // Si c'est un Map avec timeValues
    else if (dayData is Map) {
      final tvList = dayData['timeValues'] ?? dayData['time-values'] ?? dayData;
      if (tvList is List) {
        for (final tvData in tvList) {
          final tv = _decodeTimeValueFromData(tvData);
          if (tv != null) {
            timeValues.add(tv);
          }
        }
      }
    }

    return DecodedDailySchedule(timeValues: timeValues);
  }

  /// Décode un TimeValue depuis les données brutes
  static DecodedTimeValue? _decodeTimeValueFromData(dynamic tvData) {
    if (tvData == null) return null;

    if (tvData is Map) {
      // Format: {time: "HH:mm:ss.cc", value: ..., type: ...}
      final timeStr = tvData['time']?.toString() ?? '00:00:00.00';
      final value = tvData['value'];
      final typeStr = tvData['type']?.toString();

      // Parser le time string
      final timeParts = timeStr.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 0;
      final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
      int second = 0;
      int hundredths = 0;
      if (timeParts.length > 2) {
        final secParts = timeParts[2].split('.');
        second = int.tryParse(secParts[0]) ?? 0;
        if (secParts.length > 1) {
          hundredths = int.tryParse(secParts[1].padRight(2, '0').substring(0, 2)) ?? 0;
        }
      }

      // Déterminer le tag de valeur
      int valueTag = 0; // null par défaut
      if (value == null || typeStr == 'null') {
        valueTag = 0;
      } else if (value is bool || typeStr == 'boolean') {
        valueTag = 1;
      } else if (value is int) {
        valueTag = typeStr == 'unsigned' ? 2 : 9; // enumerated par défaut
      } else if (value is double || typeStr == 'real') {
        valueTag = 4;
      }

      return DecodedTimeValue(
        hour: hour,
        minute: minute,
        second: second,
        hundredths: hundredths,
        value: value,
        valueTag: valueTag,
      );
    }

    return null;
  }

  /// Décode un WeeklySchedule depuis des bytes bruts BACnet
  /// Utilisé quand on lit directement via ReadProperty
  static DecodedWeeklySchedule decodeWeeklyScheduleFromBytes(Uint8List data, int offset) {
    final days = <DecodedDailySchedule>[];

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final result = _decodeDailyScheduleFromBytes(data, offset);
      days.add(result.dailySchedule);
      offset = result.nextOffset;

      // S'arrêter si on a atteint la fin des données
      if (offset >= data.length) {
        // Remplir les jours restants avec des schedules vides
        while (days.length < 7) {
          days.add(DecodedDailySchedule.empty());
        }
        break;
      }
    }

    return DecodedWeeklySchedule(days: days);
  }

  /// Décode un DailySchedule depuis des bytes bruts
  static ({DecodedDailySchedule dailySchedule, int nextOffset}) _decodeDailyScheduleFromBytes(
    Uint8List data,
    int offset,
  ) {
    final timeValues = <DecodedTimeValue>[];

    // Chercher le tag d'ouverture (0x0E pour context 0)
    if (offset < data.length && data[offset] == 0x0E) {
      offset++; // Skip opening tag

      // Lire les TimeValues jusqu'au tag de fermeture (0x0F)
      while (offset < data.length && data[offset] != 0x0F) {
        final result = _decodeTimeValueFromBytes(data, offset);
        if (result != null) {
          timeValues.add(result.timeValue);
          offset = result.nextOffset;
        } else {
          offset++; // Skip unknown byte
        }
      }

      // Skip closing tag
      if (offset < data.length && data[offset] == 0x0F) {
        offset++;
      }
    }
    // Sinon, essayer de lire directement des TimeValues (format sans tags)
    else {
      // Lire tant qu'on trouve des Application Time tags (0xB4)
      while (offset < data.length && (data[offset] & 0xF0) == 0xB0) {
        final result = _decodeTimeValueFromBytes(data, offset);
        if (result != null) {
          timeValues.add(result.timeValue);
          offset = result.nextOffset;
        } else {
          break;
        }
      }
    }

    return (dailySchedule: DecodedDailySchedule(timeValues: timeValues), nextOffset: offset);
  }

  /// Décode un TimeValue depuis des bytes bruts
  static ({DecodedTimeValue timeValue, int nextOffset})? _decodeTimeValueFromBytes(
    Uint8List data,
    int offset,
  ) {
    if (offset >= data.length) return null;

    // Time: Application tag 11 (0xB4 = tag 11, length 4)
    final timeTag = data[offset];
    if ((timeTag & 0xF0) != 0xB0) return null; // Not a time tag

    offset++;
    if (offset + 4 > data.length) return null;

    final hour = data[offset];
    final minute = data[offset + 1];
    final second = data[offset + 2];
    final hundredths = data[offset + 3];
    offset += 4;

    // Value: Any application tag
    if (offset >= data.length) return null;

    final valueTag = data[offset];
    final tagNumber = (valueTag >> 4) & 0x0F;
    dynamic value;

    switch (tagNumber) {
      case 0: // Null
        value = null;
        offset++;
        break;

      case 1: // Boolean
        value = (valueTag & 0x01) == 1;
        offset++;
        break;

      case 2: // Unsigned
      case 9: // Enumerated
        final length = valueTag & 0x07;
        offset++;
        if (offset + length <= data.length) {
          int intVal = 0;
          for (int i = 0; i < length; i++) {
            intVal = (intVal << 8) | data[offset + i];
          }
          value = intVal;
          offset += length;
        }
        break;

      case 3: // Signed
        final length = valueTag & 0x07;
        offset++;
        if (offset + length <= data.length) {
          int intVal = 0;
          bool negative = (data[offset] & 0x80) != 0;
          for (int i = 0; i < length; i++) {
            intVal = (intVal << 8) | data[offset + i];
          }
          if (negative) {
            intVal = intVal - (1 << (length * 8));
          }
          value = intVal;
          offset += length;
        }
        break;

      case 4: // Real (float32)
        offset++;
        if (offset + 4 <= data.length) {
          final bytes = ByteData.sublistView(data, offset, offset + 4);
          value = bytes.getFloat32(0, Endian.big);
          offset += 4;
        }
        break;

      default:
        // Unknown tag, skip based on length
        final length = valueTag & 0x07;
        offset += 1 + length;
    }

    return (
      timeValue: DecodedTimeValue(
        hour: hour,
        minute: minute,
        second: second,
        hundredths: hundredths,
        value: value,
        valueTag: tagNumber,
      ),
      nextOffset: offset,
    );
  }
}
