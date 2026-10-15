import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
  ];

  /// Titre de l'application
  ///
  /// In fr, this message translates to:
  /// **'MyGlobalDC'**
  String get appTitle;

  /// Titre de la page des connexions
  ///
  /// In fr, this message translates to:
  /// **'Connexions'**
  String get connections;

  /// No description provided for @addConnection.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une connexion'**
  String get addConnection;

  /// No description provided for @editConnection.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la connexion'**
  String get editConnection;

  /// No description provided for @deleteConnection.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la connexion'**
  String get deleteConnection;

  /// No description provided for @connectionName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la connexion'**
  String get connectionName;

  /// No description provided for @host.
  ///
  /// In fr, this message translates to:
  /// **'Hôte'**
  String get host;

  /// No description provided for @port.
  ///
  /// In fr, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @username.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get username;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @connect.
  ///
  /// In fr, this message translates to:
  /// **'Connecter'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecter'**
  String get disconnect;

  /// No description provided for @testConnection.
  ///
  /// In fr, this message translates to:
  /// **'Tester la connexion'**
  String get testConnection;

  /// No description provided for @connectionSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Connexion réussie'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la connexion'**
  String get connectionFailed;

  /// No description provided for @noConnections.
  ///
  /// In fr, this message translates to:
  /// **'Aucune connexion enregistrée'**
  String get noConnections;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @points.
  ///
  /// In fr, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @physicalInputs.
  ///
  /// In fr, this message translates to:
  /// **'Entrées physiques'**
  String get physicalInputs;

  /// No description provided for @physicalOutputs.
  ///
  /// In fr, this message translates to:
  /// **'Sorties physiques'**
  String get physicalOutputs;

  /// No description provided for @analogValues.
  ///
  /// In fr, this message translates to:
  /// **'Valeurs analogiques'**
  String get analogValues;

  /// No description provided for @alarms.
  ///
  /// In fr, this message translates to:
  /// **'Alarmes'**
  String get alarms;

  /// No description provided for @activeAlarms.
  ///
  /// In fr, this message translates to:
  /// **'Alarmes actives'**
  String get activeAlarms;

  /// No description provided for @noAlarms.
  ///
  /// In fr, this message translates to:
  /// **'Aucune alarme active'**
  String get noAlarms;

  /// No description provided for @acknowledge.
  ///
  /// In fr, this message translates to:
  /// **'Acquitter'**
  String get acknowledge;

  /// No description provided for @schedules.
  ///
  /// In fr, this message translates to:
  /// **'Horaires'**
  String get schedules;

  /// No description provided for @overrides.
  ///
  /// In fr, this message translates to:
  /// **'Forçages'**
  String get overrides;

  /// No description provided for @favorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favorites;

  /// No description provided for @addToFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get removeFromFavorites;

  /// No description provided for @pidLoops.
  ///
  /// In fr, this message translates to:
  /// **'Boucles PID'**
  String get pidLoops;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @deviceInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations appareil'**
  String get deviceInfo;

  /// No description provided for @appSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de l\'application'**
  String get appSettings;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode clair'**
  String get lightMode;

  /// No description provided for @systemMode.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get systemMode;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @version.
  ///
  /// In fr, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @noData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée'**
  String get noData;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @connected.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In fr, this message translates to:
  /// **'Déconnecté'**
  String get disconnected;

  /// No description provided for @connecting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion en cours...'**
  String get connecting;

  /// No description provided for @apiVersion.
  ///
  /// In fr, this message translates to:
  /// **'Version API'**
  String get apiVersion;

  /// No description provided for @autoDetect.
  ///
  /// In fr, this message translates to:
  /// **'Détection automatique'**
  String get autoDetect;

  /// No description provided for @certificateWarning.
  ///
  /// In fr, this message translates to:
  /// **'Certificat auto-signé'**
  String get certificateWarning;

  /// No description provided for @trustCertificate.
  ///
  /// In fr, this message translates to:
  /// **'Faire confiance à ce certificat'**
  String get trustCertificate;

  /// No description provided for @certificateDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails du certificat'**
  String get certificateDetails;

  /// No description provided for @fingerprint.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte'**
  String get fingerprint;

  /// No description provided for @value.
  ///
  /// In fr, this message translates to:
  /// **'Valeur'**
  String get value;

  /// No description provided for @unit.
  ///
  /// In fr, this message translates to:
  /// **'Unité'**
  String get unit;

  /// No description provided for @status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// No description provided for @lastUpdate.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour'**
  String get lastUpdate;

  /// No description provided for @writeValue.
  ///
  /// In fr, this message translates to:
  /// **'Écrire une valeur'**
  String get writeValue;

  /// No description provided for @overrideValue.
  ///
  /// In fr, this message translates to:
  /// **'Forcer la valeur'**
  String get overrideValue;

  /// No description provided for @releaseOverride.
  ///
  /// In fr, this message translates to:
  /// **'Libérer le forçage'**
  String get releaseOverride;

  /// No description provided for @monday.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In fr, this message translates to:
  /// **'Mardi'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In fr, this message translates to:
  /// **'Mercredi'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get sunday;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la suppression'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cet élément ?'**
  String get deleteConfirmMessage;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est requis'**
  String get fieldRequired;

  /// No description provided for @invalidHost.
  ///
  /// In fr, this message translates to:
  /// **'Hôte invalide'**
  String get invalidHost;

  /// No description provided for @invalidPort.
  ///
  /// In fr, this message translates to:
  /// **'Port invalide (1-65535)'**
  String get invalidPort;

  /// No description provided for @offline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get offline;

  /// No description provided for @online.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get online;

  /// No description provided for @appearance.
  ///
  /// In fr, this message translates to:
  /// **'Apparence'**
  String get appearance;

  /// No description provided for @connection.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get connection;

  /// No description provided for @display.
  ///
  /// In fr, this message translates to:
  /// **'Affichage'**
  String get display;

  /// No description provided for @data.
  ///
  /// In fr, this message translates to:
  /// **'Données'**
  String get data;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système (auto)'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get themeDark;

  /// No description provided for @connectionTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Timeout de connexion'**
  String get connectionTimeout;

  /// No description provided for @seconds.
  ///
  /// In fr, this message translates to:
  /// **'secondes'**
  String get seconds;

  /// No description provided for @secondsValue.
  ///
  /// In fr, this message translates to:
  /// **'{count} secondes'**
  String secondsValue(Object count);

  /// No description provided for @autoRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Rafraîchissement auto'**
  String get autoRefresh;

  /// No description provided for @disabled.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get disabled;

  /// No description provided for @everySeconds.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les {count} secondes'**
  String everySeconds(Object count);

  /// No description provided for @defaultBacnetPort.
  ///
  /// In fr, this message translates to:
  /// **'Port BACnet par défaut'**
  String get defaultBacnetPort;

  /// No description provided for @temperatureUnit.
  ///
  /// In fr, this message translates to:
  /// **'Unité de température'**
  String get temperatureUnit;

  /// No description provided for @celsius.
  ///
  /// In fr, this message translates to:
  /// **'Celsius (°C)'**
  String get celsius;

  /// No description provided for @fahrenheit.
  ///
  /// In fr, this message translates to:
  /// **'Fahrenheit (°F)'**
  String get fahrenheit;

  /// No description provided for @format24Hour.
  ///
  /// In fr, this message translates to:
  /// **'Format 24 heures'**
  String get format24Hour;

  /// No description provided for @decimalPlaces.
  ///
  /// In fr, this message translates to:
  /// **'Décimales affichées'**
  String get decimalPlaces;

  /// No description provided for @decimalPlacesValue.
  ///
  /// In fr, this message translates to:
  /// **'{count} décimale(s)'**
  String decimalPlacesValue(Object count);

  /// No description provided for @example.
  ///
  /// In fr, this message translates to:
  /// **'Ex: {value}'**
  String example(Object value);

  /// No description provided for @clearCache.
  ///
  /// In fr, this message translates to:
  /// **'Vider le cache'**
  String get clearCache;

  /// No description provided for @clearCacheSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprime les données mises en cache'**
  String get clearCacheSubtitle;

  /// No description provided for @clearCacheConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Vider le cache ?'**
  String get clearCacheConfirm;

  /// No description provided for @clearCacheMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette action supprimera toutes les données en cache. Les données seront rechargées lors de la prochaine connexion.'**
  String get clearCacheMessage;

  /// No description provided for @clear.
  ///
  /// In fr, this message translates to:
  /// **'Vider'**
  String get clear;

  /// No description provided for @cacheCleared.
  ///
  /// In fr, this message translates to:
  /// **'Cache vidé avec succès'**
  String get cacheCleared;

  /// No description provided for @exportConnections.
  ///
  /// In fr, this message translates to:
  /// **'Exporter les connexions'**
  String get exportConnections;

  /// No description provided for @exportConnectionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde en fichier JSON'**
  String get exportConnectionsSubtitle;

  /// No description provided for @exportError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'export: {error}'**
  String exportError(Object error);

  /// No description provided for @importConnections.
  ///
  /// In fr, this message translates to:
  /// **'Importer des connexions'**
  String get importConnections;

  /// No description provided for @importConnectionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer depuis un fichier JSON'**
  String get importConnectionsSubtitle;

  /// No description provided for @importError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'import: {error}'**
  String importError(Object error);

  /// No description provided for @openSourceLicenses.
  ///
  /// In fr, this message translates to:
  /// **'Licences open source'**
  String get openSourceLicenses;

  /// No description provided for @resetSettings.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser les paramètres'**
  String get resetSettings;

  /// No description provided for @resetSettingsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rétablit les valeurs par défaut'**
  String get resetSettingsSubtitle;

  /// No description provided for @resetConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser ?'**
  String get resetConfirm;

  /// No description provided for @resetMessage.
  ///
  /// In fr, this message translates to:
  /// **'Tous les paramètres seront remis à leurs valeurs par défaut.'**
  String get resetMessage;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @settingsReset.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres réinitialisés'**
  String get settingsReset;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @eclypseManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des automates ECLYPSE'**
  String get eclypseManagement;

  /// No description provided for @supportsApiBacnet.
  ///
  /// In fr, this message translates to:
  /// **'Supporte les API V1 et V2 ainsi que le protocole BACnet/IP.'**
  String get supportsApiBacnet;

  /// No description provided for @invalidPointId.
  ///
  /// In fr, this message translates to:
  /// **'ID de point invalide'**
  String get invalidPointId;

  /// No description provided for @invalidInstance.
  ///
  /// In fr, this message translates to:
  /// **'Instance invalide'**
  String get invalidInstance;

  /// No description provided for @unknownType.
  ///
  /// In fr, this message translates to:
  /// **'Type inconnu: {type}'**
  String unknownType(Object type);

  /// No description provided for @pointNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Point non trouvé'**
  String get pointNotFound;

  /// No description provided for @pointNotFoundMessage.
  ///
  /// In fr, this message translates to:
  /// **'Point {type}:{instance} non trouvé'**
  String pointNotFoundMessage(Object instance, Object type);

  /// No description provided for @reloadPoints.
  ///
  /// In fr, this message translates to:
  /// **'Recharger les points'**
  String get reloadPoints;

  /// No description provided for @alarm.
  ///
  /// In fr, this message translates to:
  /// **'ALARME'**
  String get alarm;

  /// No description provided for @forcedP.
  ///
  /// In fr, this message translates to:
  /// **'Forcé P{priority}'**
  String forcedP(Object priority);

  /// No description provided for @outOfService.
  ///
  /// In fr, this message translates to:
  /// **'Hors service'**
  String get outOfService;

  /// No description provided for @set.
  ///
  /// In fr, this message translates to:
  /// **'Régler'**
  String get set;

  /// No description provided for @force.
  ///
  /// In fr, this message translates to:
  /// **'Forcer'**
  String get force;

  /// No description provided for @auto.
  ///
  /// In fr, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @forcingOutOfService.
  ///
  /// In fr, this message translates to:
  /// **'Forçage (out-of-service)'**
  String get forcingOutOfService;

  /// No description provided for @forcingPriority1.
  ///
  /// In fr, this message translates to:
  /// **'Forçage (priorité 1)'**
  String get forcingPriority1;

  /// No description provided for @typeNotEditable.
  ///
  /// In fr, this message translates to:
  /// **'Type non éditable'**
  String get typeNotEditable;

  /// No description provided for @enterValue.
  ///
  /// In fr, this message translates to:
  /// **'Entrez une valeur'**
  String get enterValue;

  /// No description provided for @invalidValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur invalide'**
  String get invalidValue;

  /// No description provided for @state.
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get state;

  /// No description provided for @scheduleStateN.
  ///
  /// In fr, this message translates to:
  /// **'État {value}'**
  String scheduleStateN(int value);

  /// No description provided for @enterState.
  ///
  /// In fr, this message translates to:
  /// **'Entrez un état'**
  String get enterState;

  /// No description provided for @invalidStateMin1.
  ///
  /// In fr, this message translates to:
  /// **'État invalide (min: 1)'**
  String get invalidStateMin1;

  /// No description provided for @selectedState.
  ///
  /// In fr, this message translates to:
  /// **'État sélectionné: {state} ({value})'**
  String selectedState(Object state, Object value);

  /// No description provided for @inProgress.
  ///
  /// In fr, this message translates to:
  /// **'En cours...'**
  String get inProgress;

  /// No description provided for @inputForced.
  ///
  /// In fr, this message translates to:
  /// **'Entrée forcée (out-of-service)'**
  String get inputForced;

  /// No description provided for @valueSet.
  ///
  /// In fr, this message translates to:
  /// **'Valeur réglée'**
  String get valueSet;

  /// No description provided for @valueForcedPriority1.
  ///
  /// In fr, this message translates to:
  /// **'Valeur forcée (priorité 1)'**
  String get valueForcedPriority1;

  /// No description provided for @pointSetToAuto.
  ///
  /// In fr, this message translates to:
  /// **'Point remis en Auto'**
  String get pointSetToAuto;

  /// No description provided for @errorSettingAuto.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise en Auto'**
  String get errorSettingAuto;

  /// No description provided for @writeError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'écriture'**
  String get writeError;

  /// No description provided for @pointInAlarm.
  ///
  /// In fr, this message translates to:
  /// **'Point en Alarme'**
  String get pointInAlarm;

  /// No description provided for @alarmTriggeredMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ce point a déclenché une alarme (status-flags.in-alarm = true).'**
  String get alarmTriggeredMessage;

  /// No description provided for @pointForced.
  ///
  /// In fr, this message translates to:
  /// **'Point Forcé'**
  String get pointForced;

  /// No description provided for @priority.
  ///
  /// In fr, this message translates to:
  /// **'Priorité'**
  String get priority;

  /// No description provided for @level.
  ///
  /// In fr, this message translates to:
  /// **'Niveau {level}'**
  String level(Object level);

  /// No description provided for @forcedValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur forcée'**
  String get forcedValue;

  /// No description provided for @release.
  ///
  /// In fr, this message translates to:
  /// **'Libérer'**
  String get release;

  /// No description provided for @emergency.
  ///
  /// In fr, this message translates to:
  /// **'Urgence'**
  String get emergency;

  /// No description provided for @inputForcedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Entrée Forcée'**
  String get inputForcedTitle;

  /// No description provided for @inputForcedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette entrée est hors service (out-of-service = true).\nLa valeur affichée est forcée manuellement.'**
  String get inputForcedMessage;

  /// No description provided for @releaseInput.
  ///
  /// In fr, this message translates to:
  /// **'Libérer l\'entrée'**
  String get releaseInput;

  /// No description provided for @inputReleased.
  ///
  /// In fr, this message translates to:
  /// **'Entrée libérée (out-of-service = false)'**
  String get inputReleased;

  /// No description provided for @inputReleaseError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la libération de l\'entrée'**
  String get inputReleaseError;

  /// No description provided for @overrideReleased.
  ///
  /// In fr, this message translates to:
  /// **'Forçage libéré'**
  String get overrideReleased;

  /// No description provided for @releaseError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la libération'**
  String get releaseError;

  /// No description provided for @emergencyRelease.
  ///
  /// In fr, this message translates to:
  /// **'Libération d\'urgence'**
  String get emergencyRelease;

  /// No description provided for @emergencyReleaseMessage.
  ///
  /// In fr, this message translates to:
  /// **'Cette action va libérer TOUTES les priorités (1-16) du point.\n\nLe point retournera en mode complètement automatique.\n\nContinuer ?'**
  String get emergencyReleaseMessage;

  /// No description provided for @releaseAll.
  ///
  /// In fr, this message translates to:
  /// **'Libérer tout'**
  String get releaseAll;

  /// No description provided for @allPrioritiesReleased.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les priorités libérées'**
  String get allPrioritiesReleased;

  /// No description provided for @emergencyReleaseError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la libération d\'urgence'**
  String get emergencyReleaseError;

  /// No description provided for @information.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get information;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @identifier.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant'**
  String get identifier;

  /// No description provided for @type.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @instance.
  ///
  /// In fr, this message translates to:
  /// **'Instance'**
  String get instance;

  /// No description provided for @properties.
  ///
  /// In fr, this message translates to:
  /// **'Propriétés'**
  String get properties;

  /// No description provided for @active.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get inactive;

  /// No description provided for @editDescription.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la description'**
  String get editDescription;

  /// No description provided for @descriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez une description...'**
  String get descriptionHint;

  /// No description provided for @descriptionUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Description mise à jour'**
  String get descriptionUpdated;

  /// No description provided for @descriptionUpdateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour'**
  String get descriptionUpdateError;

  /// No description provided for @noDescription.
  ///
  /// In fr, this message translates to:
  /// **'Aucune description'**
  String get noDescription;

  /// No description provided for @loadingEllipsis.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loadingEllipsis;

  /// No description provided for @modified.
  ///
  /// In fr, this message translates to:
  /// **'Modifié'**
  String get modified;

  /// No description provided for @editMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode édition'**
  String get editMode;

  /// No description provided for @cancelChanges.
  ///
  /// In fr, this message translates to:
  /// **'Annuler les modifications'**
  String get cancelChanges;

  /// No description provided for @saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder'**
  String get saveChanges;

  /// No description provided for @closeEdit.
  ///
  /// In fr, this message translates to:
  /// **'Fermer l\'édition'**
  String get closeEdit;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @scheduleNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Schedule non trouvé'**
  String get scheduleNotFound;

  /// No description provided for @weeklyScheduleUnreadable.
  ///
  /// In fr, this message translates to:
  /// **'Programme hebdomadaire illisible : modification désactivée pour ne pas écraser l\'automate'**
  String get weeklyScheduleUnreadable;

  /// No description provided for @errorLoadingSchedule.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement'**
  String get errorLoadingSchedule;

  /// No description provided for @discardChanges.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner les modifications'**
  String get discardChanges;

  /// No description provided for @discardChangesMessage.
  ///
  /// In fr, this message translates to:
  /// **'Vous avez des modifications non sauvegardées. Voulez-vous les abandonner ?'**
  String get discardChangesMessage;

  /// No description provided for @discard.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner'**
  String get discard;

  /// No description provided for @keep.
  ///
  /// In fr, this message translates to:
  /// **'Garder'**
  String get keep;

  /// No description provided for @loadingPoints.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des points...'**
  String get loadingPoints;

  /// No description provided for @noResultsFor.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat pour \"{query}\"'**
  String noResultsFor(Object query);

  /// No description provided for @sort.
  ///
  /// In fr, this message translates to:
  /// **'Trier'**
  String get sort;

  /// No description provided for @alarmsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} alarme(s) active(s)'**
  String alarmsCount(Object count);

  /// No description provided for @searchAlarm.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une alarme...'**
  String get searchAlarm;

  /// No description provided for @searchPoint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un point...'**
  String get searchPoint;

  /// No description provided for @statisticsPoints.
  ///
  /// In fr, this message translates to:
  /// **'Points'**
  String get statisticsPoints;

  /// No description provided for @statisticsMin.
  ///
  /// In fr, this message translates to:
  /// **'Min'**
  String get statisticsMin;

  /// No description provided for @statisticsMax.
  ///
  /// In fr, this message translates to:
  /// **'Max'**
  String get statisticsMax;

  /// No description provided for @statisticsAvg.
  ///
  /// In fr, this message translates to:
  /// **'Moy'**
  String get statisticsAvg;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get start;

  /// No description provided for @end.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get end;

  /// No description provided for @minus15.
  ///
  /// In fr, this message translates to:
  /// **'-15'**
  String get minus15;

  /// No description provided for @plus15.
  ///
  /// In fr, this message translates to:
  /// **'+15'**
  String get plus15;

  /// No description provided for @transitionAt.
  ///
  /// In fr, this message translates to:
  /// **'Transition à {time} → {state}'**
  String transitionAt(Object state, Object time);

  /// No description provided for @timeState.
  ///
  /// In fr, this message translates to:
  /// **'{time} : {state}'**
  String timeState(Object state, Object time);

  /// No description provided for @currentState.
  ///
  /// In fr, this message translates to:
  /// **'Actuel: {state}'**
  String currentState(Object state);

  /// No description provided for @instanceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Instance {instance}'**
  String instanceLabel(Object instance);

  /// No description provided for @allEquipmentNormal.
  ///
  /// In fr, this message translates to:
  /// **'Tous les équipements fonctionnent normalement'**
  String get allEquipmentNormal;

  /// No description provided for @agoMinutes.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} min'**
  String agoMinutes(Object count);

  /// No description provided for @agoHours.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} h'**
  String agoHours(Object count);

  /// No description provided for @agoDays.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} jour(s)'**
  String agoDays(Object count);

  /// No description provided for @autoRefreshDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Auto-refresh désactivé'**
  String get autoRefreshDisabled;

  /// No description provided for @autoRefreshLabel.
  ///
  /// In fr, this message translates to:
  /// **'Auto-refresh: {label}'**
  String autoRefreshLabel(Object label);

  /// No description provided for @loadingValuesProgress.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des valeurs en cours...'**
  String get loadingValuesProgress;

  /// No description provided for @allPoints.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get allPoints;

  /// No description provided for @noPointSubType.
  ///
  /// In fr, this message translates to:
  /// **'Aucun point {subType}'**
  String noPointSubType(Object subType);

  /// No description provided for @noPointInCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun point dans cette catégorie'**
  String get noPointInCategory;

  /// No description provided for @trendLogAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Trend log disponible'**
  String get trendLogAvailable;

  /// No description provided for @plannings.
  ///
  /// In fr, this message translates to:
  /// **'Plannings'**
  String get plannings;

  /// No description provided for @loadingError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get loadingError;

  /// No description provided for @noPlanning.
  ///
  /// In fr, this message translates to:
  /// **'Aucun planning'**
  String get noPlanning;

  /// No description provided for @noScheduleConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Cet automate n\'a pas de schedules configurés.'**
  String get noScheduleConfigured;

  /// No description provided for @onOff.
  ///
  /// In fr, this message translates to:
  /// **'On/Off'**
  String get onOff;

  /// No description provided for @multiState.
  ///
  /// In fr, this message translates to:
  /// **'Multi-états'**
  String get multiState;

  /// No description provided for @boolean.
  ///
  /// In fr, this message translates to:
  /// **'Booléen'**
  String get boolean;

  /// No description provided for @scheduleInstance.
  ///
  /// In fr, this message translates to:
  /// **'Schedule {instance}'**
  String scheduleInstance(Object instance);

  /// No description provided for @editModeTapSlot.
  ///
  /// In fr, this message translates to:
  /// **'Mode édition - Appuyez sur un créneau'**
  String get editModeTapSlot;

  /// No description provided for @editModeTapDay.
  ///
  /// In fr, this message translates to:
  /// **'Mode édition - Appuyez sur un jour pour modifier'**
  String get editModeTapDay;

  /// No description provided for @legend.
  ///
  /// In fr, this message translates to:
  /// **'Légende :'**
  String get legend;

  /// No description provided for @selectedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} sélectionné(s)'**
  String selectedCount(Object count);

  /// No description provided for @selectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout désélectionner'**
  String get deselectAll;

  /// No description provided for @selectionMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sélection'**
  String get selectionMode;

  /// No description provided for @newFolder.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau dossier'**
  String get newFolder;

  /// No description provided for @notConnected.
  ///
  /// In fr, this message translates to:
  /// **'Non connecté'**
  String get notConnected;

  /// No description provided for @connectToViewFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous à un automate pour voir vos favoris'**
  String get connectToViewFavorites;

  /// No description provided for @noFavorite.
  ///
  /// In fr, this message translates to:
  /// **'Aucun favori'**
  String get noFavorite;

  /// No description provided for @addFavoritesHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des points aux favoris en cliquant\\nsur l\'étoile dans la liste des points'**
  String get addFavoritesHint;

  /// No description provided for @viewPoints.
  ///
  /// In fr, this message translates to:
  /// **'Voir les points'**
  String get viewPoints;

  /// No description provided for @assignToFolders.
  ///
  /// In fr, this message translates to:
  /// **'Assigner aux dossiers'**
  String get assignToFolders;

  /// No description provided for @deleteFavoritesConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les favoris ?'**
  String get deleteFavoritesConfirm;

  /// No description provided for @deleteFavoritesMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous supprimer {count} favori(s) ?'**
  String deleteFavoritesMessage(Object count);

  /// No description provided for @favoritesAssigned.
  ///
  /// In fr, this message translates to:
  /// **'{favCount} favori(s) assigné(s) à {folderCount} dossier(s)'**
  String favoritesAssigned(Object favCount, Object folderCount);

  /// No description provided for @favoritesDeleted.
  ///
  /// In fr, this message translates to:
  /// **'{count} favori(s) supprimé(s)'**
  String favoritesDeleted(Object count);

  /// No description provided for @createFolderFirst.
  ///
  /// In fr, this message translates to:
  /// **'Créez d\'abord un dossier'**
  String get createFolderFirst;

  /// No description provided for @selectFoldersToAdd.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez les dossiers auxquels ajouter les favoris'**
  String get selectFoldersToAdd;

  /// No description provided for @assign.
  ///
  /// In fr, this message translates to:
  /// **'Assigner'**
  String get assign;

  /// No description provided for @dropHereToAdd.
  ///
  /// In fr, this message translates to:
  /// **'Déposez ici pour ajouter'**
  String get dropHereToAdd;

  /// No description provided for @favoritesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} favori(s)'**
  String favoritesCount(Object count);

  /// No description provided for @editFolder.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editFolder;

  /// No description provided for @deleteFolder.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteFolder;

  /// No description provided for @emptyFolderHint.
  ///
  /// In fr, this message translates to:
  /// **'Dossier vide - glissez des favoris ici'**
  String get emptyFolderHint;

  /// No description provided for @noFolder.
  ///
  /// In fr, this message translates to:
  /// **'Sans dossier'**
  String get noFolder;

  /// No description provided for @deleteFolderConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le dossier ?'**
  String get deleteFolderConfirm;

  /// No description provided for @deleteFolderMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le dossier \"{name}\" sera supprimé.\\n\\nLes favoris qu\'il contient ne seront pas supprimés, ils seront déplacés dans \"Sans dossier\".'**
  String deleteFolderMessage(Object name);

  /// No description provided for @favoriteAddedToFolder.
  ///
  /// In fr, this message translates to:
  /// **'Favori ajouté au dossier'**
  String get favoriteAddedToFolder;

  /// No description provided for @removedFromFavorites.
  ///
  /// In fr, this message translates to:
  /// **'{name} retiré des favoris'**
  String removedFromFavorites(Object name);

  /// No description provided for @assignToFoldersDialog.
  ///
  /// In fr, this message translates to:
  /// **'Assigner aux dossiers'**
  String get assignToFoldersDialog;

  /// No description provided for @categoryInputs.
  ///
  /// In fr, this message translates to:
  /// **'Entrées'**
  String get categoryInputs;

  /// No description provided for @categoryOutputs.
  ///
  /// In fr, this message translates to:
  /// **'Sorties'**
  String get categoryOutputs;

  /// No description provided for @categoryVariables.
  ///
  /// In fr, this message translates to:
  /// **'Valeurs'**
  String get categoryVariables;

  /// No description provided for @categoryOthers.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get categoryOthers;

  /// No description provided for @categoryAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get categoryAll;

  /// No description provided for @sortNameAsc.
  ///
  /// In fr, this message translates to:
  /// **'Nom (A→Z)'**
  String get sortNameAsc;

  /// No description provided for @sortNameDesc.
  ///
  /// In fr, this message translates to:
  /// **'Nom (Z→A)'**
  String get sortNameDesc;

  /// No description provided for @sortType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get sortType;

  /// No description provided for @sortValueAsc.
  ///
  /// In fr, this message translates to:
  /// **'Valeur ↑'**
  String get sortValueAsc;

  /// No description provided for @sortValueDesc.
  ///
  /// In fr, this message translates to:
  /// **'Valeur ↓'**
  String get sortValueDesc;

  /// No description provided for @sortFavoritesFirst.
  ///
  /// In fr, this message translates to:
  /// **'Favoris d\'abord'**
  String get sortFavoritesFirst;

  /// No description provided for @subTypeAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get subTypeAll;

  /// No description provided for @subTypeAnalog.
  ///
  /// In fr, this message translates to:
  /// **'Analog'**
  String get subTypeAnalog;

  /// No description provided for @subTypeBinary.
  ///
  /// In fr, this message translates to:
  /// **'Binary'**
  String get subTypeBinary;

  /// No description provided for @subTypeMulti.
  ///
  /// In fr, this message translates to:
  /// **'Multi'**
  String get subTypeMulti;

  /// No description provided for @autoRefreshOff.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get autoRefreshOff;

  /// No description provided for @autoRefreshSeconds.
  ///
  /// In fr, this message translates to:
  /// **'{count} secondes'**
  String autoRefreshSeconds(Object count);

  /// No description provided for @autoRefreshMinute.
  ///
  /// In fr, this message translates to:
  /// **'1 minute'**
  String get autoRefreshMinute;

  /// No description provided for @noOverride.
  ///
  /// In fr, this message translates to:
  /// **'Aucun forçage'**
  String get noOverride;

  /// No description provided for @allPointsNormal.
  ///
  /// In fr, this message translates to:
  /// **'Tous les points fonctionnent normalement'**
  String get allPointsNormal;

  /// No description provided for @outOfServiceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Hors service'**
  String get outOfServiceLabel;

  /// No description provided for @forcedLabel.
  ///
  /// In fr, this message translates to:
  /// **'Forcé'**
  String get forcedLabel;

  /// No description provided for @priorityLabel.
  ///
  /// In fr, this message translates to:
  /// **'Priorité {priority}'**
  String priorityLabel(Object priority);

  /// No description provided for @bacnetLocalNetworkOnly.
  ///
  /// In fr, this message translates to:
  /// **'Réseau local uniquement'**
  String get bacnetLocalNetworkOnly;

  /// No description provided for @bacnetLocalNetworkInfo.
  ///
  /// In fr, this message translates to:
  /// **'BACnet/IP fonctionne uniquement sur le réseau local. Assurez-vous que votre appareil est connecté au même réseau que le contrôleur.'**
  String get bacnetLocalNetworkInfo;

  /// No description provided for @bacnetDeviceIdOptional.
  ///
  /// In fr, this message translates to:
  /// **'Device ID (optionnel en local)'**
  String get bacnetDeviceIdOptional;

  /// No description provided for @bacnetDeviceIdHelper.
  ///
  /// In fr, this message translates to:
  /// **'Laissez vide pour découverte automatique sur le réseau local'**
  String get bacnetDeviceIdHelper;

  /// No description provided for @bacnetDeviceIdRemoteRequired.
  ///
  /// In fr, this message translates to:
  /// **'Requis si vous n\'êtes pas sur le même réseau'**
  String get bacnetDeviceIdRemoteRequired;

  /// No description provided for @discoverDevices.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir les appareils'**
  String get discoverDevices;

  /// No description provided for @discovering.
  ///
  /// In fr, this message translates to:
  /// **'Recherche en cours...'**
  String get discovering;

  /// No description provided for @noDeviceFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun appareil BACnet trouvé'**
  String get noDeviceFound;

  /// No description provided for @noDeviceFoundMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun appareil BACnet n\'a répondu sur le réseau local.\n\nVérifiez que :\n• Vous êtes sur le même réseau que le contrôleur\n• Le port UDP 47808 n\'est pas bloqué\n• Le contrôleur est allumé et accessible'**
  String get noDeviceFoundMessage;

  /// No description provided for @devicesFound.
  ///
  /// In fr, this message translates to:
  /// **'{count} appareil(s) trouvé(s)'**
  String devicesFound(Object count);

  /// No description provided for @selectDevice.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un appareil'**
  String get selectDevice;

  /// No description provided for @deviceId.
  ///
  /// In fr, this message translates to:
  /// **'Device ID'**
  String get deviceId;

  /// No description provided for @vendor.
  ///
  /// In fr, this message translates to:
  /// **'Fabricant'**
  String get vendor;

  /// No description provided for @model.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get model;

  /// No description provided for @bacnetPortHelper.
  ///
  /// In fr, this message translates to:
  /// **'Port BACnet/IP (défaut: 47808)'**
  String get bacnetPortHelper;

  /// No description provided for @broadcastDiscovery.
  ///
  /// In fr, this message translates to:
  /// **'Découverte broadcast'**
  String get broadcastDiscovery;

  /// No description provided for @broadcastDiscoverySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher tous les appareils BACnet sur le réseau local'**
  String get broadcastDiscoverySubtitle;

  /// No description provided for @discoverEclypse.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir ECLYPSE'**
  String get discoverEclypse;

  /// No description provided for @discoverEclypseSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherche mDNS des automates Distech'**
  String get discoverEclypseSubtitle;

  /// No description provided for @eclypseFound.
  ///
  /// In fr, this message translates to:
  /// **'{count} ECLYPSE trouvé(s)'**
  String eclypseFound(Object count);

  /// No description provided for @scanIpRange.
  ///
  /// In fr, this message translates to:
  /// **'Scanner une plage IP'**
  String get scanIpRange;

  /// No description provided for @scanIpRangeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Scan unicast pour trouver les ECLYPSE et autres'**
  String get scanIpRangeSubtitle;

  /// No description provided for @startIp.
  ///
  /// In fr, this message translates to:
  /// **'IP de début'**
  String get startIp;

  /// No description provided for @endIp.
  ///
  /// In fr, this message translates to:
  /// **'IP de fin'**
  String get endIp;

  /// No description provided for @scanProgress.
  ///
  /// In fr, this message translates to:
  /// **'Scan en cours... {current}/{total}'**
  String scanProgress(Object current, Object total);

  /// No description provided for @scanning.
  ///
  /// In fr, this message translates to:
  /// **'Scan en cours...'**
  String get scanning;

  /// No description provided for @stopScan.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter'**
  String get stopScan;

  /// No description provided for @invalidIpRange.
  ///
  /// In fr, this message translates to:
  /// **'Plage IP invalide'**
  String get invalidIpRange;

  /// No description provided for @ipRangeSameSubnet.
  ///
  /// In fr, this message translates to:
  /// **'Les IPs doivent être sur le même sous-réseau /24'**
  String get ipRangeSameSubnet;

  /// No description provided for @scanComplete.
  ///
  /// In fr, this message translates to:
  /// **'Scan terminé'**
  String get scanComplete;

  /// No description provided for @orManualEntry.
  ///
  /// In fr, this message translates to:
  /// **'ou saisie manuelle :'**
  String get orManualEntry;

  /// No description provided for @useIpScan.
  ///
  /// In fr, this message translates to:
  /// **'Scanner plage IP (ECLYPSE)'**
  String get useIpScan;

  /// No description provided for @dashboards.
  ///
  /// In fr, this message translates to:
  /// **'Dashboards'**
  String get dashboards;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @noDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dashboard'**
  String get noDashboard;

  /// No description provided for @createDashboardHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez des dashboards pour visualiser\nvos graphiques et courbes d\'historique'**
  String get createDashboardHint;

  /// No description provided for @createDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Créer un dashboard'**
  String get createDashboard;

  /// No description provided for @newDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau dashboard'**
  String get newDashboard;

  /// No description provided for @editDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le dashboard'**
  String get editDashboard;

  /// No description provided for @deleteDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le dashboard'**
  String get deleteDashboard;

  /// No description provided for @dashboardName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du dashboard'**
  String get dashboardName;

  /// No description provided for @dashboardNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get dashboardNameRequired;

  /// No description provided for @deleteDashboardConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce dashboard ?'**
  String get deleteDashboardConfirm;

  /// No description provided for @deleteDashboardMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le dashboard \"{name}\" et tous ses widgets seront supprimés.'**
  String deleteDashboardMessage(Object name);

  /// No description provided for @dashboardDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Dashboard supprimé'**
  String get dashboardDeleted;

  /// No description provided for @widgets.
  ///
  /// In fr, this message translates to:
  /// **'{count} widget(s)'**
  String widgets(Object count);

  /// No description provided for @addWidget.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un widget'**
  String get addWidget;

  /// No description provided for @configureWidget.
  ///
  /// In fr, this message translates to:
  /// **'Configurer le widget'**
  String get configureWidget;

  /// No description provided for @deleteWidget.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le widget'**
  String get deleteWidget;

  /// No description provided for @widgetDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Widget supprimé'**
  String get widgetDeleted;

  /// No description provided for @singleChart.
  ///
  /// In fr, this message translates to:
  /// **'Graphique simple'**
  String get singleChart;

  /// No description provided for @singleChartDescription.
  ///
  /// In fr, this message translates to:
  /// **'Affiche l\'historique d\'un seul point'**
  String get singleChartDescription;

  /// No description provided for @multiCurveChart.
  ///
  /// In fr, this message translates to:
  /// **'Multi-courbes'**
  String get multiCurveChart;

  /// No description provided for @multiCurveChartDescription.
  ///
  /// In fr, this message translates to:
  /// **'Compare plusieurs points sur un même graphique'**
  String get multiCurveChartDescription;

  /// No description provided for @statsCard.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statsCard;

  /// No description provided for @statsCardDescription.
  ///
  /// In fr, this message translates to:
  /// **'Affiche min, max et moyenne d\'un point'**
  String get statsCardDescription;

  /// No description provided for @selectTrendLog.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un trend log'**
  String get selectTrendLog;

  /// No description provided for @noTrendLogSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun trend log sélectionné'**
  String get noTrendLogSelected;

  /// No description provided for @selectTrendLogs.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez les trend logs'**
  String get selectTrendLogs;

  /// No description provided for @selectedTrendLogs.
  ///
  /// In fr, this message translates to:
  /// **'{count} trend log(s) sélectionné(s)'**
  String selectedTrendLogs(Object count);

  /// No description provided for @minCurvesRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez au moins 2 trend logs'**
  String get minCurvesRequired;

  /// No description provided for @maxCurvesReached.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 8 courbes autorisées'**
  String get maxCurvesReached;

  /// No description provided for @showMin.
  ///
  /// In fr, this message translates to:
  /// **'Afficher minimum'**
  String get showMin;

  /// No description provided for @showMax.
  ///
  /// In fr, this message translates to:
  /// **'Afficher maximum'**
  String get showMax;

  /// No description provided for @showAvg.
  ///
  /// In fr, this message translates to:
  /// **'Afficher moyenne'**
  String get showAvg;

  /// No description provided for @curveVisibility.
  ///
  /// In fr, this message translates to:
  /// **'Visibilité des courbes'**
  String get curveVisibility;

  /// No description provided for @periodDay.
  ///
  /// In fr, this message translates to:
  /// **'Jour'**
  String get periodDay;

  /// No description provided for @periodWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get periodMonth;

  /// No description provided for @periodYear.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get periodYear;

  /// No description provided for @networkInterface.
  ///
  /// In fr, this message translates to:
  /// **'Interface réseau'**
  String get networkInterface;

  /// No description provided for @allInterfaces.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les interfaces'**
  String get allInterfaces;

  /// No description provided for @searchingBacnetDevices.
  ///
  /// In fr, this message translates to:
  /// **'Recherche des appareils BACnet...'**
  String get searchingBacnetDevices;

  /// No description provided for @deviceIdConflict.
  ///
  /// In fr, this message translates to:
  /// **'Conflit Device ID'**
  String get deviceIdConflict;

  /// No description provided for @deviceIdConflictMessage.
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs appareils partagent le même Device ID BACnet. Ceci est interdit par le protocole et peut causer des dysfonctionnements.'**
  String get deviceIdConflictMessage;

  /// No description provided for @conflictingAddresses.
  ///
  /// In fr, this message translates to:
  /// **'Adresses IP en conflit :'**
  String get conflictingAddresses;

  /// No description provided for @conflictRecommendation.
  ///
  /// In fr, this message translates to:
  /// **'Action recommandée : Reconfigurer les appareils pour avoir des Device ID uniques.'**
  String get conflictRecommendation;

  /// No description provided for @understood.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get understood;

  /// No description provided for @idConflict.
  ///
  /// In fr, this message translates to:
  /// **'ID conflit'**
  String get idConflict;

  /// No description provided for @alsoAt.
  ///
  /// In fr, this message translates to:
  /// **'Aussi à'**
  String get alsoAt;

  /// No description provided for @conflicts.
  ///
  /// In fr, this message translates to:
  /// **'conflit(s)'**
  String get conflicts;

  /// No description provided for @bacnetPortWarning.
  ///
  /// In fr, this message translates to:
  /// **'Port {actualPort} utilisé (standard: {standardPort})'**
  String bacnetPortWarning(int actualPort, int standardPort);

  /// No description provided for @bacnetPortConflict.
  ///
  /// In fr, this message translates to:
  /// **'Conflit de port BACnet'**
  String get bacnetPortConflict;

  /// No description provided for @bacnetPortConflictDetail.
  ///
  /// In fr, this message translates to:
  /// **'Le port standard BACnet ({standardPort}) est déjà utilisé par une autre application. L\'application utilise le port {actualPort} à la place.'**
  String bacnetPortConflictDetail(int standardPort, int actualPort);

  /// No description provided for @bacnetPortConflictSolution.
  ///
  /// In fr, this message translates to:
  /// **'Solutions :'**
  String get bacnetPortConflictSolution;

  /// No description provided for @bacnetPortSolution1.
  ///
  /// In fr, this message translates to:
  /// **'Fermez YABE ou autres applications BACnet'**
  String get bacnetPortSolution1;

  /// No description provided for @bacnetPortSolution2.
  ///
  /// In fr, this message translates to:
  /// **'Relancez cette application'**
  String get bacnetPortSolution2;

  /// No description provided for @envysionDesignerSection.
  ///
  /// In fr, this message translates to:
  /// **'Synoptique Envysion (optionnel)'**
  String get envysionDesignerSection;

  /// No description provided for @designerUrl.
  ///
  /// In fr, this message translates to:
  /// **'URL du Designer'**
  String get designerUrl;

  /// No description provided for @designerUrlHelper.
  ///
  /// In fr, this message translates to:
  /// **'Chemin vers le viewer Envysion intégré au contrôleur'**
  String get designerUrlHelper;

  /// No description provided for @synopticEnvysion.
  ///
  /// In fr, this message translates to:
  /// **'Synoptique Envysion'**
  String get synopticEnvysion;

  /// No description provided for @synopticLocal.
  ///
  /// In fr, this message translates to:
  /// **'Synoptiques locaux'**
  String get synopticLocal;

  /// No description provided for @openInBrowser.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir dans le navigateur'**
  String get openInBrowser;

  /// No description provided for @webViewNotSupported.
  ///
  /// In fr, this message translates to:
  /// **'WebView non supportée sur cette plateforme'**
  String get webViewNotSupported;

  /// No description provided for @webViewNotSupportedMessage.
  ///
  /// In fr, this message translates to:
  /// **'L\'affichage intégré n\'est pas disponible sur {platform}. Voulez-vous ouvrir dans le navigateur externe ?'**
  String webViewNotSupportedMessage(Object platform);

  /// No description provided for @loadingEnvysion.
  ///
  /// In fr, this message translates to:
  /// **'Chargement du synoptique...'**
  String get loadingEnvysion;

  /// No description provided for @envysionLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get envysionLoadError;

  /// No description provided for @envysionLoadErrorMessage.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le synoptique Envysion. Vérifiez l\'URL et votre connexion.'**
  String get envysionLoadErrorMessage;

  /// No description provided for @certificateChangedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Certificat de l\'automate modifié'**
  String get certificateChangedTitle;

  /// No description provided for @trustNewCertificate.
  ///
  /// In fr, this message translates to:
  /// **'Faire confiance au nouveau certificat'**
  String get trustNewCertificate;

  /// No description provided for @trustNewCertificateMessage.
  ///
  /// In fr, this message translates to:
  /// **'Le certificat présenté par l\'automate est différent de celui enregistré lors de la première connexion.\n\nCela peut venir d\'un renouvellement du certificat (mise à jour, réinitialisation de l\'automate) ou d\'une interception du trafic. Ne faites confiance au nouveau certificat que si vous êtes sûr qu\'il est légitime.\n\nEmpreinte attendue :\n{expected}\n\nNouvelle empreinte :\n{received}'**
  String trustNewCertificateMessage(String expected, String received);

  /// No description provided for @trust.
  ///
  /// In fr, this message translates to:
  /// **'Faire confiance'**
  String get trust;

  /// No description provided for @backToConnections.
  ///
  /// In fr, this message translates to:
  /// **'Retour aux connexions'**
  String get backToConnections;

  /// No description provided for @certificateFingerprintLabel.
  ///
  /// In fr, this message translates to:
  /// **'Empreinte du certificat (SHA-256)'**
  String get certificateFingerprintLabel;

  /// No description provided for @certificateFingerprintDiffers.
  ///
  /// In fr, this message translates to:
  /// **'Différente de l\'empreinte enregistrée : le certificat de l\'automate a changé.'**
  String get certificateFingerprintDiffers;

  /// No description provided for @certificateFingerprintPinnedInfo.
  ///
  /// In fr, this message translates to:
  /// **'Elle sera enregistrée et vérifiée à chaque connexion.'**
  String get certificateFingerprintPinnedInfo;

  /// No description provided for @httpCleartextWarning.
  ///
  /// In fr, this message translates to:
  /// **'HTTP non chiffré : le mot de passe circule en clair sur le réseau. Préférez HTTPS si l\'automate le permet.'**
  String get httpCleartextWarning;

  /// No description provided for @passwordMissingBadge.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe à ressaisir'**
  String get passwordMissingBadge;

  /// No description provided for @apiVersionBadgeTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Version de l\'API REST Distech utilisée pour cet automate'**
  String get apiVersionBadgeTooltip;

  /// No description provided for @apiVersionUnknownTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Version d\'API pas encore détectée : elle le sera à la prochaine connexion'**
  String get apiVersionUnknownTooltip;

  /// No description provided for @redetectApiVersion.
  ///
  /// In fr, this message translates to:
  /// **'Re-détecter la version API'**
  String get redetectApiVersion;

  /// No description provided for @redetectingApiVersion.
  ///
  /// In fr, this message translates to:
  /// **'Détection de la version d\'API…'**
  String get redetectingApiVersion;

  /// No description provided for @redetectApiVersionDone.
  ///
  /// In fr, this message translates to:
  /// **'Version d\'API détectée : {version}'**
  String redetectApiVersionDone(String version);

  /// No description provided for @redetectApiVersionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Automate injoignable : version d\'API non détectée'**
  String get redetectApiVersionFailed;

  /// No description provided for @overrideDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée du forçage'**
  String get overrideDuration;

  /// No description provided for @overridePermanent.
  ///
  /// In fr, this message translates to:
  /// **'Permanent'**
  String get overridePermanent;

  /// No description provided for @durationMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @durationHours.
  ///
  /// In fr, this message translates to:
  /// **'{hours} h'**
  String durationHours(int hours);

  /// No description provided for @timedOverrideHint.
  ///
  /// In fr, this message translates to:
  /// **'Le relâchement automatique est fait par l\'application : elle doit être ouverte à l\'échéance (sinon il a lieu à sa prochaine ouverture).'**
  String get timedOverrideHint;

  /// No description provided for @forcedAtTime.
  ///
  /// In fr, this message translates to:
  /// **'Forcé depuis l\'app à {time}'**
  String forcedAtTime(String time);

  /// No description provided for @autoReleaseAtTime.
  ///
  /// In fr, this message translates to:
  /// **'Relâchement automatique à {time}'**
  String autoReleaseAtTime(String time);

  /// No description provided for @autoReleaseFailed.
  ///
  /// In fr, this message translates to:
  /// **'Relâchement automatique en échec, nouvel essai en cours : {error}'**
  String autoReleaseFailed(String error);

  /// No description provided for @overrideOriginUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Forcé hors de l\'application (heure inconnue)'**
  String get overrideOriginUnknown;

  /// No description provided for @overridesSelected.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{Aucun point sélectionné} =1{1 point sélectionné} other{{count} points sélectionnés}}'**
  String overridesSelected(int count);

  /// No description provided for @releaseSelection.
  ///
  /// In fr, this message translates to:
  /// **'Relâcher la sélection'**
  String get releaseSelection;

  /// No description provided for @releaseSelectionMessage.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{Relâcher le forçage de 1 point ?} other{Relâcher le forçage de {count} points ?}}'**
  String releaseSelectionMessage(int count);

  /// No description provided for @releaseSelectionDone.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 point relâché} other{{count} points relâchés}}'**
  String releaseSelectionDone(int count);

  /// No description provided for @releaseSelectionFailed.
  ///
  /// In fr, this message translates to:
  /// **'{failed} relâchement(s) sur {total} en échec'**
  String releaseSelectionFailed(int failed, int total);

  /// No description provided for @invalidCredentialsMessage.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants invalides ({status}). Vérifiez le nom d\'utilisateur et le mot de passe de la connexion.'**
  String invalidCredentialsMessage(String status);

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @rename.
  ///
  /// In fr, this message translates to:
  /// **'Renommer'**
  String get rename;

  /// No description provided for @create.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get create;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @copy.
  ///
  /// In fr, this message translates to:
  /// **'Copier'**
  String get copy;

  /// No description provided for @clearAction.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clearAction;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @details.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get details;

  /// No description provided for @unknown.
  ///
  /// In fr, this message translates to:
  /// **'Inconnu'**
  String get unknown;

  /// No description provided for @errorWithMessage.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String errorWithMessage(String error);

  /// No description provided for @trendColorBlue.
  ///
  /// In fr, this message translates to:
  /// **'Bleu'**
  String get trendColorBlue;

  /// No description provided for @trendColorGreen.
  ///
  /// In fr, this message translates to:
  /// **'Vert'**
  String get trendColorGreen;

  /// No description provided for @trendColorOrange.
  ///
  /// In fr, this message translates to:
  /// **'Orange'**
  String get trendColorOrange;

  /// No description provided for @trendColorPurple.
  ///
  /// In fr, this message translates to:
  /// **'Violet'**
  String get trendColorPurple;

  /// No description provided for @trendColorRed.
  ///
  /// In fr, this message translates to:
  /// **'Rouge'**
  String get trendColorRed;

  /// No description provided for @trendColorCyan.
  ///
  /// In fr, this message translates to:
  /// **'Cyan'**
  String get trendColorCyan;

  /// No description provided for @trendColorTeal.
  ///
  /// In fr, this message translates to:
  /// **'Sarcelle'**
  String get trendColorTeal;

  /// No description provided for @trendColorIndigo.
  ///
  /// In fr, this message translates to:
  /// **'Indigo'**
  String get trendColorIndigo;

  /// No description provided for @trendPeriodHour.
  ///
  /// In fr, this message translates to:
  /// **'1h'**
  String get trendPeriodHour;

  /// No description provided for @trendPeriodDay.
  ///
  /// In fr, this message translates to:
  /// **'24h'**
  String get trendPeriodDay;

  /// No description provided for @trendPeriodWeek.
  ///
  /// In fr, this message translates to:
  /// **'7j'**
  String get trendPeriodWeek;

  /// No description provided for @trendPeriodMonth.
  ///
  /// In fr, this message translates to:
  /// **'30j'**
  String get trendPeriodMonth;

  /// No description provided for @trendPeriodAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get trendPeriodAll;

  /// No description provided for @trendPeriodCustom.
  ///
  /// In fr, this message translates to:
  /// **'Perso.'**
  String get trendPeriodCustom;

  /// No description provided for @trendChangeColor.
  ///
  /// In fr, this message translates to:
  /// **'Changer la couleur'**
  String get trendChangeColor;

  /// No description provided for @trendAnnotations.
  ///
  /// In fr, this message translates to:
  /// **'Annotations'**
  String get trendAnnotations;

  /// No description provided for @trendMinMaxMarkers.
  ///
  /// In fr, this message translates to:
  /// **'Marqueurs Min/Max'**
  String get trendMinMaxMarkers;

  /// No description provided for @trendAverageLine.
  ///
  /// In fr, this message translates to:
  /// **'Ligne moyenne'**
  String get trendAverageLine;

  /// No description provided for @trendMinLine.
  ///
  /// In fr, this message translates to:
  /// **'Ligne minimum'**
  String get trendMinLine;

  /// No description provided for @trendMaxLine.
  ///
  /// In fr, this message translates to:
  /// **'Ligne maximum'**
  String get trendMaxLine;

  /// No description provided for @trendHideAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout masquer'**
  String get trendHideAll;

  /// No description provided for @trendNoDataForPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée pour cette période'**
  String get trendNoDataForPeriod;

  /// No description provided for @trendDateTime.
  ///
  /// In fr, this message translates to:
  /// **'Date/Heure'**
  String get trendDateTime;

  /// No description provided for @trendHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get trendHistory;

  /// No description provided for @trendFullscreen.
  ///
  /// In fr, this message translates to:
  /// **'Plein écran'**
  String get trendFullscreen;

  /// No description provided for @trendShowChart.
  ///
  /// In fr, this message translates to:
  /// **'Voir graphique'**
  String get trendShowChart;

  /// No description provided for @trendShowTable.
  ///
  /// In fr, this message translates to:
  /// **'Voir tableau'**
  String get trendShowTable;

  /// No description provided for @trendExportCsv.
  ///
  /// In fr, this message translates to:
  /// **'Exporter CSV'**
  String get trendExportCsv;

  /// No description provided for @trendExportSubject.
  ///
  /// In fr, this message translates to:
  /// **'Export historique {name}'**
  String trendExportSubject(String name);

  /// No description provided for @trendPortraitMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode portrait'**
  String get trendPortraitMode;

  /// No description provided for @trendLandscapeMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode paysage'**
  String get trendLandscapeMode;

  /// No description provided for @trendNoNumericData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée numérique'**
  String get trendNoNumericData;

  /// No description provided for @trendNoDataToDisplay.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée à afficher'**
  String get trendNoDataToDisplay;

  /// No description provided for @trendInvalidData.
  ///
  /// In fr, this message translates to:
  /// **'Données invalides'**
  String get trendInvalidData;

  /// No description provided for @trendAvgLineLabel.
  ///
  /// In fr, this message translates to:
  /// **'Moy : {value}'**
  String trendAvgLineLabel(String value);

  /// No description provided for @chartComparisonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison ({count} courbes)'**
  String chartComparisonTitle(int count);

  /// No description provided for @chartAddCurve.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une courbe'**
  String get chartAddCurve;

  /// No description provided for @chartCurvesNotLoaded.
  ///
  /// In fr, this message translates to:
  /// **'{count} courbe(s) non chargée(s)'**
  String chartCurvesNotLoaded(int count);

  /// No description provided for @chartNoVisibleCurve.
  ///
  /// In fr, this message translates to:
  /// **'Aucune courbe visible\nTouchez la légende pour afficher'**
  String get chartNoVisibleCurve;

  /// No description provided for @chartNoCurveSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune courbe sélectionnée\nAjoutez des trend logs à comparer'**
  String get chartNoCurveSelected;

  /// No description provided for @chartSelectCurves.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner les courbes'**
  String get chartSelectCurves;

  /// No description provided for @chartSelectCurvesHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez {min} à {max} trend logs à comparer'**
  String chartSelectCurvesHint(int min, int max);

  /// No description provided for @chartCurvesCount.
  ///
  /// In fr, this message translates to:
  /// **'{selected}/{max} courbes'**
  String chartCurvesCount(int selected, int max);

  /// No description provided for @chartNoTrendLogAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun trend log disponible'**
  String get chartNoTrendLogAvailable;

  /// No description provided for @chartSelectedCurves.
  ///
  /// In fr, this message translates to:
  /// **'Courbes sélectionnées :'**
  String get chartSelectedCurves;

  /// No description provided for @chartValidateCount.
  ///
  /// In fr, this message translates to:
  /// **'Valider ({count})'**
  String chartValidateCount(int count);

  /// No description provided for @widgetPromoteSuperFavorite.
  ///
  /// In fr, this message translates to:
  /// **'Promouvoir en super favori'**
  String get widgetPromoteSuperFavorite;

  /// No description provided for @widgetDemoteToFavorite.
  ///
  /// In fr, this message translates to:
  /// **'Rétrograder en favori'**
  String get widgetDemoteToFavorite;

  /// No description provided for @widgetNoFolder.
  ///
  /// In fr, this message translates to:
  /// **'Aucun dossier'**
  String get widgetNoFolder;

  /// No description provided for @widgetCreateFolder.
  ///
  /// In fr, this message translates to:
  /// **'Créer un dossier'**
  String get widgetCreateFolder;

  /// No description provided for @widgetNewFolderEllipsis.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau dossier...'**
  String get widgetNewFolderEllipsis;

  /// No description provided for @widgetEditFolder.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le dossier'**
  String get widgetEditFolder;

  /// No description provided for @widgetFolderName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du dossier'**
  String get widgetFolderName;

  /// No description provided for @widgetColor.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get widgetColor;

  /// No description provided for @widgetIcon.
  ///
  /// In fr, this message translates to:
  /// **'Icône'**
  String get widgetIcon;

  /// No description provided for @widgetConnecting.
  ///
  /// In fr, this message translates to:
  /// **'Connexion en cours'**
  String get widgetConnecting;

  /// No description provided for @widgetStepAuth.
  ///
  /// In fr, this message translates to:
  /// **'Auth'**
  String get widgetStepAuth;

  /// No description provided for @widgetPumpLabel.
  ///
  /// In fr, this message translates to:
  /// **'POMPE'**
  String get widgetPumpLabel;

  /// No description provided for @synopticsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Synoptiques'**
  String get synopticsTitle;

  /// No description provided for @synopticCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer un synoptique'**
  String get synopticCreate;

  /// No description provided for @synopticEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun synoptique'**
  String get synopticEmptyTitle;

  /// No description provided for @synopticEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre premier synoptique pour visualiser\nvos points sur un schéma graphique'**
  String get synopticEmptyHint;

  /// No description provided for @synopticDeleteTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le synoptique ?'**
  String get synopticDeleteTitle;

  /// No description provided for @synopticDeleteMessage.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer \"{name}\" ?\nCette action est irréversible.'**
  String synopticDeleteMessage(String name);

  /// No description provided for @synopticBindingsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 liaison} =1{1 liaison} other{{count} liaisons}}'**
  String synopticBindingsCount(int count);

  /// No description provided for @synopticBindingsUnknown.
  ///
  /// In fr, this message translates to:
  /// **'-- liaisons'**
  String get synopticBindingsUnknown;

  /// No description provided for @synopticGlobal.
  ///
  /// In fr, this message translates to:
  /// **'Global'**
  String get synopticGlobal;

  /// No description provided for @synopticEditBindings.
  ///
  /// In fr, this message translates to:
  /// **'Éditer les liaisons'**
  String get synopticEditBindings;

  /// No description provided for @synopticNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau synoptique'**
  String get synopticNew;

  /// No description provided for @synopticSvgModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle SVG'**
  String get synopticSvgModel;

  /// No description provided for @synopticConfigurableElementsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} éléments configurables'**
  String synopticConfigurableElementsCount(int count);

  /// No description provided for @synopticNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom du synoptique'**
  String get synopticNameLabel;

  /// No description provided for @synopticNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Circuit Chauffage RDC'**
  String get synopticNameHint;

  /// No description provided for @synopticDescriptionOptional.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnel)'**
  String get synopticDescriptionOptional;

  /// No description provided for @synopticDefaultName.
  ///
  /// In fr, this message translates to:
  /// **'Synoptique'**
  String get synopticDefaultName;

  /// No description provided for @synopticResetZoom.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le zoom'**
  String get synopticResetZoom;

  /// No description provided for @synopticNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Synoptique non trouvé'**
  String get synopticNotFound;

  /// No description provided for @synopticUpdateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de mise à jour: {error}'**
  String synopticUpdateError(String error);

  /// No description provided for @synopticActivePointsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 point actif} =1{1 point actif} other{{count} points actifs}}'**
  String synopticActivePointsCount(int count);

  /// No description provided for @synopticPinchToZoom.
  ///
  /// In fr, this message translates to:
  /// **'Pincez pour zoomer'**
  String get synopticPinchToZoom;

  /// No description provided for @synopticSvgElement.
  ///
  /// In fr, this message translates to:
  /// **'Élément SVG'**
  String get synopticSvgElement;

  /// No description provided for @synopticBindingType.
  ///
  /// In fr, this message translates to:
  /// **'Type de liaison'**
  String get synopticBindingType;

  /// No description provided for @synopticCurrentValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur actuelle'**
  String get synopticCurrentValue;

  /// No description provided for @synopticViewPoint.
  ///
  /// In fr, this message translates to:
  /// **'Voir le point'**
  String get synopticViewPoint;

  /// No description provided for @synopticNumericValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur numérique'**
  String get synopticNumericValue;

  /// No description provided for @synopticColorIndicator.
  ///
  /// In fr, this message translates to:
  /// **'Indicateur couleur'**
  String get synopticColorIndicator;

  /// No description provided for @synopticAnimation.
  ///
  /// In fr, this message translates to:
  /// **'Animation'**
  String get synopticAnimation;

  /// No description provided for @synopticEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Éditer: {name}'**
  String synopticEditTitle(String name);

  /// No description provided for @synopticHelp.
  ///
  /// In fr, this message translates to:
  /// **'Aide'**
  String get synopticHelp;

  /// No description provided for @synopticPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu du synoptique'**
  String get synopticPreview;

  /// No description provided for @synopticConfigurableElements.
  ///
  /// In fr, this message translates to:
  /// **'Éléments configurables'**
  String get synopticConfigurableElements;

  /// No description provided for @synopticNoConfigurableElements.
  ///
  /// In fr, this message translates to:
  /// **'Aucun élément configurable détecté'**
  String get synopticNoConfigurableElements;

  /// No description provided for @synopticHowToConfigure.
  ///
  /// In fr, this message translates to:
  /// **'Comment configurer'**
  String get synopticHowToConfigure;

  /// No description provided for @synopticHelpSteps.
  ///
  /// In fr, this message translates to:
  /// **'1. Sélectionnez un élément dans la liste\n2. Choisissez le point BACnet à associer\n3. Configurez le type de liaison:\n   • Valeur: affiche la valeur du point\n   • Couleur: change la couleur selon l\'état\n   • Animation: active/désactive une animation\n4. Personnalisez le format si nécessaire'**
  String get synopticHelpSteps;

  /// No description provided for @synopticStateIndicator.
  ///
  /// In fr, this message translates to:
  /// **'Indicateur d\'état'**
  String get synopticStateIndicator;

  /// No description provided for @synopticElement.
  ///
  /// In fr, this message translates to:
  /// **'Élément'**
  String get synopticElement;

  /// No description provided for @synopticConfigureBinding.
  ///
  /// In fr, this message translates to:
  /// **'Configurer la liaison'**
  String get synopticConfigureBinding;

  /// No description provided for @synopticDeleteBinding.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la liaison'**
  String get synopticDeleteBinding;

  /// No description provided for @synopticColor.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get synopticColor;

  /// No description provided for @synopticDisplayFormat.
  ///
  /// In fr, this message translates to:
  /// **'Format d\'affichage'**
  String get synopticDisplayFormat;

  /// No description provided for @synopticFormatHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: {placeholder}°C ou {placeholder}%'**
  String synopticFormatHint(String placeholder);

  /// No description provided for @synopticFormatHelper.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez {placeholder} pour la valeur du point'**
  String synopticFormatHelper(String placeholder);

  /// No description provided for @synopticColors.
  ///
  /// In fr, this message translates to:
  /// **'Couleurs'**
  String get synopticColors;

  /// No description provided for @synopticAnimationConfig.
  ///
  /// In fr, this message translates to:
  /// **'Configuration Animation'**
  String get synopticAnimationConfig;

  /// No description provided for @synopticAnimationOnOff.
  ///
  /// In fr, this message translates to:
  /// **'Animation ON/OFF'**
  String get synopticAnimationOnOff;

  /// No description provided for @synopticAnimationExplanation.
  ///
  /// In fr, this message translates to:
  /// **'L\'animation sera visible quand la valeur du point est > seuil (actif), et masquée sinon.'**
  String get synopticAnimationExplanation;

  /// No description provided for @synopticThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil ON/OFF'**
  String get synopticThreshold;

  /// No description provided for @synopticThresholdHelper.
  ///
  /// In fr, this message translates to:
  /// **'Valeur > seuil = ON, sinon OFF (pour booléen: 0.5)'**
  String get synopticThresholdHelper;

  /// No description provided for @synopticBacnetPoint.
  ///
  /// In fr, this message translates to:
  /// **'Point BACnet'**
  String get synopticBacnetPoint;

  /// No description provided for @synopticNoPointFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun point trouvé'**
  String get synopticNoPointFound;

  /// No description provided for @synopticDeleteBindingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la liaison ?'**
  String get synopticDeleteBindingTitle;

  /// No description provided for @synopticIrreversible.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible.'**
  String get synopticIrreversible;

  /// No description provided for @envysionConnectionNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Connexion introuvable'**
  String get envysionConnectionNotFound;

  /// No description provided for @envysionAuthFailed.
  ///
  /// In fr, this message translates to:
  /// **'Authentification échouée (401)'**
  String get envysionAuthFailed;

  /// No description provided for @envysionPageNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Page non trouvée (404)'**
  String get envysionPageNotFound;

  /// No description provided for @dashboardNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Dashboard introuvable'**
  String get dashboardNotFound;

  /// No description provided for @dashboardDeleteWidgetConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le widget ?'**
  String get dashboardDeleteWidgetConfirm;

  /// No description provided for @dashboardDeleteWidgetMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ce widget sera supprimé du tableau de bord.'**
  String get dashboardDeleteWidgetMessage;

  /// No description provided for @dashboardEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le titre'**
  String get dashboardEditTitle;

  /// No description provided for @dashboardTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get dashboardTitleLabel;

  /// No description provided for @dashboardTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Laisser vide pour le titre par défaut'**
  String get dashboardTitleHint;

  /// No description provided for @dashboardSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres du dashboard'**
  String get dashboardSettingsTitle;

  /// No description provided for @dashboardColumnsWithColon.
  ///
  /// In fr, this message translates to:
  /// **'Colonnes : '**
  String get dashboardColumnsWithColon;

  /// No description provided for @dashboardRowsWithColon.
  ///
  /// In fr, this message translates to:
  /// **'Lignes : '**
  String get dashboardRowsWithColon;

  /// No description provided for @dashboardDeletePermanentMessage.
  ///
  /// In fr, this message translates to:
  /// **'Ce tableau de bord et tous ses widgets seront supprimés définitivement.'**
  String get dashboardDeletePermanentMessage;

  /// No description provided for @dashboardSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher...'**
  String get dashboardSearchHint;

  /// No description provided for @dashboardNewShort.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get dashboardNewShort;

  /// No description provided for @dashboardEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Créez votre premier tableau de bord pour visualiser\nplusieurs graphiques sur une seule page.'**
  String get dashboardEmptyHint;

  /// No description provided for @dashboardGridSize.
  ///
  /// In fr, this message translates to:
  /// **'Grille {columns}x{rows}'**
  String dashboardGridSize(int columns, int rows);

  /// No description provided for @dashboardNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Chauffage, Ventilation...'**
  String get dashboardNameHint;

  /// No description provided for @dashboardGridLayout.
  ///
  /// In fr, this message translates to:
  /// **'Disposition de la grille'**
  String get dashboardGridLayout;

  /// No description provided for @dashboardColumns.
  ///
  /// In fr, this message translates to:
  /// **'Colonnes'**
  String get dashboardColumns;

  /// No description provided for @dashboardRows.
  ///
  /// In fr, this message translates to:
  /// **'Lignes'**
  String get dashboardRows;

  /// No description provided for @dashboardChartDefault.
  ///
  /// In fr, this message translates to:
  /// **'Graphique'**
  String get dashboardChartDefault;

  /// No description provided for @dashboardComparisonTitle.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison ({count} courbes)'**
  String dashboardComparisonTitle(int count);

  /// No description provided for @dashboardNotConfigured.
  ///
  /// In fr, this message translates to:
  /// **'Non configuré'**
  String get dashboardNotConfigured;

  /// No description provided for @dashboardConfigure.
  ///
  /// In fr, this message translates to:
  /// **'Configurer'**
  String get dashboardConfigure;

  /// No description provided for @deviceInfoProtocol.
  ///
  /// In fr, this message translates to:
  /// **'Protocole'**
  String get deviceInfoProtocol;

  /// No description provided for @deviceInfoUser.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get deviceInfoUser;

  /// No description provided for @deviceInfoLastConnection.
  ///
  /// In fr, this message translates to:
  /// **'Dernière connexion'**
  String get deviceInfoLastConnection;

  /// No description provided for @deviceInfoNetwork.
  ///
  /// In fr, this message translates to:
  /// **'Réseau'**
  String get deviceInfoNetwork;

  /// No description provided for @deviceInfoInterfacesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =1{1 interface} other{{count} interfaces}}'**
  String deviceInfoInterfacesCount(int count);

  /// No description provided for @deviceInfoIpAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse IP'**
  String get deviceInfoIpAddress;

  /// No description provided for @deviceInfoSubnetMask.
  ///
  /// In fr, this message translates to:
  /// **'Masque'**
  String get deviceInfoSubnetMask;

  /// No description provided for @deviceInfoGateway.
  ///
  /// In fr, this message translates to:
  /// **'Passerelle'**
  String get deviceInfoGateway;

  /// No description provided for @deviceInfoPrimaryDns.
  ///
  /// In fr, this message translates to:
  /// **'DNS primaire'**
  String get deviceInfoPrimaryDns;

  /// No description provided for @deviceInfoMacAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse MAC'**
  String get deviceInfoMacAddress;

  /// No description provided for @deviceInfoCopied.
  ///
  /// In fr, this message translates to:
  /// **'{label} copié'**
  String deviceInfoCopied(String label);

  /// No description provided for @deviceInfoBacnetObjects.
  ///
  /// In fr, this message translates to:
  /// **'Objets BACnet'**
  String get deviceInfoBacnetObjects;

  /// No description provided for @deviceInfoTotalObjects.
  ///
  /// In fr, this message translates to:
  /// **'Total : {count} objets'**
  String deviceInfoTotalObjects(int count);

  /// No description provided for @deviceInfoNoDataAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée disponible'**
  String get deviceInfoNoDataAvailable;

  /// No description provided for @deviceInfoTechnical.
  ///
  /// In fr, this message translates to:
  /// **'Informations techniques'**
  String get deviceInfoTechnical;

  /// No description provided for @deviceInfoHostName.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'hôte'**
  String get deviceInfoHostName;

  /// No description provided for @homeAuthenticating.
  ///
  /// In fr, this message translates to:
  /// **'Authentification...'**
  String get homeAuthenticating;

  /// No description provided for @homeFetchingData.
  ///
  /// In fr, this message translates to:
  /// **'Récupération des données...'**
  String get homeFetchingData;

  /// No description provided for @homeSynoptic.
  ///
  /// In fr, this message translates to:
  /// **'Synoptique'**
  String get homeSynoptic;

  /// No description provided for @homeControllerTimeTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Heure automate : {time}'**
  String homeControllerTimeTooltip(String time);

  /// No description provided for @homeTimeOffsetTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Décalage : {offset}'**
  String homeTimeOffsetTooltip(String offset);

  /// No description provided for @homeControllerTimeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Heure de l\'automate'**
  String get homeControllerTimeTitle;

  /// No description provided for @homeControllerDateTime.
  ///
  /// In fr, this message translates to:
  /// **'Date/Heure automate'**
  String get homeControllerDateTime;

  /// No description provided for @homeLocalTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure locale'**
  String get homeLocalTime;

  /// No description provided for @homeTimeOffset.
  ///
  /// In fr, this message translates to:
  /// **'Décalage'**
  String get homeTimeOffset;

  /// No description provided for @homeTimeOffsetWarning.
  ///
  /// In fr, this message translates to:
  /// **'L\'heure de l\'automate est décalée. Les plannings peuvent ne pas s\'exécuter aux moments attendus.'**
  String get homeTimeOffsetWarning;

  /// No description provided for @homeSyncV2Info.
  ///
  /// In fr, this message translates to:
  /// **'API V2 : utilisez l\'interface web EC-NetAX ou configurez le NTP pour synchroniser l\'heure.'**
  String get homeSyncV2Info;

  /// No description provided for @homeSyncSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation réussie avec succès !'**
  String get homeSyncSuccess;

  /// No description provided for @homeSyncFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la synchronisation.'**
  String get homeSyncFailed;

  /// No description provided for @homeSyncing.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation...'**
  String get homeSyncing;

  /// No description provided for @homeSync.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser'**
  String get homeSync;

  /// No description provided for @routerPageNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Page non trouvée : {path}'**
  String routerPageNotFound(String path);

  /// No description provided for @routerInvalidId.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant invalide : \"{id}\"'**
  String routerInvalidId(String id);

  /// No description provided for @connectionsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, =0{0 connexion} =1{1 connexion} other{{count} connexions}}'**
  String connectionsCount(int count);

  /// No description provided for @connectionsEmptyFolder.
  ///
  /// In fr, this message translates to:
  /// **'Dossier vide'**
  String get connectionsEmptyFolder;

  /// No description provided for @connectionsFolderName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du dossier'**
  String get connectionsFolderName;

  /// No description provided for @connectionsEditFolder.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le dossier'**
  String get connectionsEditFolder;

  /// No description provided for @connectionsDeleteFolder.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le dossier'**
  String get connectionsDeleteFolder;

  /// No description provided for @connectionsDeleteFolderMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous supprimer le dossier \"{name}\" ?\n\nLes connexions qu\'il contient seront déplacées à la racine.'**
  String connectionsDeleteFolderMessage(String name);

  /// No description provided for @connectionsFolderDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Dossier \"{name}\" supprimé'**
  String connectionsFolderDeleted(String name);

  /// No description provided for @connectionsDeleteConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous supprimer \"{name}\" ?'**
  String connectionsDeleteConfirm(String name);

  /// No description provided for @connectionsDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Connexion \"{name}\" supprimée'**
  String connectionsDeleted(String name);

  /// No description provided for @connectionsMoveTo.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer vers'**
  String get connectionsMoveTo;

  /// No description provided for @connectionsMoved.
  ///
  /// In fr, this message translates to:
  /// **'Connexion déplacée'**
  String get connectionsMoved;

  /// No description provided for @connectionsAddToStart.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez une connexion pour commencer'**
  String get connectionsAddToStart;

  /// No description provided for @connectionsMove.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer'**
  String get connectionsMove;

  /// No description provided for @connectionsRefreshFolderTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Rafraîchir tous les super favoris du dossier'**
  String get connectionsRefreshFolderTooltip;

  /// No description provided for @connectionsRefreshValuesTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Rafraîchir les valeurs'**
  String get connectionsRefreshValuesTooltip;

  /// No description provided for @addConnSelected.
  ///
  /// In fr, this message translates to:
  /// **'{name} sélectionné'**
  String addConnSelected(String name);

  /// No description provided for @addConnUseSecure.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser une connexion sécurisée'**
  String get addConnUseSecure;

  /// No description provided for @addConnConnectionType.
  ///
  /// In fr, this message translates to:
  /// **'Type de connexion'**
  String get addConnConnectionType;

  /// No description provided for @addConnBacnetSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Connexion BACnet réussie ! Device ID : {deviceId}'**
  String addConnBacnetSuccess(String deviceId);

  /// No description provided for @addConnNotDiscovered.
  ///
  /// In fr, this message translates to:
  /// **'non découvert'**
  String get addConnNotDiscovered;

  /// No description provided for @addConnBacnetFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la connexion BACnet'**
  String get addConnBacnetFailed;

  /// No description provided for @addConnUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Connexion modifiée'**
  String get addConnUpdated;

  /// No description provided for @addConnSaved.
  ///
  /// In fr, this message translates to:
  /// **'Connexion enregistrée'**
  String get addConnSaved;

  /// No description provided for @discoverMdnsError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur mDNS'**
  String get discoverMdnsError;

  /// No description provided for @discoverSearchingEclypse.
  ///
  /// In fr, this message translates to:
  /// **'Recherche des automates ECLYPSE sur le réseau...'**
  String get discoverSearchingEclypse;

  /// No description provided for @discoverNoEclypseFoundMessage.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ECLYPSE n\'a été trouvé sur le réseau.\nVérifiez que vous êtes connecté au même réseau que l\'automate.'**
  String get discoverNoEclypseFoundMessage;

  /// No description provided for @discoverProbing.
  ///
  /// In fr, this message translates to:
  /// **'Détection API…'**
  String get discoverProbing;

  /// No description provided for @discoverApiAdvertised.
  ///
  /// In fr, this message translates to:
  /// **'API {version} annoncée'**
  String discoverApiAdvertised(String version);

  /// No description provided for @discoverApiUnknown.
  ///
  /// In fr, this message translates to:
  /// **'API détectée à la connexion'**
  String get discoverApiUnknown;

  /// No description provided for @discoverUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Injoignable'**
  String get discoverUnreachable;

  /// No description provided for @discoverModel.
  ///
  /// In fr, this message translates to:
  /// **'Modèle : {model}'**
  String discoverModel(String model);

  /// No description provided for @discoverFirmware.
  ///
  /// In fr, this message translates to:
  /// **'Firmware : {version}'**
  String discoverFirmware(String version);

  /// No description provided for @discoverFirmwareAfterLogin.
  ///
  /// In fr, this message translates to:
  /// **'Firmware visible après connexion'**
  String get discoverFirmwareAfterLogin;

  /// No description provided for @discoverCreateConnection.
  ///
  /// In fr, this message translates to:
  /// **'Créer la connexion'**
  String get discoverCreateConnection;

  /// No description provided for @discoverDeviceIdConflictWithId.
  ///
  /// In fr, this message translates to:
  /// **'Conflit Device ID {deviceId}'**
  String discoverDeviceIdConflictWithId(String deviceId);

  /// No description provided for @alarmsSortNewest.
  ///
  /// In fr, this message translates to:
  /// **'Plus récentes'**
  String get alarmsSortNewest;

  /// No description provided for @alarmsSortOldest.
  ///
  /// In fr, this message translates to:
  /// **'Plus anciennes'**
  String get alarmsSortOldest;

  /// No description provided for @bacnetTypeAnalogInput.
  ///
  /// In fr, this message translates to:
  /// **'Entrée Analogique'**
  String get bacnetTypeAnalogInput;

  /// No description provided for @bacnetTypeAnalogOutput.
  ///
  /// In fr, this message translates to:
  /// **'Sortie Analogique'**
  String get bacnetTypeAnalogOutput;

  /// No description provided for @bacnetTypeAnalogValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur Analogique'**
  String get bacnetTypeAnalogValue;

  /// No description provided for @bacnetTypeBinaryInput.
  ///
  /// In fr, this message translates to:
  /// **'Entrée Binaire'**
  String get bacnetTypeBinaryInput;

  /// No description provided for @bacnetTypeBinaryOutput.
  ///
  /// In fr, this message translates to:
  /// **'Sortie Binaire'**
  String get bacnetTypeBinaryOutput;

  /// No description provided for @bacnetTypeBinaryValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur Binaire'**
  String get bacnetTypeBinaryValue;

  /// No description provided for @bacnetTypeMultiStateInput.
  ///
  /// In fr, this message translates to:
  /// **'Entrée Multi-états'**
  String get bacnetTypeMultiStateInput;

  /// No description provided for @bacnetTypeMultiStateOutput.
  ///
  /// In fr, this message translates to:
  /// **'Sortie Multi-états'**
  String get bacnetTypeMultiStateOutput;

  /// No description provided for @bacnetTypeMultiStateValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur Multi-états'**
  String get bacnetTypeMultiStateValue;

  /// No description provided for @bacnetTypeSchedule.
  ///
  /// In fr, this message translates to:
  /// **'Horaire'**
  String get bacnetTypeSchedule;

  /// No description provided for @bacnetTypeCalendar.
  ///
  /// In fr, this message translates to:
  /// **'Calendrier'**
  String get bacnetTypeCalendar;

  /// No description provided for @bacnetTypeTrendLog.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get bacnetTypeTrendLog;

  /// No description provided for @bacnetTypeNotificationClass.
  ///
  /// In fr, this message translates to:
  /// **'Classe de notification'**
  String get bacnetTypeNotificationClass;

  /// No description provided for @bacnetTypeDevice.
  ///
  /// In fr, this message translates to:
  /// **'Appareil'**
  String get bacnetTypeDevice;

  /// No description provided for @scheduleDayShortMonday.
  ///
  /// In fr, this message translates to:
  /// **'Lun'**
  String get scheduleDayShortMonday;

  /// No description provided for @scheduleDayShortTuesday.
  ///
  /// In fr, this message translates to:
  /// **'Mar'**
  String get scheduleDayShortTuesday;

  /// No description provided for @scheduleDayShortWednesday.
  ///
  /// In fr, this message translates to:
  /// **'Mer'**
  String get scheduleDayShortWednesday;

  /// No description provided for @scheduleDayShortThursday.
  ///
  /// In fr, this message translates to:
  /// **'Jeu'**
  String get scheduleDayShortThursday;

  /// No description provided for @scheduleDayShortFriday.
  ///
  /// In fr, this message translates to:
  /// **'Ven'**
  String get scheduleDayShortFriday;

  /// No description provided for @scheduleDayShortSaturday.
  ///
  /// In fr, this message translates to:
  /// **'Sam'**
  String get scheduleDayShortSaturday;

  /// No description provided for @scheduleDayShortSunday.
  ///
  /// In fr, this message translates to:
  /// **'Dim'**
  String get scheduleDayShortSunday;

  /// No description provided for @scheduleNewSlot.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau créneau'**
  String get scheduleNewSlot;

  /// No description provided for @scheduleEditSlot.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le créneau'**
  String get scheduleEditSlot;

  /// No description provided for @scheduleNewTransition.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle transition'**
  String get scheduleNewTransition;

  /// No description provided for @scheduleAllDay.
  ///
  /// In fr, this message translates to:
  /// **'Toute la journée'**
  String get scheduleAllDay;

  /// No description provided for @scheduleStartTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure de début'**
  String get scheduleStartTime;

  /// No description provided for @scheduleEndTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure de fin'**
  String get scheduleEndTime;

  /// No description provided for @scheduleTime.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get scheduleTime;

  /// No description provided for @scheduleEndAfterStartError.
  ///
  /// In fr, this message translates to:
  /// **'L\'heure de fin doit être après l\'heure de début'**
  String get scheduleEndAfterStartError;

  /// No description provided for @scheduleDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée: {duration}'**
  String scheduleDuration(String duration);

  /// No description provided for @scheduleSelectTime.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner l\'heure'**
  String get scheduleSelectTime;

  /// No description provided for @scheduleMidnightEndOfDay.
  ///
  /// In fr, this message translates to:
  /// **'Minuit (fin de journée)'**
  String get scheduleMidnightEndOfDay;

  /// No description provided for @scheduleCopyDay.
  ///
  /// In fr, this message translates to:
  /// **'Copier ce jour'**
  String get scheduleCopyDay;

  /// No description provided for @schedulePasteHereFrom.
  ///
  /// In fr, this message translates to:
  /// **'Coller ici (depuis {day})'**
  String schedulePasteHereFrom(String day);

  /// No description provided for @schedulePasteFrom.
  ///
  /// In fr, this message translates to:
  /// **'Coller depuis {day}'**
  String schedulePasteFrom(String day);

  /// No description provided for @schedulePasteToWorkDays.
  ///
  /// In fr, this message translates to:
  /// **'Coller sur jours ouvrés'**
  String get schedulePasteToWorkDays;

  /// No description provided for @scheduleWorkDaysRange.
  ///
  /// In fr, this message translates to:
  /// **'Lun-Ven'**
  String get scheduleWorkDaysRange;

  /// No description provided for @schedulePasteToAllDays.
  ///
  /// In fr, this message translates to:
  /// **'Coller sur tous les jours'**
  String get schedulePasteToAllDays;

  /// No description provided for @scheduleClearDay.
  ///
  /// In fr, this message translates to:
  /// **'Effacer ce jour'**
  String get scheduleClearDay;

  /// No description provided for @scheduleDayCopied.
  ///
  /// In fr, this message translates to:
  /// **'{day} copié'**
  String scheduleDayCopied(String day);

  /// No description provided for @schedulePastedToWorkDays.
  ///
  /// In fr, this message translates to:
  /// **'Collé sur les jours ouvrés'**
  String get schedulePastedToWorkDays;

  /// No description provided for @schedulePastedToAllDays.
  ///
  /// In fr, this message translates to:
  /// **'Collé sur tous les jours'**
  String get schedulePastedToAllDays;

  /// No description provided for @scheduleMoreActions.
  ///
  /// In fr, this message translates to:
  /// **'Plus d\'actions'**
  String get scheduleMoreActions;

  /// No description provided for @scheduleSaveConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder le planning ?'**
  String get scheduleSaveConfirmTitle;

  /// No description provided for @scheduleSaveConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Les modifications seront envoyées à l\'automate et prendront effet immédiatement.'**
  String get scheduleSaveConfirmMessage;

  /// No description provided for @scheduleDiscardConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler les modifications ?'**
  String get scheduleDiscardConfirmTitle;

  /// No description provided for @scheduleDiscardConfirmMessage.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les modifications non sauvegardées seront perdues.'**
  String get scheduleDiscardConfirmMessage;

  /// No description provided for @scheduleContinueEditing.
  ///
  /// In fr, this message translates to:
  /// **'Continuer l\'édition'**
  String get scheduleContinueEditing;

  /// No description provided for @scheduleDeleteTransitionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette transition ?'**
  String get scheduleDeleteTransitionTitle;

  /// No description provided for @scheduleDeleteSlotTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce créneau ?'**
  String get scheduleDeleteSlotTitle;

  /// No description provided for @scheduleNoTransition.
  ///
  /// In fr, this message translates to:
  /// **'Aucune transition'**
  String get scheduleNoTransition;

  /// No description provided for @scheduleNoScheduledTransition.
  ///
  /// In fr, this message translates to:
  /// **'Aucune transition programmée'**
  String get scheduleNoScheduledTransition;

  /// No description provided for @scheduleTapPlusToAdd.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez sur + pour ajouter'**
  String get scheduleTapPlusToAdd;

  /// No description provided for @scheduleAddSlot.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un créneau'**
  String get scheduleAddSlot;

  /// No description provided for @scheduleFullDay.
  ///
  /// In fr, this message translates to:
  /// **'Journée'**
  String get scheduleFullDay;

  /// No description provided for @scheduleEditDayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier - {day}'**
  String scheduleEditDayTitle(String day);

  /// No description provided for @scheduleAddDayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter - {day}'**
  String scheduleAddDayTitle(String day);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
