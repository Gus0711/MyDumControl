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
