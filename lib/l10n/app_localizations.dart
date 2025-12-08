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
  /// **'MyDumControl'**
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
