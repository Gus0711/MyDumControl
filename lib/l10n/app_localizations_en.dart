// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MyGlobalDC';

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
  String scheduleStateN(int value) {
    return 'State $value';
  }

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
  String get editDescription => 'Edit description';

  @override
  String get descriptionHint => 'Enter a description...';

  @override
  String get descriptionUpdated => 'Description updated';

  @override
  String get descriptionUpdateError => 'Error updating description';

  @override
  String get noDescription => 'No description';

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
  String get weeklyScheduleUnreadable =>
      'Weekly program unreadable: editing disabled so as not to overwrite the controller';

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

  @override
  String get dashboards => 'Dashboards';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get noDashboard => 'No dashboard';

  @override
  String get createDashboardHint =>
      'Create dashboards to visualize\nyour graphs and history curves';

  @override
  String get createDashboard => 'Create dashboard';

  @override
  String get newDashboard => 'New dashboard';

  @override
  String get editDashboard => 'Edit dashboard';

  @override
  String get deleteDashboard => 'Delete dashboard';

  @override
  String get dashboardName => 'Dashboard name';

  @override
  String get dashboardNameRequired => 'Name is required';

  @override
  String get deleteDashboardConfirm => 'Delete this dashboard?';

  @override
  String deleteDashboardMessage(Object name) {
    return 'Dashboard \"$name\" and all its widgets will be deleted.';
  }

  @override
  String get dashboardDeleted => 'Dashboard deleted';

  @override
  String widgets(Object count) {
    return '$count widget(s)';
  }

  @override
  String get addWidget => 'Add widget';

  @override
  String get configureWidget => 'Configure widget';

  @override
  String get deleteWidget => 'Delete widget';

  @override
  String get widgetDeleted => 'Widget deleted';

  @override
  String get singleChart => 'Simple chart';

  @override
  String get singleChartDescription => 'Displays the history of a single point';

  @override
  String get multiCurveChart => 'Multi-curves';

  @override
  String get multiCurveChartDescription =>
      'Compare multiple points on the same graph';

  @override
  String get statsCard => 'Statistics';

  @override
  String get statsCardDescription => 'Displays min, max and average of a point';

  @override
  String get selectTrendLog => 'Select a trend log';

  @override
  String get noTrendLogSelected => 'No trend log selected';

  @override
  String get selectTrendLogs => 'Select trend logs';

  @override
  String selectedTrendLogs(Object count) {
    return '$count trend log(s) selected';
  }

  @override
  String get minCurvesRequired => 'Select at least 2 trend logs';

  @override
  String get maxCurvesReached => 'Maximum 8 curves allowed';

  @override
  String get showMin => 'Show minimum';

  @override
  String get showMax => 'Show maximum';

  @override
  String get showAvg => 'Show average';

  @override
  String get curveVisibility => 'Curve visibility';

  @override
  String get periodDay => 'Day';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String get networkInterface => 'Network interface';

  @override
  String get allInterfaces => 'All interfaces';

  @override
  String get searchingBacnetDevices => 'Searching for BACnet devices...';

  @override
  String get deviceIdConflict => 'Device ID Conflict';

  @override
  String get deviceIdConflictMessage =>
      'Multiple devices share the same BACnet Device ID. This is prohibited by the protocol and may cause malfunctions.';

  @override
  String get conflictingAddresses => 'Conflicting IP addresses:';

  @override
  String get conflictRecommendation =>
      'Recommended action: Reconfigure devices to have unique Device IDs.';

  @override
  String get understood => 'Understood';

  @override
  String get idConflict => 'ID conflict';

  @override
  String get alsoAt => 'Also at';

  @override
  String get conflicts => 'conflict(s)';

  @override
  String bacnetPortWarning(int actualPort, int standardPort) {
    return 'Port $actualPort in use (standard: $standardPort)';
  }

  @override
  String get bacnetPortConflict => 'BACnet port conflict';

  @override
  String bacnetPortConflictDetail(int standardPort, int actualPort) {
    return 'The standard BACnet port ($standardPort) is already in use by another application. The app is using port $actualPort instead.';
  }

  @override
  String get bacnetPortConflictSolution => 'Solutions:';

  @override
  String get bacnetPortSolution1 => 'Close YABE or other BACnet applications';

  @override
  String get bacnetPortSolution2 => 'Restart this application';

  @override
  String get envysionDesignerSection => 'Envysion Synoptic (optional)';

  @override
  String get designerUrl => 'Designer URL';

  @override
  String get designerUrlHelper =>
      'Path to the Envysion viewer embedded in the controller';

  @override
  String get synopticEnvysion => 'Envysion Synoptic';

  @override
  String get synopticLocal => 'Local Synoptics';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get webViewNotSupported => 'WebView not supported on this platform';

  @override
  String webViewNotSupportedMessage(Object platform) {
    return 'Embedded display is not available on $platform. Do you want to open in external browser?';
  }

  @override
  String get loadingEnvysion => 'Loading synoptic...';

  @override
  String get envysionLoadError => 'Loading error';

  @override
  String get envysionLoadErrorMessage =>
      'Unable to load Envysion synoptic. Check the URL and your connection.';

  @override
  String get certificateChangedTitle => 'Controller certificate changed';

  @override
  String get trustNewCertificate => 'Trust the new certificate';

  @override
  String trustNewCertificateMessage(String expected, String received) {
    return 'The certificate presented by the controller differs from the one saved on the first connection.\n\nThis may come from a certificate renewal (firmware update, controller reset) or from traffic interception. Only trust the new certificate if you are sure it is legitimate.\n\nExpected fingerprint:\n$expected\n\nNew fingerprint:\n$received';
  }

  @override
  String get trust => 'Trust';

  @override
  String get backToConnections => 'Back to connections';

  @override
  String get certificateFingerprintLabel => 'Certificate fingerprint (SHA-256)';

  @override
  String get certificateFingerprintDiffers =>
      'Differs from the saved fingerprint: the controller certificate changed.';

  @override
  String get certificateFingerprintPinnedInfo =>
      'It will be saved and checked on every connection.';

  @override
  String get httpCleartextWarning =>
      'Unencrypted HTTP: the password is sent in clear text on the network. Prefer HTTPS if the controller supports it.';

  @override
  String get passwordMissingBadge => 'Password required';

  @override
  String invalidCredentialsMessage(String status) {
    return 'Invalid credentials ($status). Check the connection user name and password.';
  }

  @override
  String get close => 'Close';

  @override
  String get add => 'Add';

  @override
  String get rename => 'Rename';

  @override
  String get create => 'Create';

  @override
  String get apply => 'Apply';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get back => 'Back';

  @override
  String get copy => 'Copy';

  @override
  String get clearAction => 'Clear';

  @override
  String get validate => 'Validate';

  @override
  String get details => 'Details';

  @override
  String get unknown => 'Unknown';

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get trendColorBlue => 'Blue';

  @override
  String get trendColorGreen => 'Green';

  @override
  String get trendColorOrange => 'Orange';

  @override
  String get trendColorPurple => 'Purple';

  @override
  String get trendColorRed => 'Red';

  @override
  String get trendColorCyan => 'Cyan';

  @override
  String get trendColorTeal => 'Teal';

  @override
  String get trendColorIndigo => 'Indigo';

  @override
  String get trendPeriodHour => '1h';

  @override
  String get trendPeriodDay => '24h';

  @override
  String get trendPeriodWeek => '7d';

  @override
  String get trendPeriodMonth => '30d';

  @override
  String get trendPeriodAll => 'All';

  @override
  String get trendPeriodCustom => 'Custom';

  @override
  String get trendChangeColor => 'Change color';

  @override
  String get trendAnnotations => 'Annotations';

  @override
  String get trendMinMaxMarkers => 'Min/Max markers';

  @override
  String get trendAverageLine => 'Average line';

  @override
  String get trendMinLine => 'Minimum line';

  @override
  String get trendMaxLine => 'Maximum line';

  @override
  String get trendHideAll => 'Hide all';

  @override
  String get trendNoDataForPeriod => 'No data for this period';

  @override
  String get trendDateTime => 'Date/Time';

  @override
  String get trendHistory => 'History';

  @override
  String get trendFullscreen => 'Full screen';

  @override
  String get trendShowChart => 'Show chart';

  @override
  String get trendShowTable => 'Show table';

  @override
  String get trendExportCsv => 'Export CSV';

  @override
  String trendExportSubject(String name) {
    return 'History export $name';
  }

  @override
  String get trendPortraitMode => 'Portrait mode';

  @override
  String get trendLandscapeMode => 'Landscape mode';

  @override
  String get trendNoNumericData => 'No numeric data';

  @override
  String get trendNoDataToDisplay => 'No data to display';

  @override
  String get trendInvalidData => 'Invalid data';

  @override
  String trendAvgLineLabel(String value) {
    return 'Avg: $value';
  }

  @override
  String chartComparisonTitle(int count) {
    return 'Comparison ($count curves)';
  }

  @override
  String get chartAddCurve => 'Add a curve';

  @override
  String chartCurvesNotLoaded(int count) {
    return '$count curve(s) not loaded';
  }

  @override
  String get chartNoVisibleCurve =>
      'No visible curve\nTap the legend to show one';

  @override
  String get chartNoCurveSelected =>
      'No curve selected\nAdd trend logs to compare';

  @override
  String get chartSelectCurves => 'Select curves';

  @override
  String chartSelectCurvesHint(int min, int max) {
    return 'Select $min to $max trend logs to compare';
  }

  @override
  String chartCurvesCount(int selected, int max) {
    return '$selected/$max curves';
  }

  @override
  String get chartNoTrendLogAvailable => 'No trend log available';

  @override
  String get chartSelectedCurves => 'Selected curves:';

  @override
  String chartValidateCount(int count) {
    return 'Confirm ($count)';
  }

  @override
  String get widgetPromoteSuperFavorite => 'Promote to super favorite';

  @override
  String get widgetDemoteToFavorite => 'Demote to favorite';

  @override
  String get widgetNoFolder => 'No folder';

  @override
  String get widgetCreateFolder => 'Create a folder';

  @override
  String get widgetNewFolderEllipsis => 'New folder...';

  @override
  String get widgetEditFolder => 'Edit folder';

  @override
  String get widgetFolderName => 'Folder name';

  @override
  String get widgetColor => 'Color';

  @override
  String get widgetIcon => 'Icon';

  @override
  String get widgetConnecting => 'Connecting';

  @override
  String get widgetStepAuth => 'Auth';

  @override
  String get widgetPumpLabel => 'PUMP';

  @override
  String get synopticsTitle => 'Synoptics';

  @override
  String get synopticCreate => 'Create a synoptic';

  @override
  String get synopticEmptyTitle => 'No synoptics';

  @override
  String get synopticEmptyHint =>
      'Create your first synoptic to display\nyour points on a graphical diagram';

  @override
  String get synopticDeleteTitle => 'Delete synoptic?';

  @override
  String synopticDeleteMessage(String name) {
    return 'Are you sure you want to delete \"$name\"?\nThis action cannot be undone.';
  }

  @override
  String synopticBindingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bindings',
      one: '1 binding',
      zero: '0 bindings',
    );
    return '$_temp0';
  }

  @override
  String get synopticBindingsUnknown => '-- bindings';

  @override
  String get synopticGlobal => 'Global';

  @override
  String get synopticEditBindings => 'Edit bindings';

  @override
  String get synopticNew => 'New synoptic';

  @override
  String get synopticSvgModel => 'SVG template';

  @override
  String synopticConfigurableElementsCount(int count) {
    return '$count configurable elements';
  }

  @override
  String get synopticNameLabel => 'Synoptic name';

  @override
  String get synopticNameHint => 'E.g.: Ground floor heating circuit';

  @override
  String get synopticDescriptionOptional => 'Description (optional)';

  @override
  String get synopticDefaultName => 'Synoptic';

  @override
  String get synopticResetZoom => 'Reset zoom';

  @override
  String get synopticNotFound => 'Synoptic not found';

  @override
  String synopticUpdateError(String error) {
    return 'Update error: $error';
  }

  @override
  String synopticActivePointsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active points',
      one: '1 active point',
      zero: '0 active points',
    );
    return '$_temp0';
  }

  @override
  String get synopticPinchToZoom => 'Pinch to zoom';

  @override
  String get synopticSvgElement => 'SVG element';

  @override
  String get synopticBindingType => 'Binding type';

  @override
  String get synopticCurrentValue => 'Current value';

  @override
  String get synopticViewPoint => 'View point';

  @override
  String get synopticNumericValue => 'Numeric value';

  @override
  String get synopticColorIndicator => 'Color indicator';

  @override
  String get synopticAnimation => 'Animation';

  @override
  String synopticEditTitle(String name) {
    return 'Edit: $name';
  }

  @override
  String get synopticHelp => 'Help';

  @override
  String get synopticPreview => 'Synoptic preview';

  @override
  String get synopticConfigurableElements => 'Configurable elements';

  @override
  String get synopticNoConfigurableElements =>
      'No configurable elements detected';

  @override
  String get synopticHowToConfigure => 'How to configure';

  @override
  String get synopticHelpSteps =>
      '1. Select an element in the list\n2. Choose the BACnet point to bind\n3. Configure the binding type:\n   • Value: displays the point value\n   • Color: changes the color based on the state\n   • Animation: enables/disables an animation\n4. Customize the format if needed';

  @override
  String get synopticStateIndicator => 'State indicator';

  @override
  String get synopticElement => 'Element';

  @override
  String get synopticConfigureBinding => 'Configure binding';

  @override
  String get synopticDeleteBinding => 'Delete binding';

  @override
  String get synopticColor => 'Color';

  @override
  String get synopticDisplayFormat => 'Display format';

  @override
  String synopticFormatHint(String placeholder) {
    return 'E.g.: $placeholder°C or $placeholder%';
  }

  @override
  String synopticFormatHelper(String placeholder) {
    return 'Use $placeholder for the point value';
  }

  @override
  String get synopticColors => 'Colors';

  @override
  String get synopticAnimationConfig => 'Animation settings';

  @override
  String get synopticAnimationOnOff => 'Animation ON/OFF';

  @override
  String get synopticAnimationExplanation =>
      'The animation is visible when the point value is > threshold (active), and hidden otherwise.';

  @override
  String get synopticThreshold => 'ON/OFF threshold';

  @override
  String get synopticThresholdHelper =>
      'Value > threshold = ON, otherwise OFF (for boolean: 0.5)';

  @override
  String get synopticBacnetPoint => 'BACnet point';

  @override
  String get synopticNoPointFound => 'No point found';

  @override
  String get synopticDeleteBindingTitle => 'Delete binding?';

  @override
  String get synopticIrreversible => 'This action cannot be undone.';

  @override
  String get envysionConnectionNotFound => 'Connection not found';

  @override
  String get envysionAuthFailed => 'Authentication failed (401)';

  @override
  String get envysionPageNotFound => 'Page not found (404)';

  @override
  String get dashboardNotFound => 'Dashboard not found';

  @override
  String get dashboardDeleteWidgetConfirm => 'Delete widget?';

  @override
  String get dashboardDeleteWidgetMessage =>
      'This widget will be removed from the dashboard.';

  @override
  String get dashboardEditTitle => 'Edit title';

  @override
  String get dashboardTitleLabel => 'Title';

  @override
  String get dashboardTitleHint => 'Leave empty for the default title';

  @override
  String get dashboardSettingsTitle => 'Dashboard settings';

  @override
  String get dashboardColumnsWithColon => 'Columns: ';

  @override
  String get dashboardRowsWithColon => 'Rows: ';

  @override
  String get dashboardDeletePermanentMessage =>
      'This dashboard and all its widgets will be permanently deleted.';

  @override
  String get dashboardSearchHint => 'Search...';

  @override
  String get dashboardNewShort => 'New';

  @override
  String get dashboardEmptyHint =>
      'Create your first dashboard to view\nseveral charts on a single page.';

  @override
  String dashboardGridSize(int columns, int rows) {
    return 'Grid ${columns}x$rows';
  }

  @override
  String get dashboardNameHint => 'E.g. Heating, Ventilation...';

  @override
  String get dashboardGridLayout => 'Grid layout';

  @override
  String get dashboardColumns => 'Columns';

  @override
  String get dashboardRows => 'Rows';

  @override
  String get dashboardChartDefault => 'Chart';

  @override
  String dashboardComparisonTitle(int count) {
    return 'Comparison ($count curves)';
  }

  @override
  String get dashboardNotConfigured => 'Not configured';

  @override
  String get dashboardConfigure => 'Configure';

  @override
  String get deviceInfoProtocol => 'Protocol';

  @override
  String get deviceInfoUser => 'User';

  @override
  String get deviceInfoLastConnection => 'Last connection';

  @override
  String get deviceInfoNetwork => 'Network';

  @override
  String deviceInfoInterfacesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count interfaces',
      one: '1 interface',
    );
    return '$_temp0';
  }

  @override
  String get deviceInfoIpAddress => 'IP address';

  @override
  String get deviceInfoSubnetMask => 'Subnet mask';

  @override
  String get deviceInfoGateway => 'Gateway';

  @override
  String get deviceInfoPrimaryDns => 'Primary DNS';

  @override
  String get deviceInfoMacAddress => 'MAC address';

  @override
  String deviceInfoCopied(String label) {
    return '$label copied';
  }

  @override
  String get deviceInfoBacnetObjects => 'BACnet objects';

  @override
  String deviceInfoTotalObjects(int count) {
    return 'Total: $count objects';
  }

  @override
  String get deviceInfoNoDataAvailable => 'No data available';

  @override
  String get deviceInfoTechnical => 'Technical information';

  @override
  String get deviceInfoHostName => 'Host name';

  @override
  String get homeAuthenticating => 'Authenticating...';

  @override
  String get homeFetchingData => 'Fetching data...';

  @override
  String get homeSynoptic => 'Synoptic';

  @override
  String homeControllerTimeTooltip(String time) {
    return 'Controller time: $time';
  }

  @override
  String homeTimeOffsetTooltip(String offset) {
    return 'Offset: $offset';
  }

  @override
  String get homeControllerTimeTitle => 'Controller time';

  @override
  String get homeControllerDateTime => 'Controller date/time';

  @override
  String get homeLocalTime => 'Local time';

  @override
  String get homeTimeOffset => 'Offset';

  @override
  String get homeTimeOffsetWarning =>
      'The controller clock is off. Schedules may not run at the expected times.';

  @override
  String get homeSyncV2Info =>
      'API V2: use the EC-NetAX web interface or configure NTP to synchronize the time.';

  @override
  String get homeSyncSuccess => 'Time synchronized successfully!';

  @override
  String get homeSyncFailed => 'Synchronization failed.';

  @override
  String get homeSyncing => 'Synchronizing...';

  @override
  String get homeSync => 'Synchronize';

  @override
  String routerPageNotFound(String path) {
    return 'Page not found: $path';
  }

  @override
  String routerInvalidId(String id) {
    return 'Invalid identifier: \"$id\"';
  }

  @override
  String connectionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count connections',
      one: '1 connection',
      zero: '0 connections',
    );
    return '$_temp0';
  }

  @override
  String get connectionsEmptyFolder => 'Empty folder';

  @override
  String get connectionsFolderName => 'Folder name';

  @override
  String get connectionsEditFolder => 'Edit folder';

  @override
  String get connectionsDeleteFolder => 'Delete folder';

  @override
  String connectionsDeleteFolderMessage(String name) {
    return 'Do you want to delete the folder \"$name\"?\n\nThe connections it contains will be moved to the root.';
  }

  @override
  String connectionsFolderDeleted(String name) {
    return 'Folder \"$name\" deleted';
  }

  @override
  String connectionsDeleteConfirm(String name) {
    return 'Do you want to delete \"$name\"?';
  }

  @override
  String connectionsDeleted(String name) {
    return 'Connection \"$name\" deleted';
  }

  @override
  String get connectionsMoveTo => 'Move to';

  @override
  String get connectionsMoved => 'Connection moved';

  @override
  String get connectionsAddToStart => 'Add a connection to get started';

  @override
  String get connectionsMove => 'Move';

  @override
  String get connectionsRefreshFolderTooltip =>
      'Refresh all super favorites in the folder';

  @override
  String get connectionsRefreshValuesTooltip => 'Refresh values';

  @override
  String addConnSelected(String name) {
    return '$name selected';
  }

  @override
  String get addConnUseSecure => 'Use a secure connection';

  @override
  String get addConnConnectionType => 'Connection type';

  @override
  String addConnBacnetSuccess(String deviceId) {
    return 'BACnet connection successful! Device ID: $deviceId';
  }

  @override
  String get addConnNotDiscovered => 'not discovered';

  @override
  String get addConnBacnetFailed => 'BACnet connection failed';

  @override
  String get addConnUpdated => 'Connection updated';

  @override
  String get addConnSaved => 'Connection saved';

  @override
  String get discoverMdnsError => 'mDNS error';

  @override
  String get discoverSearchingEclypse =>
      'Searching for ECLYPSE controllers on the network...';

  @override
  String get discoverNoEclypseFoundMessage =>
      'No ECLYPSE was found on the network.\nCheck that you are connected to the same network as the controller.';

  @override
  String discoverDeviceIdConflictWithId(String deviceId) {
    return 'Device ID conflict $deviceId';
  }

  @override
  String get alarmsSortNewest => 'Newest first';

  @override
  String get alarmsSortOldest => 'Oldest first';

  @override
  String get bacnetTypeAnalogInput => 'Analog Input';

  @override
  String get bacnetTypeAnalogOutput => 'Analog Output';

  @override
  String get bacnetTypeAnalogValue => 'Analog Value';

  @override
  String get bacnetTypeBinaryInput => 'Binary Input';

  @override
  String get bacnetTypeBinaryOutput => 'Binary Output';

  @override
  String get bacnetTypeBinaryValue => 'Binary Value';

  @override
  String get bacnetTypeMultiStateInput => 'Multi-state Input';

  @override
  String get bacnetTypeMultiStateOutput => 'Multi-state Output';

  @override
  String get bacnetTypeMultiStateValue => 'Multi-state Value';

  @override
  String get bacnetTypeSchedule => 'Schedule';

  @override
  String get bacnetTypeCalendar => 'Calendar';

  @override
  String get bacnetTypeTrendLog => 'Trend log';

  @override
  String get bacnetTypeNotificationClass => 'Notification class';

  @override
  String get bacnetTypeDevice => 'Device';

  @override
  String get scheduleDayShortMonday => 'Mon';

  @override
  String get scheduleDayShortTuesday => 'Tue';

  @override
  String get scheduleDayShortWednesday => 'Wed';

  @override
  String get scheduleDayShortThursday => 'Thu';

  @override
  String get scheduleDayShortFriday => 'Fri';

  @override
  String get scheduleDayShortSaturday => 'Sat';

  @override
  String get scheduleDayShortSunday => 'Sun';

  @override
  String get scheduleNewSlot => 'New time slot';

  @override
  String get scheduleEditSlot => 'Edit time slot';

  @override
  String get scheduleNewTransition => 'New transition';

  @override
  String get scheduleAllDay => 'All day';

  @override
  String get scheduleStartTime => 'Start time';

  @override
  String get scheduleEndTime => 'End time';

  @override
  String get scheduleTime => 'Time';

  @override
  String get scheduleEndAfterStartError => 'End time must be after start time';

  @override
  String scheduleDuration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get scheduleSelectTime => 'Select time';

  @override
  String get scheduleMidnightEndOfDay => 'Midnight (end of day)';

  @override
  String get scheduleCopyDay => 'Copy this day';

  @override
  String schedulePasteHereFrom(String day) {
    return 'Paste here (from $day)';
  }

  @override
  String schedulePasteFrom(String day) {
    return 'Paste from $day';
  }

  @override
  String get schedulePasteToWorkDays => 'Paste to weekdays';

  @override
  String get scheduleWorkDaysRange => 'Mon-Fri';

  @override
  String get schedulePasteToAllDays => 'Paste to all days';

  @override
  String get scheduleClearDay => 'Clear this day';

  @override
  String scheduleDayCopied(String day) {
    return '$day copied';
  }

  @override
  String get schedulePastedToWorkDays => 'Pasted to weekdays';

  @override
  String get schedulePastedToAllDays => 'Pasted to all days';

  @override
  String get scheduleMoreActions => 'More actions';

  @override
  String get scheduleSaveConfirmTitle => 'Save schedule?';

  @override
  String get scheduleSaveConfirmMessage =>
      'Changes will be sent to the controller and take effect immediately.';

  @override
  String get scheduleDiscardConfirmTitle => 'Discard changes?';

  @override
  String get scheduleDiscardConfirmMessage =>
      'All unsaved changes will be lost.';

  @override
  String get scheduleContinueEditing => 'Keep editing';

  @override
  String get scheduleDeleteTransitionTitle => 'Delete this transition?';

  @override
  String get scheduleDeleteSlotTitle => 'Delete this time slot?';

  @override
  String get scheduleNoTransition => 'No transition';

  @override
  String get scheduleNoScheduledTransition => 'No scheduled transition';

  @override
  String get scheduleTapPlusToAdd => 'Tap + to add';

  @override
  String get scheduleAddSlot => 'Add time slot';

  @override
  String get scheduleFullDay => 'All day';

  @override
  String scheduleEditDayTitle(String day) {
    return 'Edit - $day';
  }

  @override
  String scheduleAddDayTitle(String day) {
    return 'Add - $day';
  }
}
