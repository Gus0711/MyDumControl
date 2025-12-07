/// Constantes du protocole BACnet/IP
library;

/// Port UDP par défaut pour BACnet/IP
const int bacnetDefaultPort = 47808;

/// Timeout par défaut pour les requêtes BACnet (ms)
const int bacnetDefaultTimeout = 5000;

/// Version du protocole NPDU
const int npduVersion = 0x01;

/// BVLC Type pour BACnet/IP
const int bvlcTypeBacnetIp = 0x81;

/// BVLC Functions
class BvlcFunction {
  static const int result = 0x00;
  static const int writeBroadcastDistributionTable = 0x01;
  static const int readBroadcastDistributionTable = 0x02;
  static const int readBroadcastDistributionTableAck = 0x03;
  static const int forwardedNpdu = 0x04;
  static const int registerForeignDevice = 0x05;
  static const int readForeignDeviceTable = 0x06;
  static const int readForeignDeviceTableAck = 0x07;
  static const int deleteForeignDeviceTableEntry = 0x08;
  static const int distributeBroadcastToNetwork = 0x09;
  static const int originalUnicastNpdu = 0x0A;
  static const int originalBroadcastNpdu = 0x0B;
}

/// NPDU Control Flags
class NpduControl {
  /// Bit 7: 1 = NSDU contient un message réseau, 0 = NSDU contient un APDU
  static const int networkLayerMessage = 0x80;

  /// Bit 5: 1 = DNET, DLEN, DADR et Hop Count présents
  static const int destinationSpecifier = 0x20;

  /// Bit 3: 1 = SNET, SLEN et SADR présents
  static const int sourceSpecifier = 0x08;

  /// Bit 2: 1 = réponse attendue (pour Confirmed requests)
  static const int expectingReply = 0x04;

  /// Bits 1-0: Priorité (0 = normal, 1 = urgent, 2 = critical, 3 = life safety)
  static const int priorityNormal = 0x00;
  static const int priorityUrgent = 0x01;
  static const int priorityCritical = 0x02;
  static const int priorityLifeSafety = 0x03;
}

/// APDU Types (bits 7-4 du premier byte)
class ApduType {
  static const int confirmedRequest = 0x00;
  static const int unconfirmedRequest = 0x10;
  static const int simpleAck = 0x20;
  static const int complexAck = 0x30;
  static const int segmentAck = 0x40;
  static const int error = 0x50;
  static const int reject = 0x60;
  static const int abort = 0x70;
}

/// Confirmed Service Choices
class ConfirmedService {
  static const int acknowledgeAlarm = 0;
  static const int confirmedCovNotification = 1;
  static const int confirmedEventNotification = 2;
  static const int getAlarmSummary = 3;
  static const int getEnrollmentSummary = 4;
  static const int subscribeCov = 5;
  static const int atomicReadFile = 6;
  static const int atomicWriteFile = 7;
  static const int addListElement = 8;
  static const int removeListElement = 9;
  static const int createObject = 10;
  static const int deleteObject = 11;
  static const int readProperty = 12;
  static const int readPropertyConditional = 13;
  static const int readPropertyMultiple = 14;
  static const int writeProperty = 15;
  static const int writePropertyMultiple = 16;
  static const int deviceCommunicationControl = 17;
  static const int confirmedPrivateTransfer = 18;
  static const int confirmedTextMessage = 19;
  static const int reinitializeDevice = 20;
  static const int vtOpen = 21;
  static const int vtClose = 22;
  static const int vtData = 23;
  static const int authenticate = 24;
  static const int requestKey = 25;
  static const int readRange = 26;
  static const int lifeSafetyOperation = 27;
  static const int subscribeCovProperty = 28;
  static const int getEventInformation = 29;
}

/// Unconfirmed Service Choices
class UnconfirmedService {
  static const int iAm = 0;
  static const int iHave = 1;
  static const int unconfirmedCovNotification = 2;
  static const int unconfirmedEventNotification = 3;
  static const int unconfirmedPrivateTransfer = 4;
  static const int unconfirmedTextMessage = 5;
  static const int timeSynchronization = 6;
  static const int whoHas = 7;
  static const int whoIs = 8;
  static const int utcTimeSynchronization = 9;
}

/// BACnet Object Types
class BacnetObjectTypeCode {
  static const int analogInput = 0;
  static const int analogOutput = 1;
  static const int analogValue = 2;
  static const int binaryInput = 3;
  static const int binaryOutput = 4;
  static const int binaryValue = 5;
  static const int calendar = 6;
  static const int command = 7;
  static const int device = 8;
  static const int eventEnrollment = 9;
  static const int file = 10;
  static const int group = 11;
  static const int loop = 12;
  static const int multiStateInput = 13;
  static const int multiStateOutput = 14;
  static const int notificationClass = 15;
  static const int program = 16;
  static const int schedule = 17;
  static const int averaging = 18;
  static const int multiStateValue = 19;
  static const int trendLog = 20;
  static const int lifeSafetyPoint = 21;
  static const int lifeSafetyZone = 22;
  static const int accumulator = 23;
  static const int pulseConverter = 24;
  static const int eventLog = 25;
  static const int globalGroup = 26;
  static const int trendLogMultiple = 27;
  static const int loadControl = 28;
  static const int structuredView = 29;
  static const int accessDoor = 30;
  static const int accessCredential = 32;
  static const int accessPoint = 33;
  static const int accessRights = 34;
  static const int accessUser = 35;
  static const int accessZone = 36;
  static const int credentialDataInput = 37;
  static const int networkPort = 56;
  static const int networkSecurity = 38;
  static const int bitstringValue = 39;
  static const int characterstringValue = 40;
  static const int datePatternValue = 41;
  static const int dateValue = 42;
  static const int datetimePatternValue = 43;
  static const int datetimeValue = 44;
  static const int integerValue = 45;
  static const int largeAnalogValue = 46;
  static const int octetstringValue = 47;
  static const int positiveIntegerValue = 48;
  static const int timePatternValue = 49;
  static const int timeValue = 50;

  /// Convertit un code en nom lisible
  static String getName(int code) {
    return _names[code] ?? 'unknown-$code';
  }

  static const Map<int, String> _names = {
    0: 'analog-input',
    1: 'analog-output',
    2: 'analog-value',
    3: 'binary-input',
    4: 'binary-output',
    5: 'binary-value',
    6: 'calendar',
    7: 'command',
    8: 'device',
    9: 'event-enrollment',
    10: 'file',
    11: 'group',
    12: 'loop',
    13: 'multi-state-input',
    14: 'multi-state-output',
    15: 'notification-class',
    16: 'program',
    17: 'schedule',
    18: 'averaging',
    19: 'multi-state-value',
    20: 'trend-log',
    21: 'life-safety-point',
    22: 'life-safety-zone',
    23: 'accumulator',
    24: 'pulse-converter',
    25: 'event-log',
    26: 'global-group',
    27: 'trend-log-multiple',
    28: 'load-control',
    29: 'structured-view',
    30: 'access-door',
    32: 'access-credential',
    33: 'access-point',
    34: 'access-rights',
    35: 'access-user',
    36: 'access-zone',
    37: 'credential-data-input',
    38: 'network-security',
    39: 'bitstring-value',
    40: 'characterstring-value',
    41: 'date-pattern-value',
    42: 'date-value',
    43: 'datetime-pattern-value',
    44: 'datetime-value',
    45: 'integer-value',
    46: 'large-analog-value',
    47: 'octetstring-value',
    48: 'positive-integer-value',
    49: 'time-pattern-value',
    50: 'time-value',
    56: 'network-port',
  };
}

/// BACnet Property IDs
class BacnetPropertyId {
  static const int ackedTransitions = 0;
  static const int ackRequired = 1;
  static const int action = 2;
  static const int actionText = 3;
  static const int activeText = 4;
  static const int activeVtSessions = 5;
  static const int alarmValue = 6;
  static const int alarmValues = 7;
  static const int all = 8;
  static const int allWritesSuccessful = 9;
  static const int apduSegmentTimeout = 10;
  static const int apduTimeout = 11;
  static const int applicationSoftwareVersion = 12;
  static const int archive = 13;
  static const int bias = 14;
  static const int changeOfStateCount = 15;
  static const int changeOfStateTime = 16;
  static const int notificationClass = 17;
  static const int controlledVariableReference = 19;
  static const int controlledVariableUnits = 20;
  static const int controlledVariableValue = 21;
  static const int covIncrement = 22;
  static const int dateList = 23;
  static const int daylightSavingsStatus = 24;
  static const int deadband = 25;
  static const int derivativeConstant = 26;
  static const int derivativeConstantUnits = 27;
  static const int description = 28;
  static const int descriptionOfHalt = 29;
  static const int deviceAddressBinding = 30;
  static const int deviceType = 31;
  static const int effectivePeriod = 32;
  static const int elapsedActiveTime = 33;
  static const int errorLimit = 34;
  static const int eventEnable = 35;
  static const int eventState = 36;
  static const int eventType = 37;
  static const int exceptionSchedule = 38;
  static const int faultValues = 39;
  static const int feedbackValue = 40;
  static const int fileAccessMethod = 41;
  static const int fileSize = 42;
  static const int fileType = 43;
  static const int firmwareRevision = 44;
  static const int highLimit = 45;
  static const int inactiveText = 46;
  static const int inProcess = 47;
  static const int instanceOf = 48;
  static const int integralConstant = 49;
  static const int integralConstantUnits = 50;
  static const int limitEnable = 52;
  static const int listOfGroupMembers = 53;
  static const int listOfObjectPropertyReferences = 54;
  static const int localDate = 56;
  static const int localTime = 57;
  static const int location = 58;
  static const int lowLimit = 59;
  static const int manipulatedVariableReference = 60;
  static const int maximumOutput = 61;
  static const int maxApduLengthAccepted = 62;
  static const int maxInfoFrames = 63;
  static const int maxMaster = 64;
  static const int maxPresValue = 65;
  static const int minimumOffTime = 66;
  static const int minimumOnTime = 67;
  static const int minimumOutput = 68;
  static const int minPresValue = 69;
  static const int modelName = 70;
  static const int modificationDate = 71;
  static const int notifyType = 72;
  static const int numberOfApduRetries = 73;
  static const int numberOfStates = 74;
  static const int objectIdentifier = 75;
  static const int objectList = 76;
  static const int objectName = 77;
  static const int objectPropertyReference = 78;
  static const int objectType = 79;
  static const int optional = 80;
  static const int outOfService = 81;
  static const int outputUnits = 82;
  static const int eventParameters = 83;
  static const int polarity = 84;
  static const int presentValue = 85;
  static const int priority = 86;
  static const int priorityArray = 87;
  static const int priorityForWriting = 88;
  static const int processIdentifier = 89;
  static const int programChange = 90;
  static const int programLocation = 91;
  static const int programState = 92;
  static const int proportionalConstant = 93;
  static const int proportionalConstantUnits = 94;
  static const int protocolObjectTypesSupported = 96;
  static const int protocolServicesSupported = 97;
  static const int protocolVersion = 98;
  static const int readOnly = 99;
  static const int reasonForHalt = 100;
  static const int recipientList = 102;
  static const int reliability = 103;
  static const int relinquishDefault = 104;
  static const int required = 105;
  static const int resolution = 106;
  static const int segmentationSupported = 107;
  static const int setpoint = 108;
  static const int setpointReference = 109;
  static const int stateText = 110;
  static const int statusFlags = 111;
  static const int systemStatus = 112;
  static const int timeDelay = 113;
  static const int timeOfActiveTimeReset = 114;
  static const int timeOfStateCountReset = 115;
  static const int timeSynchronizationRecipients = 116;
  static const int units = 117;
  static const int updateInterval = 118;
  static const int utcOffset = 119;
  static const int vendorIdentifier = 120;
  static const int vendorName = 121;
  static const int vtClassesSupported = 122;
  static const int weeklySchedule = 123;
  static const int attemptedSamples = 124;
  static const int averageValue = 125;
  static const int bufferSize = 126;
  static const int clientCovIncrement = 127;
  static const int covResubscriptionInterval = 128;
  static const int eventTimeStamps = 130;
  static const int logBuffer = 131;
  static const int logDeviceObjectProperty = 132;
  static const int enable = 133;
  static const int logInterval = 134;
  static const int maximumValue = 135;
  static const int minimumValue = 136;
  static const int notificationThreshold = 137;
  static const int protocolRevision = 139;
  static const int recordsSinceNotification = 140;
  static const int recordCount = 141;
  static const int startTime = 142;
  static const int stopTime = 143;
  static const int stopWhenFull = 144;
  static const int totalRecordCount = 145;
  static const int validSamples = 146;
  static const int windowInterval = 147;
  static const int windowSamples = 148;
  static const int maximumValueTimestamp = 149;
  static const int minimumValueTimestamp = 150;
  static const int varianceValue = 151;
  static const int activeCovSubscriptions = 152;
  static const int backupFailureTimeout = 153;
  static const int configurationFiles = 154;
  static const int databaseRevision = 155;
  static const int directReading = 156;
  static const int lastRestoreTime = 157;
  static const int maintenanceRequired = 158;
  static const int memberOf = 159;
  static const int mode = 160;
  static const int operationExpected = 161;
  static const int setting = 162;
  static const int silenced = 163;
  static const int trackingValue = 164;
  static const int zoneMembers = 165;
  static const int lifeSafetyAlarmValues = 166;
  static const int maxSegmentsAccepted = 167;
  static const int profileName = 168;
}

/// Application Tags (ASN.1/BER encoding)
class ApplicationTag {
  static const int nullValue = 0;
  static const int boolean = 1;
  static const int unsignedInt = 2;
  static const int signedInt = 3;
  static const int real = 4;
  static const int double_ = 5;
  static const int octetString = 6;
  static const int characterString = 7;
  static const int bitString = 8;
  static const int enumerated = 9;
  static const int date = 10;
  static const int time = 11;
  static const int objectIdentifier = 12;
}

/// Error Classes
class BacnetErrorClass {
  static const int device = 0;
  static const int object = 1;
  static const int property = 2;
  static const int resources = 3;
  static const int security = 4;
  static const int services = 5;
  static const int vt = 6;
  static const int communication = 7;
}

/// Error Codes
class BacnetErrorCode {
  static const int other = 0;
  static const int configurationInProgress = 2;
  static const int deviceBusy = 3;
  static const int dynamicCreationNotSupported = 4;
  static const int fileAccessDenied = 5;
  static const int inconsistentParameters = 7;
  static const int inconsistentSelectionCriterion = 8;
  static const int invalidDataType = 9;
  static const int invalidFileAccessMethod = 10;
  static const int invalidFileStartPosition = 11;
  static const int invalidParameterDataType = 13;
  static const int invalidTimeStamp = 14;
  static const int missingRequiredParameter = 16;
  static const int noObjectsOfSpecifiedType = 17;
  static const int noSpaceForObject = 18;
  static const int noSpaceToAddListElement = 19;
  static const int noSpaceToWriteProperty = 20;
  static const int noVtSessionsAvailable = 21;
  static const int propertyIsNotAList = 22;
  static const int objectDeletionNotPermitted = 23;
  static const int objectIdentifierAlreadyExists = 24;
  static const int operationalProblem = 25;
  static const int passwordFailure = 26;
  static const int readAccessDenied = 27;
  static const int serviceRequestDenied = 29;
  static const int timeout = 30;
  static const int unknownObject = 31;
  static const int unknownProperty = 32;
  static const int unknownVtClass = 34;
  static const int unknownVtSession = 35;
  static const int unsupportedObjectType = 36;
  static const int valueOutOfRange = 37;
  static const int vtSessionAlreadyClosed = 38;
  static const int vtSessionTerminationFailure = 39;
  static const int writeAccessDenied = 40;
  static const int characterSetNotSupported = 41;
  static const int invalidArrayIndex = 42;
  static const int covSubscriptionFailed = 43;
  static const int notCovProperty = 44;
  static const int optionalFunctionalityNotSupported = 45;
  static const int invalidConfigurationData = 46;
}
