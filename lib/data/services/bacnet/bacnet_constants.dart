/// Constantes du protocole BACnet/IP
library;

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

/// Network Layer Message Types (quand NpduControl.networkLayerMessage est set)
/// Ces messages sont utilisés pour la découverte et la gestion des routeurs BACnet
class NetworkLayerMessageType {
  static const int whoIsRouterToNetwork = 0x00;
  static const int iAmRouterToNetwork = 0x01;
  static const int iCouldBeRouterToNetwork = 0x02;
  static const int rejectMessageToNetwork = 0x03;
  static const int routerBusyToNetwork = 0x04;
  static const int routerAvailableToNetwork = 0x05;
  static const int initializeRoutingTable = 0x06;
  static const int initializeRoutingTableAck = 0x07;
  static const int establishConnectionToNetwork = 0x08;
  static const int disconnectConnectionToNetwork = 0x09;
  static const int challengeRequest = 0x0A;
  static const int securityPayload = 0x0B;
  static const int securityResponse = 0x0C;
  static const int requestKeyUpdate = 0x0D;
  static const int updateKeySet = 0x0E;
  static const int updateDistributionKey = 0x0F;
  static const int requestMasterKey = 0x10;
  static const int setMasterKey = 0x11;
  static const int whatIsNetworkNumber = 0x12;
  static const int networkNumberIs = 0x13;
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
  static const int scheduleDefault = 174;
  static const int propertyList = 371;
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

/// BACnet Engineering Units (ASHRAE 135-2020)
class BacnetUnits {
  // Acceleration
  static const int metersPerSecondPerSecond = 166;

  // Area
  static const int squareMeters = 0;
  static const int squareCentimeters = 116;
  static const int squareFeet = 1;
  static const int squareInches = 115;

  // Currency
  static const int currency1 = 105;
  static const int currency2 = 106;
  static const int currency3 = 107;
  static const int currency4 = 108;
  static const int currency5 = 109;
  static const int currency6 = 110;
  static const int currency7 = 111;
  static const int currency8 = 112;
  static const int currency9 = 113;
  static const int currency10 = 114;

  // Electrical
  static const int milliamperes = 2;
  static const int amperes = 3;
  static const int amperesPerMeter = 167;
  static const int amperesPerSquareMeter = 168;
  static const int ampereSquareMeters = 169;
  static const int decibels = 199;
  static const int decibelsMillivolt = 200;
  static const int decibelsVolt = 201;
  static const int farads = 170;
  static const int henrys = 171;
  static const int ohms = 4;
  static const int ohmMeters = 172;
  static const int milliohms = 145;
  static const int kilohms = 122;
  static const int megohms = 123;
  static const int microsiemens = 190;
  static const int millisiemens = 202;
  static const int siemens = 173;
  static const int siemensPerMeter = 174;
  static const int teslas = 175;
  static const int volts = 5;
  static const int millivolts = 124;
  static const int kilovolts = 6;
  static const int megavolts = 7;
  static const int voltAmperes = 8;
  static const int kilovoltAmperes = 9;
  static const int megavoltAmperes = 10;
  static const int voltAmperesReactive = 11;
  static const int kilovoltAmperesReactive = 12;
  static const int megavoltAmperesReactive = 13;
  static const int voltsPerDegreeKelvin = 176;
  static const int voltsPerMeter = 177;
  static const int degreesPhase = 14;
  static const int powerFactor = 15;
  static const int webers = 178;

  // Energy
  static const int joules = 16;
  static const int kilojoules = 17;
  static const int kilojoulesPerKilogram = 125;
  static const int megajoules = 126;
  static const int wattHours = 18;
  static const int kilowattHours = 19;
  static const int megawattHours = 146;
  static const int wattHoursReactive = 203;
  static const int kilowattHoursReactive = 204;
  static const int megawattHoursReactive = 205;
  static const int btus = 20;
  static const int kiloBtus = 147;
  static const int megaBtus = 148;
  static const int therms = 21;
  static const int tonHours = 22;

  // Enthalpy
  static const int joulesPerKilogramDryAir = 23;
  static const int kilojoulesPerKilogramDryAir = 149;
  static const int megajoulesPerKilogramDryAir = 150;
  static const int btusPerPoundDryAir = 24;
  static const int btusPerPound = 117;

  // Entropy
  static const int joulesPerDegreeKelvin = 127;
  static const int kilojoulesPerDegreeKelvin = 151;
  static const int megajoulesPerDegreeKelvin = 152;
  static const int joulesPerKilogramDegreeKelvin = 128;

  // Force
  static const int newtons = 153;

  // Frequency
  static const int cyclesPerHour = 25;
  static const int cyclesPerMinute = 26;
  static const int hertz = 27;
  static const int kilohertz = 129;
  static const int megahertz = 130;
  static const int perHour = 131;

  // Humidity
  static const int gramsOfWaterPerKilogramDryAir = 28;
  static const int percentRelativeHumidity = 29;

  // Length
  static const int micrometers = 194;
  static const int millimeters = 30;
  static const int centimeters = 118;
  static const int kilometers = 193;
  static const int meters = 31;
  static const int inches = 32;
  static const int feet = 33;

  // Light
  static const int candelas = 179;
  static const int candelasPerSquareMeter = 180;
  static const int wattsPerSquareFoot = 34;
  static const int wattsPerSquareMeter = 35;
  static const int lumens = 36;
  static const int luxes = 37;
  static const int footCandles = 38;

  // Mass
  static const int milligrams = 196;
  static const int grams = 195;
  static const int kilograms = 39;
  static const int poundsMass = 40;
  static const int tons = 41;

  // Mass Flow
  static const int gramsPerSecond = 154;
  static const int gramsPerMinute = 155;
  static const int kilogramsPerSecond = 42;
  static const int kilogramsPerMinute = 43;
  static const int kilogramsPerHour = 44;
  static const int poundsMassPerSecond = 119;
  static const int poundsMassPerMinute = 45;
  static const int poundsMassPerHour = 46;
  static const int tonsPerHour = 156;

  // Power
  static const int milliwatts = 132;
  static const int watts = 47;
  static const int kilowatts = 48;
  static const int megawatts = 49;
  static const int btusPerHour = 50;
  static const int kiloBtusPerHour = 157;
  static const int horsepower = 51;
  static const int tonsRefrigeration = 52;

  // Pressure
  static const int pascals = 53;
  static const int hectopascals = 133;
  static const int kilopascals = 54;
  static const int millibars = 134;
  static const int bars = 55;
  static const int poundsForcePerSquareInch = 56;
  static const int millimetersOfWater = 206;
  static const int centimetersOfWater = 57;
  static const int inchesOfWater = 58;
  static const int millimetersOfMercury = 59;
  static const int centimetersOfMercury = 60;
  static const int inchesOfMercury = 61;

  // Temperature
  static const int degreesCelsius = 62;
  static const int degreesKelvin = 63;
  static const int degreesKelvinPerHour = 181;
  static const int degreesKelvinPerMinute = 182;
  static const int degreesFahrenheit = 64;
  static const int degreeDaysCelsius = 65;
  static const int degreeDaysFahrenheit = 66;
  static const int deltaDegreesFahrenheit = 120;
  static const int deltaDegreesCelsius = 121;

  // Time
  static const int years = 67;
  static const int months = 68;
  static const int weeks = 69;
  static const int days = 70;
  static const int hours = 71;
  static const int minutes = 72;
  static const int seconds = 73;
  static const int hundredthsSeconds = 158;
  static const int milliseconds = 159;

  // Torque
  static const int newtonMeters = 160;

  // Velocity
  static const int millimetersPerSecond = 161;
  static const int millimetersPerMinute = 162;
  static const int metersPerSecond = 74;
  static const int metersPerMinute = 163;
  static const int metersPerHour = 164;
  static const int kilometersPerHour = 75;
  static const int feetPerSecond = 76;
  static const int feetPerMinute = 77;
  static const int milesPerHour = 78;

  // Volume
  static const int cubicFeet = 79;
  static const int cubicMeters = 80;
  static const int imperialGallons = 81;
  static const int milliliters = 197;
  static const int liters = 82;
  static const int usGallons = 83;

  // Volumetric Flow
  static const int cubicFeetPerSecond = 142;
  static const int cubicFeetPerMinute = 84;
  static const int cubicFeetPerHour = 191;
  static const int cubicFeetPerDay = 248;
  static const int cubicMetersPerSecond = 85;
  static const int cubicMetersPerMinute = 165;
  static const int cubicMetersPerHour = 135;
  static const int cubicMetersPerDay = 249;
  static const int imperialGallonsPerMinute = 86;
  static const int millilitersPerSecond = 198;
  static const int litersPerSecond = 87;
  static const int litersPerMinute = 88;
  static const int litersPerHour = 136;
  static const int usGallonsPerMinute = 89;
  static const int usGallonsPerHour = 192;

  // Other
  static const int degreesAngular = 90;
  static const int degreesCelsiusPerHour = 91;
  static const int degreesCelsiusPerMinute = 92;
  static const int degreesFahrenheitPerHour = 93;
  static const int degreesFahrenheitPerMinute = 94;
  static const int percent = 95;
  static const int percentPerSecond = 96;
  static const int perMinute = 97;
  static const int perSecond = 98;
  static const int psiPerDegreeFahrenheit = 102;
  static const int radians = 103;
  static const int radiansPerSecond = 184;
  static const int revolutionsPerMinute = 104;
  static const int squareMetersPerNewton = 185;
  static const int wattsPerMeterPerDegreeKelvin = 189;
  static const int wattsPerSquareMeterDegreeKelvin = 141;
  static const int perMille = 207;
  static const int gramsPerGram = 208;
  static const int kilogramsPerKilogram = 209;
  static const int gramsPerKilogram = 210;
  static const int milligramsPerGram = 211;
  static const int milligramsPerKilogram = 212;
  static const int gramsPerMilliliter = 213;
  static const int gramsPerLiter = 214;
  static const int milligramsPerLiter = 215;
  static const int microgramsPerLiter = 216;
  static const int gramsPerCubicMeter = 217;
  static const int milligramsPerCubicMeter = 218;
  static const int microgramsPerCubicMeter = 219;
  static const int nanogramsPerCubicMeter = 220;
  static const int gramsPerCubicCentimeter = 221;
  static const int becquerels = 222;
  static const int kilobecquerels = 223;
  static const int megabecquerels = 224;
  static const int gray = 225;
  static const int milligray = 226;
  static const int microgray = 227;
  static const int sieverts = 228;
  static const int millisieverts = 229;
  static const int microsieverts = 230;
  static const int microsievertsPerHour = 231;
  static const int decibelsA = 232;
  static const int neppiersPerSecond = 233;
  static const int partsPerMillion = 99;
  static const int partsPerBillion = 100;
  static const int noUnits = 95;  // Note: same as percent in some implementations

  // pH and special
  static const int ph = 234;
  static const int cubicMetersPerUnit = 244;
  static const int litersPerUnit = 245;

  /// Convertit un code d'unité en texte lisible
  static String getUnitText(dynamic unit) {
    if (unit == null) return '';

    // Si c'est déjà du texte, le retourner tel quel
    if (unit is String) {
      // Si c'est un nombre sous forme de chaîne, le convertir
      final code = int.tryParse(unit);
      if (code != null) {
        return _unitNames[code] ?? unit;
      }
      // Sinon retourner la chaîne telle quelle (ex: "DegreesCelsius")
      return _formatUnitText(unit);
    }

    // Si c'est un nombre, chercher le texte correspondant
    if (unit is int) {
      return _unitNames[unit] ?? 'code-$unit';
    }

    return unit.toString();
  }

  /// Formate un texte d'unité camelCase ou PascalCase en texte lisible
  static String _formatUnitText(String text) {
    if (text.isEmpty) return '';

    // Cas spéciaux déjà bien formatés
    final knownUnits = {
      'NoUnits': '',
      'Percent': '%',
      'DegreesCelsius': '°C',
      'DegreesFahrenheit': '°F',
      'DegreesKelvin': 'K',
      'Seconds': 's',
      'Minutes': 'min',
      'Hours': 'h',
      'Days': 'j',
      'Meters': 'm',
      'Centimeters': 'cm',
      'Millimeters': 'mm',
      'Feet': 'ft',
      'Inches': 'in',
      'Kilograms': 'kg',
      'Grams': 'g',
      'Milligrams': 'mg',
      'Pounds': 'lb',
      'Pascals': 'Pa',
      'Kilopascals': 'kPa',
      'Bars': 'bar',
      'Millibars': 'mbar',
      'Watts': 'W',
      'Kilowatts': 'kW',
      'Megawatts': 'MW',
      'WattsPerSquareMeter': 'W/m²',
      'WattsPerSquareFoot': 'W/ft²',
      'Volts': 'V',
      'Millivolts': 'mV',
      'Kilovolts': 'kV',
      'Amperes': 'A',
      'Milliamperes': 'mA',
      'Ohms': 'Ω',
      'Hertz': 'Hz',
      'Kilohertz': 'kHz',
      'Megahertz': 'MHz',
      'Liters': 'L',
      'Milliliters': 'mL',
      'CubicMeters': 'm³',
      'CubicFeet': 'ft³',
      'LitersPerSecond': 'L/s',
      'LitersPerMinute': 'L/min',
      'LitersPerHour': 'L/h',
      'CubicMetersPerHour': 'm³/h',
      'CubicFeetPerMinute': 'CFM',
      'KilowattHours': 'kWh',
      'WattHours': 'Wh',
      'Joules': 'J',
      'Kilojoules': 'kJ',
      'Megajoules': 'MJ',
      'Btus': 'BTU',
      'PercentRelativeHumidity': '%RH',
      'PartsPerMillion': 'ppm',
      'PartsPerBillion': 'ppb',
      'Radians': 'rad',
      'DegreesAngular': '°',
      'MetersPerSecond': 'm/s',
      'KilometersPerHour': 'km/h',
      'MilesPerHour': 'mph',
      'FeetPerMinute': 'ft/min',
      'RevolutionsPerMinute': 'RPM',
      'Lumens': 'lm',
      'Luxes': 'lx',
      'FootCandles': 'fc',
    };

    return knownUnits[text] ?? text;
  }

  static const Map<int, String> _unitNames = {
    0: 'm²',
    1: 'ft²',
    2: 'mA',
    3: 'A',
    4: 'Ω',
    5: 'V',
    6: 'kV',
    7: 'MV',
    8: 'VA',
    9: 'kVA',
    10: 'MVA',
    11: 'VAR',
    12: 'kVAR',
    13: 'MVAR',
    14: '°',
    15: 'PF',
    16: 'J',
    17: 'kJ',
    18: 'Wh',
    19: 'kWh',
    20: 'BTU',
    21: 'therm',
    22: 'ton-h',
    23: 'J/kg air sec',
    24: 'BTU/lb air sec',
    25: 'cycles/h',
    26: 'cycles/min',
    27: 'Hz',
    28: 'g eau/kg air sec',
    29: '%RH',
    30: 'mm',
    31: 'm',
    32: 'in',
    33: 'ft',
    34: 'W/ft²',
    35: 'W/m²',
    36: 'lm',
    37: 'lx',
    38: 'fc',
    39: 'kg',
    40: 'lb',
    41: 'ton',
    42: 'kg/s',
    43: 'kg/min',
    44: 'kg/h',
    45: 'lb/min',
    46: 'lb/h',
    47: 'W',
    48: 'kW',
    49: 'MW',
    50: 'BTU/h',
    51: 'HP',
    52: 'TR',
    53: 'Pa',
    54: 'kPa',
    55: 'bar',
    56: 'psi',
    57: 'cmH₂O',
    58: 'inH₂O',
    59: 'mmHg',
    60: 'cmHg',
    61: 'inHg',
    62: '°C',
    63: 'K',
    64: '°F',
    65: '°C·j',
    66: '°F·j',
    67: 'années',
    68: 'mois',
    69: 'semaines',
    70: 'jours',
    71: 'h',
    72: 'min',
    73: 's',
    74: 'm/s',
    75: 'km/h',
    76: 'ft/s',
    77: 'ft/min',
    78: 'mph',
    79: 'ft³',
    80: 'm³',
    81: 'gal UK',
    82: 'L',
    83: 'gal US',
    84: 'CFM',
    85: 'm³/s',
    86: 'gal UK/min',
    87: 'L/s',
    88: 'L/min',
    89: 'gal US/min',
    90: '°',
    91: '°C/h',
    92: '°C/min',
    93: '°F/h',
    94: '°F/min',
    95: '%',
    96: '%/s',
    97: '/min',
    98: '/s',
    99: 'ppm',
    100: 'ppb',
    102: 'psi/°F',
    103: 'rad',
    104: 'RPM',
    115: 'in²',
    116: 'cm²',
    117: 'BTU/lb',
    118: 'cm',
    119: 'lb/s',
    120: 'Δ°F',
    121: 'Δ°C',
    122: 'kΩ',
    123: 'MΩ',
    124: 'mV',
    125: 'kJ/kg',
    126: 'MJ',
    127: 'J/K',
    128: 'J/(kg·K)',
    129: 'kHz',
    130: 'MHz',
    131: '/h',
    132: 'mW',
    133: 'hPa',
    134: 'mbar',
    135: 'm³/h',
    136: 'L/h',
    141: 'W/(m²·K)',
    142: 'ft³/s',
    145: 'mΩ',
    146: 'MWh',
    147: 'kBTU',
    148: 'MBTU',
    149: 'kJ/kg air sec',
    150: 'MJ/kg air sec',
    151: 'kJ/K',
    152: 'MJ/K',
    153: 'N',
    154: 'g/s',
    155: 'g/min',
    156: 'ton/h',
    157: 'kBTU/h',
    158: 'cs',
    159: 'ms',
    160: 'N·m',
    161: 'mm/s',
    162: 'mm/min',
    163: 'm/min',
    164: 'm/h',
    165: 'm³/min',
    166: 'm/s²',
    167: 'A/m',
    168: 'A/m²',
    169: 'A·m²',
    170: 'F',
    171: 'H',
    172: 'Ω·m',
    173: 'S',
    174: 'S/m',
    175: 'T',
    176: 'V/K',
    177: 'V/m',
    178: 'Wb',
    179: 'cd',
    180: 'cd/m²',
    181: 'K/h',
    182: 'K/min',
    184: 'rad/s',
    185: 'm²/N',
    189: 'W/(m·K)',
    190: 'µS',
    191: 'ft³/h',
    192: 'gal US/h',
    193: 'km',
    194: 'µm',
    195: 'g',
    196: 'mg',
    197: 'mL',
    198: 'mL/s',
    199: 'dB',
    200: 'dBmV',
    201: 'dBV',
    202: 'mS',
    203: 'VARh',
    204: 'kVARh',
    205: 'MVARh',
    206: 'mmH₂O',
    207: '‰',
    208: 'g/g',
    209: 'kg/kg',
    210: 'g/kg',
    211: 'mg/g',
    212: 'mg/kg',
    213: 'g/mL',
    214: 'g/L',
    215: 'mg/L',
    216: 'µg/L',
    217: 'g/m³',
    218: 'mg/m³',
    219: 'µg/m³',
    220: 'ng/m³',
    221: 'g/cm³',
    222: 'Bq',
    223: 'kBq',
    224: 'MBq',
    225: 'Gy',
    226: 'mGy',
    227: 'µGy',
    228: 'Sv',
    229: 'mSv',
    230: 'µSv',
    231: 'µSv/h',
    232: 'dBA',
    233: 'Np/s',
    234: 'pH',
    244: 'm³/unité',
    245: 'L/unité',
    248: 'ft³/j',
    249: 'm³/j',
  };
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
