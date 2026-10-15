/// Constantes liées aux API ECLYPSE
class ApiConstants {
  ApiConstants._();

  // Timeouts (ConnectedApiClient)
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Timeout for large downloads (trend-log buffers, V2 history get-table)
  static const Duration longReceiveTimeout = Duration(minutes: 5);
  static const Duration longSendTimeout = Duration(minutes: 1);

  /// Timeout used by the connection test (ApiService.testConnection): kept
  /// short so that an unreachable host fails fast.
  static const Duration testConnectionTimeout = Duration(seconds: 10);

  /// Maximum number of HTTP requests in flight towards one controller: the
  /// ECLYPSE answers 401 to valid credentials when it receives bursts.
  static const int maxConcurrentRequests = 4;

  // Ports par défaut
  static const int defaultHttpsPort = 443;
  static const int defaultHttpPort = 80;

  // Chemins API V1
  static const String v1BasePath = '/api/rest/v1';
  static const String v1Info = '$v1BasePath/info';
  static const String v1DeviceInfo = '$v1BasePath/info/device';
  static const String v1BacnetLocal = '$v1BasePath/protocols/bacnet/local';
  static const String v1Objects = '$v1BacnetLocal/objects';
  static const String v1Alarms = '$v1BasePath/alarms';

  // Chemins API V2
  static const String v2BasePath = '/api/rest/v2';
  static const String v2Info = '$v2BasePath/info';
  static const String v2DeviceInfo = '$v2BasePath/info/device';
  static const String v2Services = '$v2BasePath/services';
  static const String v2BacnetLocal = '$v2Services/bacnet/local';
  static const String v2Objects = '$v2BacnetLocal/objects';
  static const String v2Alarms = '$v2Services/alarm';
  static const String v2Batch = '$v2BasePath/batch';
  static const String v2Platform = '$v2Services/platform';
  static const String v2BacnetHistories = '$v2Services/history/groups/bacnet/histories';

  // Types d'objets BACnet
  static const String objectTypeAnalogInput = 'analog-input';
  static const String objectTypeAnalogOutput = 'analog-output';
  static const String objectTypeAnalogValue = 'analog-value';
  static const String objectTypeBinaryInput = 'binary-input';
  static const String objectTypeBinaryOutput = 'binary-output';
  static const String objectTypeBinaryValue = 'binary-value';
  static const String objectTypeSchedule = 'schedule';
  static const String objectTypeLoop = 'loop';
  static const String objectTypeTrendLog = 'trend-log';

  // Propriétés BACnet communes
  static const String propertyPresentValue = 'present-value';
  static const String propertyObjectName = 'object-name';
  static const String propertyDescription = 'description';
  static const String propertyUnits = 'units';
  static const String propertyStatusFlags = 'status-flags';
  static const String propertyOutOfService = 'out-of-service';
  static const String propertyPriorityArray = 'priority-array';
  static const String propertyWeeklySchedule = 'weekly-schedule';
}
