import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/database_provider.dart';
import '../providers/folder_providers.dart';
import '../../data/database/app_database.dart';

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

/// Provider pour SharedPreferences
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider principal des paramètres
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref);
});

/// Notifier pour gérer les paramètres
class SettingsNotifier extends StateNotifier<AppSettings> {
  SharedPreferences? _prefs;

  SettingsNotifier(Ref ref) : super(const AppSettings()) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }

  void _loadSettings() {
    if (_prefs == null) return;

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
    state = state.copyWith(themeMode: mode);
    await _prefs?.setInt(SettingsKeys.themeMode, mode.index);
  }

  Future<void> setLocale(String locale) async {
    state = state.copyWith(locale: locale);
    await _prefs?.setString(SettingsKeys.locale, locale);
  }

  Future<void> setConnectionTimeout(int seconds) async {
    state = state.copyWith(connectionTimeoutSeconds: seconds);
    await _prefs?.setInt(SettingsKeys.connectionTimeout, seconds);
  }

  Future<void> setRefreshInterval(int seconds) async {
    state = state.copyWith(refreshIntervalSeconds: seconds);
    await _prefs?.setInt(SettingsKeys.refreshInterval, seconds);
  }

  Future<void> setDefaultBacnetPort(int port) async {
    state = state.copyWith(defaultBacnetPort: port);
    await _prefs?.setInt(SettingsKeys.defaultBacnetPort, port);
  }

  Future<void> setTemperatureUnit(String unit) async {
    state = state.copyWith(temperatureUnit: unit);
    await _prefs?.setString(SettingsKeys.temperatureUnit, unit);
  }

  Future<void> setUse24HourFormat(bool use24Hour) async {
    state = state.copyWith(use24HourFormat: use24Hour);
    await _prefs?.setBool(SettingsKeys.use24HourFormat, use24Hour);
  }

  Future<void> setDecimalPlaces(int places) async {
    state = state.copyWith(decimalPlaces: places);
    await _prefs?.setInt(SettingsKeys.decimalPlaces, places);
  }

  /// Réinitialise tous les paramètres aux valeurs par défaut
  Future<void> resetToDefaults() async {
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
    final connections = await db.allConnections;
    final folders = await db.allFolders;

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
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final db = _ref.read(databaseProvider);

      int foldersImported = 0;
      int connectionsImported = 0;
      int connectionsSkipped = 0;
      final errors = <String>[];

      // Mapping des noms de dossiers vers leurs IDs
      final folderNameToId = <String, int>{};

      // Importer les dossiers
      final foldersData = data['folders'] as List<dynamic>? ?? [];
      for (final folderData in foldersData) {
        try {
          final name = folderData['name'] as String;
          // Vérifier si le dossier existe déjà
          final existingFolders = await db.allFolders;
          final existing = existingFolders.where((f) => f.name == name).firstOrNull;

          if (existing != null) {
            folderNameToId[name] = existing.id;
          } else {
            final id = await db.insertFolder(FoldersCompanion.insert(
              name: name,
              icon: Value(folderData['icon'] as String? ?? 'folder'),
              color: Value(folderData['color'] as String? ?? 'blue'),
              sortOrder: Value(folderData['sortOrder'] as int? ?? 0),
            ));
            folderNameToId[name] = id;
            foldersImported++;
          }
        } catch (e) {
          errors.add('Erreur dossier: $e');
        }
      }

      // Importer les connexions
      final connectionsData = data['connections'] as List<dynamic>? ?? [];
      for (final connData in connectionsData) {
        try {
          final host = connData['host'] as String;
          final port = connData['port'] as int;

          // Vérifier si la connexion existe déjà (même host:port)
          final existingConnections = await db.allConnections;
          final existing = existingConnections.where(
            (c) => c.host == host && c.port == port
          ).firstOrNull;

          if (existing != null) {
            connectionsSkipped++;
            continue;
          }

          // Trouver l'ID du dossier
          final folderName = connData['folderName'] as String?;
          final folderId = (folderName != null && folderNameToId.containsKey(folderName))
              ? folderNameToId[folderName]
              : null;

          await db.insertConnection(ConnectionsCompanion.insert(
            name: connData['name'] as String,
            host: host,
            port: Value(port),
            useHttps: Value(connData['useHttps'] as bool? ?? true),
            username: connData['username'] as String? ?? '',
            passwordKey: '', // L'utilisateur devra ressaisir le mot de passe
            connectionType: Value(connData['connectionType'] as String? ?? 'api'),
            folderId: Value(folderId),
          ));
          connectionsImported++;
        } catch (e) {
          errors.add('Erreur connexion: $e');
        }
      }

      // Rafraîchir les providers
      _ref.invalidate(foldersStreamProvider);

      return ImportResult(
        success: true,
        foldersImported: foldersImported,
        connectionsImported: connectionsImported,
        connectionsSkipped: connectionsSkipped,
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
}

/// Résultat d'une importation
class ImportResult {
  final bool success;
  final int foldersImported;
  final int connectionsImported;
  final int connectionsSkipped;
  final List<String> errors;

  const ImportResult({
    required this.success,
    required this.foldersImported,
    required this.connectionsImported,
    required this.connectionsSkipped,
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
    return parts.isEmpty ? 'Rien à importer' : 'Importé: ${parts.join(', ')}';
  }
}

/// Extension pour la base de données
extension AppDatabaseCacheExtension on AppDatabase {
  /// Vide tout le cache global
  Future<void> clearAllCacheGlobal() async {
    await delete(cachedPoints).go();
    await delete(cachedDeviceInfo).go();
    await delete(cachedObjectsSummary).go();
    // Note: cachedTrendLogMappings fait partie du même cache
  }

  /// Obtient les statistiques globales du cache
  Future<({int totalPoints, int totalDevices})> getGlobalCacheStats() async {
    final pointsList = await select(cachedPoints).get();
    final devicesList = await select(cachedDeviceInfo).get();
    return (totalPoints: pointsList.length, totalDevices: devicesList.length);
  }

  /// Récupère tous les dossiers
  Future<List<Folder>> get allFolders => select(folders).get();

  /// Récupère toutes les connexions
  Future<List<Connection>> get allConnections => select(connections).get();
}
