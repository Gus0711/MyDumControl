import 'package:drift/drift.dart';
import 'folders_table.dart';

/// Table des connexions sauvegardées
class Connections extends Table {
  /// Identifiant unique
  IntColumn get id => integer().autoIncrement()();

  /// Dossier parent (null = racine)
  IntColumn get folderId => integer().nullable().references(Folders, #id)();

  /// Nom de la connexion (affiché dans la liste)
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Hôte (IP ou hostname)
  TextColumn get host => text().withLength(min: 1, max: 255)();

  /// Port
  IntColumn get port => integer().withDefault(const Constant(443))();

  /// Utiliser HTTPS (ignoré si connectionType = 'bacnet')
  BoolColumn get useHttps => boolean().withDefault(const Constant(true))();

  /// Nom d'utilisateur (ignoré si connectionType = 'bacnet')
  TextColumn get username => text().withLength(min: 1, max: 100)();

  /// Mot de passe (sera chiffré via flutter_secure_storage séparément)
  /// Ici on stocke juste une référence/clé (ignoré si connectionType = 'bacnet')
  TextColumn get passwordKey => text().withLength(min: 1, max: 100)();

  /// Version de l'API détectée (v1, v2, ou null si pas encore testé)
  /// Pour BACnet, contiendra la version du protocole si disponible
  TextColumn get apiVersion => text().nullable()();

  /// Empreinte du certificat (pour TOFU) - API Distech uniquement
  TextColumn get certificateFingerprint => text().nullable()();

  /// Type de connexion : 'distech_api' (défaut) ou 'bacnet'
  TextColumn get connectionType =>
      text().withDefault(const Constant('distech_api'))();

  /// Device ID BACnet (instance number du device object)
  /// Utilisé pour adresser un device spécifique (ex: via routeur BACnet)
  /// Null = auto-détection ou device unique
  IntColumn get bacnetDeviceId => integer().nullable()();

  /// Date de création
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Date de dernière modification
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Dernière connexion réussie
  DateTimeColumn get lastConnectedAt => dateTime().nullable()();
}
