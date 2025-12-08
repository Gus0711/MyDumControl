// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MyDumControl';

  @override
  String get connections => 'Connections';

  @override
  String get addConnection => 'Add connection';

  @override
  String get editConnection => 'Edit connection';

  @override
  String get deleteConnection => 'Delete connection';

  @override
  String get connectionName => 'Connection name';

  @override
  String get host => 'Host';

  @override
  String get port => 'Port';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get testConnection => 'Test connection';

  @override
  String get connectionSuccess => 'Connection successful';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get noConnections => 'No saved connections';

  @override
  String get home => 'Home';

  @override
  String get points => 'Points';

  @override
  String get physicalInputs => 'Physical inputs';

  @override
  String get physicalOutputs => 'Physical outputs';

  @override
  String get analogValues => 'Analog values';

  @override
  String get alarms => 'Alarms';

  @override
  String get activeAlarms => 'Active alarms';

  @override
  String get noAlarms => 'No active alarms';

  @override
  String get acknowledge => 'Acknowledge';

  @override
  String get schedules => 'Schedules';

  @override
  String get overrides => 'Overrides';

  @override
  String get favorites => 'Favorites';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get pidLoops => 'PID loops';

  @override
  String get settings => 'Settings';

  @override
  String get deviceInfo => 'Device info';

  @override
  String get appSettings => 'App settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get lightMode => 'Light mode';

  @override
  String get systemMode => 'System';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get noData => 'No data';

  @override
  String get search => 'Search';

  @override
  String get refresh => 'Refresh';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get connecting => 'Connecting...';

  @override
  String get apiVersion => 'API version';

  @override
  String get autoDetect => 'Auto-detect';

  @override
  String get certificateWarning => 'Self-signed certificate';

  @override
  String get trustCertificate => 'Trust this certificate';

  @override
  String get certificateDetails => 'Certificate details';

  @override
  String get fingerprint => 'Fingerprint';

  @override
  String get value => 'Value';

  @override
  String get unit => 'Unit';

  @override
  String get status => 'Status';

  @override
  String get lastUpdate => 'Last update';

  @override
  String get writeValue => 'Write value';

  @override
  String get overrideValue => 'Override value';

  @override
  String get releaseOverride => 'Release override';

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get deleteConfirmTitle => 'Confirm deletion';

  @override
  String get deleteConfirmMessage =>
      'Are you sure you want to delete this item?';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidHost => 'Invalid host';

  @override
  String get invalidPort => 'Invalid port (1-65535)';

  @override
  String get offline => 'Offline';

  @override
  String get online => 'Online';

  @override
  String get appearance => 'Appearance';

  @override
  String get connection => 'Connection';

  @override
  String get display => 'Display';

  @override
  String get data => 'Data';

  @override
  String get themeSystem => 'System (auto)';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get connectionTimeout => 'Connection timeout';

  @override
  String get seconds => 'seconds';

  @override
  String secondsValue(Object count) {
    return '$count seconds';
  }

  @override
  String get autoRefresh => 'Auto refresh';

  @override
  String get disabled => 'Disabled';

  @override
  String everySeconds(Object count) {
    return 'Every $count seconds';
  }

  @override
  String get defaultBacnetPort => 'Default BACnet port';

  @override
  String get temperatureUnit => 'Temperature unit';

  @override
  String get celsius => 'Celsius (°C)';

  @override
  String get fahrenheit => 'Fahrenheit (°F)';

  @override
  String get format24Hour => '24-hour format';

  @override
  String get decimalPlaces => 'Decimal places';

  @override
  String decimalPlacesValue(Object count) {
    return '$count decimal(s)';
  }

  @override
  String example(Object value) {
    return 'Ex: $value';
  }

  @override
  String get clearCache => 'Clear cache';

  @override
  String get clearCacheSubtitle => 'Deletes cached data';

  @override
  String get clearCacheConfirm => 'Clear cache?';

  @override
  String get clearCacheMessage =>
      'This action will delete all cached data. Data will be reloaded on the next connection.';

  @override
  String get clear => 'Clear';

  @override
  String get cacheCleared => 'Cache cleared successfully';

  @override
  String get exportConnections => 'Export connections';

  @override
  String get exportConnectionsSubtitle => 'Backup to JSON file';

  @override
  String exportError(Object error) {
    return 'Export error: $error';
  }

  @override
  String get importConnections => 'Import connections';

  @override
  String get importConnectionsSubtitle => 'Restore from JSON file';

  @override
  String importError(Object error) {
    return 'Import error: $error';
  }

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get resetSettings => 'Reset settings';

  @override
  String get resetSettingsSubtitle => 'Restore default values';

  @override
  String get resetConfirm => 'Reset?';

  @override
  String get resetMessage =>
      'All settings will be restored to their default values.';

  @override
  String get reset => 'Reset';

  @override
  String get settingsReset => 'Settings reset';

  @override
  String get ok => 'OK';

  @override
  String get eclypseManagement => 'ECLYPSE controller management app';

  @override
  String get supportsApiBacnet =>
      'Supports V1 and V2 APIs and BACnet/IP protocol.';

  @override
  String get invalidPointId => 'Invalid point ID';

  @override
  String get invalidInstance => 'Invalid instance';

  @override
  String unknownType(Object type) {
    return 'Unknown type: $type';
  }

  @override
  String get pointNotFound => 'Point not found';

  @override
  String pointNotFoundMessage(Object instance, Object type) {
    return 'Point $type:$instance not found';
  }

  @override
  String get reloadPoints => 'Reload points';

  @override
  String get alarm => 'ALARM';

  @override
  String forcedP(Object priority) {
    return 'Forced P$priority';
  }

  @override
  String get outOfService => 'Out of service';

  @override
  String get set => 'Set';

  @override
  String get force => 'Force';

  @override
  String get auto => 'Auto';

  @override
  String get forcingOutOfService => 'Forcing (out-of-service)';

  @override
  String get forcingPriority1 => 'Forcing (priority 1)';

  @override
  String get typeNotEditable => 'Type not editable';

  @override
  String get enterValue => 'Enter a value';

  @override
  String get invalidValue => 'Invalid value';

  @override
  String get state => 'State';

  @override
  String get enterState => 'Enter a state';

  @override
  String get invalidStateMin1 => 'Invalid state (min: 1)';

  @override
  String selectedState(Object state, Object value) {
    return 'Selected state: $state ($value)';
  }

  @override
  String get inProgress => 'In progress...';

  @override
  String get inputForced => 'Input forced (out-of-service)';

  @override
  String get valueSet => 'Value set';

  @override
  String get valueForcedPriority1 => 'Value forced (priority 1)';

  @override
  String get pointSetToAuto => 'Point set to Auto';

  @override
  String get errorSettingAuto => 'Error setting to Auto';

  @override
  String get writeError => 'Error writing value';

  @override
  String get pointInAlarm => 'Point in Alarm';

  @override
  String get alarmTriggeredMessage =>
      'This point triggered an alarm (status-flags.in-alarm = true).';

  @override
  String get pointForced => 'Point Forced';

  @override
  String get priority => 'Priority';

  @override
  String level(Object level) {
    return 'Level $level';
  }

  @override
  String get forcedValue => 'Forced value';

  @override
  String get release => 'Release';

  @override
  String get emergency => 'Emergency';

  @override
  String get inputForcedTitle => 'Input Forced';

  @override
  String get inputForcedMessage =>
      'This input is out of service (out-of-service = true).\nThe displayed value is manually forced.';

  @override
  String get releaseInput => 'Release input';

  @override
  String get inputReleased => 'Input released (out-of-service = false)';

  @override
  String get inputReleaseError => 'Error releasing input';

  @override
  String get overrideReleased => 'Override released';

  @override
  String get releaseError => 'Error releasing';

  @override
  String get emergencyRelease => 'Emergency release';

  @override
  String get emergencyReleaseMessage =>
      'This action will release ALL priorities (1-16) of the point.\n\nThe point will return to fully automatic mode.\n\nContinue?';

  @override
  String get releaseAll => 'Release all';

  @override
  String get allPrioritiesReleased => 'All priorities released';

  @override
  String get emergencyReleaseError => 'Error during emergency release';

  @override
  String get information => 'Information';

  @override
  String get name => 'Name';

  @override
  String get description => 'Description';

  @override
  String get identifier => 'Identifier';

  @override
  String get type => 'Type';

  @override
  String get instance => 'Instance';

  @override
  String get properties => 'Properties';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get loadingEllipsis => 'Loading...';

  @override
  String get modified => 'Modified';

  @override
  String get editMode => 'Edit mode';

  @override
  String get cancelChanges => 'Cancel changes';

  @override
  String get saveChanges => 'Save';

  @override
  String get closeEdit => 'Close edit';

  @override
  String get edit => 'Edit';

  @override
  String get scheduleNotFound => 'Schedule not found';

  @override
  String get errorLoadingSchedule => 'Error loading schedule';

  @override
  String get discardChanges => 'Discard changes';

  @override
  String get discardChangesMessage =>
      'You have unsaved changes. Do you want to discard them?';

  @override
  String get discard => 'Discard';

  @override
  String get keep => 'Keep';

  @override
  String get loadingPoints => 'Loading points...';

  @override
  String noResultsFor(Object query) {
    return 'No results for \"$query\"';
  }

  @override
  String get sort => 'Sort';

  @override
  String alarmsCount(Object count) {
    return '$count active alarm(s)';
  }

  @override
  String get searchAlarm => 'Search for an alarm...';

  @override
  String get searchPoint => 'Search for a point...';

  @override
  String get statisticsPoints => 'Points';

  @override
  String get statisticsMin => 'Min';

  @override
  String get statisticsMax => 'Max';

  @override
  String get statisticsAvg => 'Avg';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get minus15 => '-15';

  @override
  String get plus15 => '+15';

  @override
  String transitionAt(Object state, Object time) {
    return 'Transition at $time → $state';
  }

  @override
  String timeState(Object state, Object time) {
    return '$time : $state';
  }

  @override
  String currentState(Object state) {
    return 'Current: $state';
  }

  @override
  String instanceLabel(Object instance) {
    return 'Instance $instance';
  }

  @override
  String get allEquipmentNormal => 'All equipment is operating normally';

  @override
  String agoMinutes(Object count) {
    return '$count min ago';
  }

  @override
  String agoHours(Object count) {
    return '$count h ago';
  }

  @override
  String agoDays(Object count) {
    return '$count day(s) ago';
  }

  @override
  String get autoRefreshDisabled => 'Auto-refresh disabled';

  @override
  String autoRefreshLabel(Object label) {
    return 'Auto-refresh: $label';
  }

  @override
  String get loadingValuesProgress => 'Loading values in progress...';

  @override
  String get allPoints => 'All';

  @override
  String noPointSubType(Object subType) {
    return 'No $subType point';
  }

  @override
  String get noPointInCategory => 'No point in this category';

  @override
  String get trendLogAvailable => 'Trend log available';

  @override
  String get plannings => 'Schedules';

  @override
  String get loadingError => 'Loading error';

  @override
  String get noPlanning => 'No schedule';

  @override
  String get noScheduleConfigured =>
      'This controller has no configured schedules.';

  @override
  String get onOff => 'On/Off';

  @override
  String get multiState => 'Multi-state';

  @override
  String get boolean => 'Boolean';

  @override
  String scheduleInstance(Object instance) {
    return 'Schedule $instance';
  }

  @override
  String get editModeTapSlot => 'Edit mode - Tap on a slot';

  @override
  String get editModeTapDay => 'Edit mode - Tap on a day to modify';

  @override
  String get legend => 'Legend:';

  @override
  String selectedCount(Object count) {
    return '$count selected';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get selectionMode => 'Selection mode';

  @override
  String get newFolder => 'New folder';

  @override
  String get notConnected => 'Not connected';

  @override
  String get connectToViewFavorites =>
      'Connect to a controller to view your favorites';

  @override
  String get noFavorite => 'No favorite';

  @override
  String get addFavoritesHint =>
      'Add points to favorites by clicking\\nthe star in the points list';

  @override
  String get viewPoints => 'View points';

  @override
  String get assignToFolders => 'Assign to folders';

  @override
  String get deleteFavoritesConfirm => 'Delete favorites?';

  @override
  String deleteFavoritesMessage(Object count) {
    return 'Do you want to delete $count favorite(s)?';
  }

  @override
  String favoritesAssigned(Object favCount, Object folderCount) {
    return '$favCount favorite(s) assigned to $folderCount folder(s)';
  }

  @override
  String favoritesDeleted(Object count) {
    return '$count favorite(s) deleted';
  }

  @override
  String get createFolderFirst => 'Create a folder first';

  @override
  String get selectFoldersToAdd => 'Select the folders to add the favorites to';

  @override
  String get assign => 'Assign';

  @override
  String get dropHereToAdd => 'Drop here to add';

  @override
  String favoritesCount(Object count) {
    return '$count favorite(s)';
  }

  @override
  String get editFolder => 'Edit';

  @override
  String get deleteFolder => 'Delete';

  @override
  String get emptyFolderHint => 'Empty folder - drag favorites here';

  @override
  String get noFolder => 'No folder';

  @override
  String get deleteFolderConfirm => 'Delete the folder?';

  @override
  String deleteFolderMessage(Object name) {
    return 'The folder \"$name\" will be deleted.\\n\\nFavorites in it won\'t be deleted, they will be moved to \"No folder\".';
  }

  @override
  String get favoriteAddedToFolder => 'Favorite added to folder';

  @override
  String removedFromFavorites(Object name) {
    return '$name removed from favorites';
  }

  @override
  String get assignToFoldersDialog => 'Assign to folders';

  @override
  String get categoryInputs => 'Inputs';

  @override
  String get categoryOutputs => 'Outputs';

  @override
  String get categoryVariables => 'Values';

  @override
  String get categoryOthers => 'Others';

  @override
  String get categoryAll => 'All';

  @override
  String get sortNameAsc => 'Name (A→Z)';

  @override
  String get sortNameDesc => 'Name (Z→A)';

  @override
  String get sortType => 'Type';

  @override
  String get sortValueAsc => 'Value ↑';

  @override
  String get sortValueDesc => 'Value ↓';

  @override
  String get sortFavoritesFirst => 'Favorites first';

  @override
  String get subTypeAll => 'All';

  @override
  String get subTypeAnalog => 'Analog';

  @override
  String get subTypeBinary => 'Binary';

  @override
  String get subTypeMulti => 'Multi';

  @override
  String get autoRefreshOff => 'Off';

  @override
  String autoRefreshSeconds(Object count) {
    return '$count seconds';
  }

  @override
  String get autoRefreshMinute => '1 minute';

  @override
  String get noOverride => 'No overrides';

  @override
  String get allPointsNormal => 'All points are operating normally';

  @override
  String get outOfServiceLabel => 'Out of service';

  @override
  String get forcedLabel => 'Forced';

  @override
  String priorityLabel(Object priority) {
    return 'Priority $priority';
  }

  @override
  String get bacnetLocalNetworkOnly => 'Local network only';

  @override
  String get bacnetLocalNetworkInfo =>
      'BACnet/IP only works on the local network. Make sure your device is connected to the same network as the controller.';

  @override
  String get bacnetDeviceIdOptional => 'Device ID (optional on local network)';

  @override
  String get bacnetDeviceIdHelper =>
      'Leave empty for automatic discovery on local network';

  @override
  String get bacnetDeviceIdRemoteRequired =>
      'Required if not on the same network';

  @override
  String get discoverDevices => 'Discover devices';

  @override
  String get discovering => 'Searching...';

  @override
  String get noDeviceFound => 'No BACnet device found';

  @override
  String get noDeviceFoundMessage =>
      'No BACnet device responded on the local network.\n\nCheck that:\n• You are on the same network as the controller\n• UDP port 47808 is not blocked\n• The controller is powered on and accessible';

  @override
  String devicesFound(Object count) {
    return '$count device(s) found';
  }

  @override
  String get selectDevice => 'Select a device';

  @override
  String get deviceId => 'Device ID';

  @override
  String get vendor => 'Vendor';

  @override
  String get model => 'Model';

  @override
  String get bacnetPortHelper => 'BACnet/IP port (default: 47808)';

  @override
  String get broadcastDiscovery => 'Broadcast discovery';

  @override
  String get broadcastDiscoverySubtitle =>
      'Search for all BACnet devices on local network';

  @override
  String get discoverEclypse => 'Discover ECLYPSE';

  @override
  String get discoverEclypseSubtitle => 'mDNS search for Distech controllers';

  @override
  String eclypseFound(Object count) {
    return '$count ECLYPSE found';
  }

  @override
  String get scanIpRange => 'Scan IP range';

  @override
  String get scanIpRangeSubtitle => 'Unicast scan to find ECLYPSE and others';

  @override
  String get startIp => 'Start IP';

  @override
  String get endIp => 'End IP';

  @override
  String scanProgress(Object current, Object total) {
    return 'Scanning... $current/$total';
  }

  @override
  String get scanning => 'Scanning...';

  @override
  String get stopScan => 'Stop';

  @override
  String get invalidIpRange => 'Invalid IP range';

  @override
  String get ipRangeSameSubnet => 'IPs must be on the same /24 subnet';

  @override
  String get scanComplete => 'Scan complete';

  @override
  String get orManualEntry => 'or manual entry:';

  @override
  String get useIpScan => 'Scan IP range (ECLYPSE)';
}
