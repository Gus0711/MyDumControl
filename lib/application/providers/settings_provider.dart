import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/connection_providers.dart';
import '../providers/database_provider.dart';
import '../providers/folder_providers.dart';
import '../../data/database/app_database.dart';
import '../../domain/models/display_preferences.dart';

/// Clés pour SharedPreferences
class SettingsKeys {
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String connectionTimeout = 'connection_timeout';
  static const String refreshInterval = 'refresh_interval';
  static const String defaultBacnetPort = 'default_bacnet_port';
  static const String temperatureUnit = 'temperature_unit';
  static const String use24HourFormat = 'use_24_hour_format';
  static const String decimalPlaces = 'decimal_places';
}

/// État des paramètres de l'application
class AppSettings {
  final ThemeMode themeMode;
  final String locale;
  final int connectionTimeoutSeconds;
  final int refreshIntervalSeconds; // 0 = désactivé
  final int defaultBacnetPort;
  final String temperatureUnit; // 'celsius' ou 'fahrenheit'
  final bool use24HourFormat;
  final int decimalPlaces;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.locale = 'fr',
    this.connectionTimeoutSeconds = 10,
    this.refreshIntervalSeconds = 0,
    this.defaultBacnetPort = 47808,
    this.temperatureUnit = 'celsius',
    this.use24HourFormat = true,
    this.decimalPlaces = 2,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? locale,
    int? connectionTimeoutSeconds,
    int? refreshIntervalSeconds,
    int? defaultBacnetPort,
    String? temperatureUnit,
    bool? use24HourFormat,
    int? decimalPlaces,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      connectionTimeoutSeconds: connectionTimeoutSeconds ?? this.connectionTimeoutSeconds,
      refreshIntervalSeconds: refreshIntervalSeconds ?? this.refreshIntervalSeconds,
      defaultBacnetPort: defaultBacnetPort ?? this.defaultBacnetPort,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      decimalPlaces: decimalPlaces ?? this.decimalPlaces,
    );
  }
}

/// Provider principal des paramètres
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref);
});

/// Notifier pour gérer les paramètres
class SettingsNotifier extends StateNotifier<AppSettings> {
  SharedPreferences? _prefs;

  /// Completes once preferences are loaded. Setters await it so a value set
  /// early is neither lost (no-op write) nor overwritten by the initial load.
  late final Future<void> _ready;

  SettingsNotifier(Ref ref) : super(const AppSettings()) {
    // Keep the display preferences read by the models in sync
    addListener((s) => DisplayPreferences.apply(
          decimalPlaces: s.decimalPlaces,
          temperatureUnit: s.temperatureUnit,
          use24HourFormat: s.use24HourFormat,
        ));
    _ready = _init();
  }

  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadSettings();
    } catch (e) {
      debugPrint('SettingsNotifier: failed to load preferences: $e');
    }
  }

  void _loadSettings() {
    if (_prefs == null || !mounted) return;

    final themeModeIndex = _prefs!.getInt(SettingsKeys.themeMode) ?? 0;
    final themeMode = ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)];

    state = AppSettings(
      themeMode: themeMode,
      locale: _prefs!.getString(SettingsKeys.locale) ?? 'fr',
      connectionTimeoutSeconds: _prefs!.getInt(SettingsKeys.connectionTimeout) ?? 10,
      refreshIntervalSeconds: _prefs!.getInt(SettingsKeys.refreshInterval) ?? 0,
      defaultBacnetPort: _prefs!.getInt(SettingsKeys.defaultBacnetPort) ?? 47808,
      temperatureUnit: _prefs!.getString(SettingsKeys.temperatureUnit) ?? 'celsius',
      use24HourFormat: _prefs!.getBool(SettingsKeys.use24HourFormat) ?? true,
      decimalPlaces: _prefs!.getInt(SettingsKeys.decimalPlaces) ?? 2,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _ready;
    if (!mounted) return;
    state = state.copyWith(themeMode: mode);
    await _prefs?.setInt(SettingsKeys.themeMode, mode.index);
  }

  Future<void> setLocale(String locale) async {
    await _ready;
    if (!mounted) return;
    state = state.copyWith(locale: locale);
    await _prefs?.setString(SettingsKeys.locale, locale);
  }

  Future<void> setConnectionTimeout(int seconds) async {
    await _ready;
    if (!mounted) return;
    state = state.copyWith(connectionTimeoutSeconds: seconds);
    await _prefs?.setInt(SettingsKeys.connectionTimeout, seconds);
  }

  Future<void> setRefreshInterval(int seconds) async {
    await _ready;
    if (!mounted) return;
    state = state.copyWith(refreshIntervalSeconds: seconds);
    await _prefs?.setInt(SettingsKeys.refreshInterval, seconds);
  }

  Future<void> setDefaultBacnetPort(int port) async {
    await _ready;
    if (!mounted) return;
    state = state.copyWith(defaultBacnetPort: port);
    await _prefs?.setInt(SettingsKeys.defaultBacnetPort, port);
  }

  Future<void> setTemperatureUnit(String unit) async {
    await _ready;
    if (!mounted) return;
    state = state.copyWith(temperatureUnit: unit);
    await _prefs?.setString(SettingsKeys.temperatureUnit, unit);
  }

  Future<void> setUse24HourFormat(bool use24Hour) async {
    await _ready;
    if (!mounted) return;
    state = state.copyWith(use24HourFormat: use24Hour);
    await _prefs?.setBool(SettingsKeys.use24HourFormat, use24Hour);
  }

  Future<void> setDecimalPlaces(int places) async {
    await _ready;
    if (!mounted) return;
    state = state.copyWith(decimalPlaces: places);
    await _prefs?.setInt(SettingsKeys.decimalPlaces, places);
  }

  /// Réinitialise tous les paramètres aux valeurs par défaut
  Future<void> resetToDefaults() async {
    await _ready;
    if (!mounted) return;
    state = const AppSettings();
    await _prefs?.remove(SettingsKeys.themeMode);
    await _prefs?.remove(SettingsKeys.locale);
    await _prefs?.remove(SettingsKeys.connectionTimeout);
    await _prefs?.remove(SettingsKeys.refreshInterval);
    await _prefs?.remove(SettingsKeys.defaultBacnetPort);
    await _prefs?.remove(SettingsKeys.temperatureUnit);
    await _prefs?.remove(SettingsKeys.use24HourFormat);
    await _prefs?.remove(SettingsKeys.decimalPlaces);
  }
}

/// Provider pour les opérations de cache
final cacheOperationsProvider = Provider((ref) => CacheOperations(ref));

class CacheOperations {
  final Ref _ref;

  CacheOperations(this._ref);

  /// Vide tout le cache de l'application
  Future<void> clearAllCache() async {
    final db = _ref.read(databaseProvider);
    // Vider les caches pour toutes les connexions
    await db.clearAllCacheGlobal();
  }

  /// Obtient la taille estimée du cache
  Future<String> getCacheSize() async {
    final db = _ref.read(databaseProvider);
    final stats = await db.getGlobalCacheStats();
    return '${stats.totalPoints} points, ${stats.totalDevices} appareils';
  }
}

/// Provider pour l'export/import des données
final dataExportProvider = Provider((ref) => DataExportService(ref));

class DataExportService {
  final Ref _ref;

  DataExportService(this._ref);

  /// Exporte toutes les connexions et dossiers en JSON
  Future<String> exportConnectionsToJson() async {
    final db = _ref.read(databaseProvider);

    // Récupérer les données
    final connections = await db.getAllConnections();
    final folders = await db.getAllFolders();

    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'folders': folders.map((f) => {
        'name': f.name,
        'icon': f.icon,
        'color': f.color,
        'sortOrder': f.sortOrder,
      }).toList(),
      'connections': connections.map((c) => {
        'name': c.name,
        'host': c.host,
        'port': c.port,
        'useHttps': c.useHttps,
        'username': c.username,
        // Note: On n'exporte pas le mot de passe pour des raisons de sécurité
        'apiVersion': c.apiVersion,
        'connectionType': c.connectionType,
        'bacnetDeviceId': c.bacnetDeviceId,
        'designerUrl': c.designerUrl,
        'folderName': folders.where((f) => f.id == c.folderId).firstOrNull?.name,
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Exporte et partage le fichier
  Future<void> exportAndShare() async {
    final json = await exportConnectionsToJson();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${tempDir.path}/mydumcontrol_export_$timestamp.json');
    await file.writeAsString(json);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Export MyDumControl',
      text: 'Sauvegarde des connexions MyDumControl',
    );
  }

  /// Importe les connexions depuis un JSON
  Future<ImportResult> importConnectionsFromJson(String jsonString) async {
    final db = _ref.read(databaseProvider);
    final result = await importConnectionsData(db, jsonString);
    // Rafraîchir les providers
    _ref.invalidate(foldersStreamProvider);
    return result;
  }
}

/// Normalizes a connection type read from an export ('api' or unknown values
/// from older exports map to 'distech_api').
String normalizeImportedConnectionType(String? type) =>
    type == 'bacnet' ? 'bacnet' : 'distech_api';

/// Imports folders and connections from an export JSON into [db].
///
/// Runs in a single transaction. Each imported connection gets its own unique
/// passwordKey; no secret is written, so Distech API connections need their
/// password to be entered again (counted in [ImportResult.connectionsNeedingPassword]).
Future<ImportResult> importConnectionsData(AppDatabase db, String jsonString) async {
  try {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;

    int foldersImported = 0;
    int connectionsImported = 0;
    int connectionsSkipped = 0;
    int connectionsNeedingPassword = 0;
    final errors = <String>[];

    await db.transaction(() async {
      // Load existing data once (no N+1 queries)
      final folderNameToId = <String, int>{
        for (final f in await db.getAllFolders()) f.name: f.id,
      };
      final existingTargets = <String>{
        for (final c in await db.getAllConnections())
          _connectionDedupKey(c.host, c.port, c.connectionType),
      };

      // Importer les dossiers
      final foldersData = data['folders'] as List<dynamic>? ?? [];
      for (final folderData in foldersData) {
        try {
          final name = (folderData['name'] as String?)?.trim() ?? '';
          if (name.isEmpty) {
            errors.add('Erreur dossier: nom manquant');
            continue;
          }
          if (folderNameToId.containsKey(name)) continue;

          final id = await db.insertFolder(FoldersCompanion.insert(
            name: name,
            icon: Value(folderData['icon'] as String? ?? 'folder'),
            color: Value(folderData['color'] as String? ?? '#2196F3'),
            sortOrder: Value(folderData['sortOrder'] as int? ?? 0),
          ));
          folderNameToId[name] = id;
          foldersImported++;
        } on Object catch (e) {
          // Dart-side errors only (bad JSON types, Drift validation):
          // no SQL statement failed, so the transaction stays usable.
          if (e is! TypeError && e is! InvalidDataException) rethrow;
          errors.add('Erreur dossier: $e');
        }
      }

      // Importer les connexions
      final connectionsData = data['connections'] as List<dynamic>? ?? [];
      for (final connData in connectionsData) {
        try {
          final name = (connData['name'] as String?)?.trim() ?? '';
          final host = (connData['host'] as String?)?.trim() ?? '';
          final port = connData['port'] as int;
          final connectionType =
              normalizeImportedConnectionType(connData['connectionType'] as String?);
          final isBacnet = connectionType == 'bacnet';
          var username = (connData['username'] as String?)?.trim() ?? '';
          if (username.isEmpty && isBacnet) username = 'bacnet';

          if (name.isEmpty || host.isEmpty || username.isEmpty) {
            errors.add('Erreur connexion: champ manquant (${name.isEmpty ? host : name})');
            continue;
          }

          // Vérifier si la connexion existe déjà (même host:port:type)
          final key = _connectionDedupKey(host, port, connectionType);
          if (existingTargets.contains(key)) {
            connectionsSkipped++;
            continue;
          }

          // Trouver l'ID du dossier
          final folderName = connData['folderName'] as String?;
          final folderId = folderName != null ? folderNameToId[folderName] : null;

          await db.insertConnection(ConnectionsCompanion.insert(
            name: name,
            host: host,
            port: Value(port),
            useHttps: Value(connData['useHttps'] as bool? ?? true),
            username: username,
            // Unique key per connection; the password itself is never exported
            passwordKey: generatePasswordKey(),
            apiVersion: Value(connData['apiVersion'] as String?),
            connectionType: Value(connectionType),
            bacnetDeviceId: Value(connData['bacnetDeviceId'] as int?),
            designerUrl: Value(connData['designerUrl'] as String?),
            folderId: Value(folderId),
          ));
          existingTargets.add(key);
          connectionsImported++;
          if (!isBacnet) connectionsNeedingPassword++;
        } on Object catch (e) {
          if (e is! TypeError && e is! InvalidDataException) rethrow;
          errors.add('Erreur connexion: $e');
        }
      }
    });

    return ImportResult(
      success: true,
      foldersImported: foldersImported,
      connectionsImported: connectionsImported,
      connectionsSkipped: connectionsSkipped,
      connectionsNeedingPassword: connectionsNeedingPassword,
      errors: errors,
    );
  } catch (e) {
    return ImportResult(
      success: false,
      foldersImported: 0,
      connectionsImported: 0,
      connectionsSkipped: 0,
      errors: ['Erreur de parsing: $e'],
    );
  }
}

String _connectionDedupKey(String host, int port, String connectionType) =>
    '${host.toLowerCase()}:$port:$connectionType';

/// Résultat d'une importation
class ImportResult {
  final bool success;
  final int foldersImported;
  final int connectionsImported;
  final int connectionsSkipped;

  /// Imported Distech API connections whose password must be entered again
  /// (passwords are never exported).
  final int connectionsNeedingPassword;
  final List<String> errors;

  const ImportResult({
    required this.success,
    required this.foldersImported,
    required this.connectionsImported,
    required this.connectionsSkipped,
    this.connectionsNeedingPassword = 0,
    required this.errors,
  });

  String get summary {
    if (!success) {
      return 'Échec de l\'importation: ${errors.join(', ')}';
    }
    final parts = <String>[];
    if (foldersImported > 0) parts.add('$foldersImported dossier(s)');
    if (connectionsImported > 0) parts.add('$connectionsImported connexion(s)');
    if (connectionsSkipped > 0) parts.add('$connectionsSkipped ignorée(s)');
    if (parts.isEmpty) return 'Rien à importer';
    final summary = 'Importé: ${parts.join(', ')}';
    if (connectionsNeedingPassword > 0) {
      return '$summary. Mot de passe à ressaisir (modifier la connexion) '
          'pour $connectionsNeedingPassword connexion(s)';
    }
    return summary;
  }
}
