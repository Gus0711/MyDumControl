// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MyGlobalDC';

  @override
  String get connections => 'Connexions';

  @override
  String get addConnection => 'Ajouter une connexion';

  @override
  String get editConnection => 'Modifier la connexion';

  @override
  String get deleteConnection => 'Supprimer la connexion';

  @override
  String get connectionName => 'Nom de la connexion';

  @override
  String get host => 'Hôte';

  @override
  String get port => 'Port';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get password => 'Mot de passe';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get connect => 'Connecter';

  @override
  String get disconnect => 'Déconnecter';

  @override
  String get testConnection => 'Tester la connexion';

  @override
  String get connectionSuccess => 'Connexion réussie';

  @override
  String get connectionFailed => 'Échec de la connexion';

  @override
  String get noConnections => 'Aucune connexion enregistrée';

  @override
  String get home => 'Accueil';

  @override
  String get points => 'Points';

  @override
  String get physicalInputs => 'Entrées physiques';

  @override
  String get physicalOutputs => 'Sorties physiques';

  @override
  String get analogValues => 'Valeurs analogiques';

  @override
  String get alarms => 'Alarmes';

  @override
  String get activeAlarms => 'Alarmes actives';

  @override
  String get noAlarms => 'Aucune alarme active';

  @override
  String get acknowledge => 'Acquitter';

  @override
  String get schedules => 'Horaires';

  @override
  String get overrides => 'Forçages';

  @override
  String get favorites => 'Favoris';

  @override
  String get addToFavorites => 'Ajouter aux favoris';

  @override
  String get removeFromFavorites => 'Retirer des favoris';

  @override
  String get pidLoops => 'Boucles PID';

  @override
  String get settings => 'Paramètres';

  @override
  String get deviceInfo => 'Informations appareil';

  @override
  String get appSettings => 'Paramètres de l\'application';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get systemMode => 'Système';

  @override
  String get about => 'À propos';

  @override
  String get version => 'Version';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get retry => 'Réessayer';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get search => 'Rechercher';

  @override
  String get refresh => 'Actualiser';

  @override
  String get connected => 'Connecté';

  @override
  String get disconnected => 'Déconnecté';

  @override
  String get connecting => 'Connexion en cours...';

  @override
  String get apiVersion => 'Version API';

  @override
  String get autoDetect => 'Détection automatique';

  @override
  String get certificateWarning => 'Certificat auto-signé';

  @override
  String get trustCertificate => 'Faire confiance à ce certificat';

  @override
  String get certificateDetails => 'Détails du certificat';

  @override
  String get fingerprint => 'Empreinte';

  @override
  String get value => 'Valeur';

  @override
  String get unit => 'Unité';

  @override
  String get status => 'Statut';

  @override
  String get lastUpdate => 'Dernière mise à jour';

  @override
  String get writeValue => 'Écrire une valeur';

  @override
  String get overrideValue => 'Forcer la valeur';

  @override
  String get releaseOverride => 'Libérer le forçage';

  @override
  String get monday => 'Lundi';

  @override
  String get tuesday => 'Mardi';

  @override
  String get wednesday => 'Mercredi';

  @override
  String get thursday => 'Jeudi';

  @override
  String get friday => 'Vendredi';

  @override
  String get saturday => 'Samedi';

  @override
  String get sunday => 'Dimanche';

  @override
  String get deleteConfirmTitle => 'Confirmer la suppression';

  @override
  String get deleteConfirmMessage =>
      'Êtes-vous sûr de vouloir supprimer cet élément ?';

  @override
  String get fieldRequired => 'Ce champ est requis';

  @override
  String get invalidHost => 'Hôte invalide';

  @override
  String get invalidPort => 'Port invalide (1-65535)';

  @override
  String get offline => 'Hors ligne';

  @override
  String get online => 'En ligne';

  @override
  String get appearance => 'Apparence';

  @override
  String get connection => 'Connexion';

  @override
  String get display => 'Affichage';

  @override
  String get data => 'Données';

  @override
  String get themeSystem => 'Système (auto)';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get connectionTimeout => 'Timeout de connexion';

  @override
  String get seconds => 'secondes';

  @override
  String secondsValue(Object count) {
    return '$count secondes';
  }

  @override
  String get autoRefresh => 'Rafraîchissement auto';

  @override
  String get disabled => 'Désactivé';

  @override
  String everySeconds(Object count) {
    return 'Toutes les $count secondes';
  }

  @override
  String get defaultBacnetPort => 'Port BACnet par défaut';

  @override
  String get temperatureUnit => 'Unité de température';

  @override
  String get celsius => 'Celsius (°C)';

  @override
  String get fahrenheit => 'Fahrenheit (°F)';

  @override
  String get format24Hour => 'Format 24 heures';

  @override
  String get decimalPlaces => 'Décimales affichées';

  @override
  String decimalPlacesValue(Object count) {
    return '$count décimale(s)';
  }

  @override
  String example(Object value) {
    return 'Ex: $value';
  }

  @override
  String get clearCache => 'Vider le cache';

  @override
  String get clearCacheSubtitle => 'Supprime les données mises en cache';

  @override
  String get clearCacheConfirm => 'Vider le cache ?';

  @override
  String get clearCacheMessage =>
      'Cette action supprimera toutes les données en cache. Les données seront rechargées lors de la prochaine connexion.';

  @override
  String get clear => 'Vider';

  @override
  String get cacheCleared => 'Cache vidé avec succès';

  @override
  String get exportConnections => 'Exporter les connexions';

  @override
  String get exportConnectionsSubtitle => 'Sauvegarde en fichier JSON';

  @override
  String exportError(Object error) {
    return 'Erreur d\'export: $error';
  }

  @override
  String get importConnections => 'Importer des connexions';

  @override
  String get importConnectionsSubtitle => 'Restaurer depuis un fichier JSON';

  @override
  String importError(Object error) {
    return 'Erreur d\'import: $error';
  }

  @override
  String get openSourceLicenses => 'Licences open source';

  @override
  String get resetSettings => 'Réinitialiser les paramètres';

  @override
  String get resetSettingsSubtitle => 'Rétablit les valeurs par défaut';

  @override
  String get resetConfirm => 'Réinitialiser ?';

  @override
  String get resetMessage =>
      'Tous les paramètres seront remis à leurs valeurs par défaut.';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get settingsReset => 'Paramètres réinitialisés';

  @override
  String get ok => 'OK';

  @override
  String get eclypseManagement => 'Gestion des automates ECLYPSE';

  @override
  String get supportsApiBacnet =>
      'Supporte les API V1 et V2 ainsi que le protocole BACnet/IP.';

  @override
  String get invalidPointId => 'ID de point invalide';

  @override
  String get invalidInstance => 'Instance invalide';

  @override
  String unknownType(Object type) {
    return 'Type inconnu: $type';
  }

  @override
  String get pointNotFound => 'Point non trouvé';

  @override
  String pointNotFoundMessage(Object instance, Object type) {
    return 'Point $type:$instance non trouvé';
  }

  @override
  String get reloadPoints => 'Recharger les points';

  @override
  String get alarm => 'ALARME';

  @override
  String forcedP(Object priority) {
    return 'Forcé P$priority';
  }

  @override
  String get outOfService => 'Hors service';

  @override
  String get set => 'Régler';

  @override
  String get force => 'Forcer';

  @override
  String get auto => 'Auto';

  @override
  String get forcingOutOfService => 'Forçage (out-of-service)';

  @override
  String get forcingPriority1 => 'Forçage (priorité 1)';

  @override
  String get typeNotEditable => 'Type non éditable';

  @override
  String get enterValue => 'Entrez une valeur';

  @override
  String get invalidValue => 'Valeur invalide';

  @override
  String get state => 'État';

  @override
  String get enterState => 'Entrez un état';

  @override
  String get invalidStateMin1 => 'État invalide (min: 1)';

  @override
  String selectedState(Object state, Object value) {
    return 'État sélectionné: $state ($value)';
  }

  @override
  String get inProgress => 'En cours...';

  @override
  String get inputForced => 'Entrée forcée (out-of-service)';

  @override
  String get valueSet => 'Valeur réglée';

  @override
  String get valueForcedPriority1 => 'Valeur forcée (priorité 1)';

  @override
  String get pointSetToAuto => 'Point remis en Auto';

  @override
  String get errorSettingAuto => 'Erreur lors de la mise en Auto';

  @override
  String get writeError => 'Erreur lors de l\'écriture';

  @override
  String get pointInAlarm => 'Point en Alarme';

  @override
  String get alarmTriggeredMessage =>
      'Ce point a déclenché une alarme (status-flags.in-alarm = true).';

  @override
  String get pointForced => 'Point Forcé';

  @override
  String get priority => 'Priorité';

  @override
  String level(Object level) {
    return 'Niveau $level';
  }

  @override
  String get forcedValue => 'Valeur forcée';

  @override
  String get release => 'Libérer';

  @override
  String get emergency => 'Urgence';

  @override
  String get inputForcedTitle => 'Entrée Forcée';

  @override
  String get inputForcedMessage =>
      'Cette entrée est hors service (out-of-service = true).\nLa valeur affichée est forcée manuellement.';

  @override
  String get releaseInput => 'Libérer l\'entrée';

  @override
  String get inputReleased => 'Entrée libérée (out-of-service = false)';

  @override
  String get inputReleaseError => 'Erreur lors de la libération de l\'entrée';

  @override
  String get overrideReleased => 'Forçage libéré';

  @override
  String get releaseError => 'Erreur lors de la libération';

  @override
  String get emergencyRelease => 'Libération d\'urgence';

  @override
  String get emergencyReleaseMessage =>
      'Cette action va libérer TOUTES les priorités (1-16) du point.\n\nLe point retournera en mode complètement automatique.\n\nContinuer ?';

  @override
  String get releaseAll => 'Libérer tout';

  @override
  String get allPrioritiesReleased => 'Toutes les priorités libérées';

  @override
  String get emergencyReleaseError => 'Erreur lors de la libération d\'urgence';

  @override
  String get information => 'Informations';

  @override
  String get name => 'Nom';

  @override
  String get description => 'Description';

  @override
  String get identifier => 'Identifiant';

  @override
  String get type => 'Type';

  @override
  String get instance => 'Instance';

  @override
  String get properties => 'Propriétés';

  @override
  String get active => 'Actif';

  @override
  String get inactive => 'Inactif';

  @override
  String get editDescription => 'Modifier la description';

  @override
  String get descriptionHint => 'Entrez une description...';

  @override
  String get descriptionUpdated => 'Description mise à jour';

  @override
  String get descriptionUpdateError => 'Erreur lors de la mise à jour';

  @override
  String get noDescription => 'Aucune description';

  @override
  String get loadingEllipsis => 'Chargement...';

  @override
  String get modified => 'Modifié';

  @override
  String get editMode => 'Mode édition';

  @override
  String get cancelChanges => 'Annuler les modifications';

  @override
  String get saveChanges => 'Sauvegarder';

  @override
  String get closeEdit => 'Fermer l\'édition';

  @override
  String get edit => 'Modifier';

  @override
  String get scheduleNotFound => 'Schedule non trouvé';

  @override
  String get weeklyScheduleUnreadable =>
      'Programme hebdomadaire illisible : modification désactivée pour ne pas écraser l\'automate';

  @override
  String get errorLoadingSchedule => 'Erreur lors du chargement';

  @override
  String get discardChanges => 'Abandonner les modifications';

  @override
  String get discardChangesMessage =>
      'Vous avez des modifications non sauvegardées. Voulez-vous les abandonner ?';

  @override
  String get discard => 'Abandonner';

  @override
  String get keep => 'Garder';

  @override
  String get loadingPoints => 'Chargement des points...';

  @override
  String noResultsFor(Object query) {
    return 'Aucun résultat pour \"$query\"';
  }

  @override
  String get sort => 'Trier';

  @override
  String alarmsCount(Object count) {
    return '$count alarme(s) active(s)';
  }

  @override
  String get searchAlarm => 'Rechercher une alarme...';

  @override
  String get searchPoint => 'Rechercher un point...';

  @override
  String get statisticsPoints => 'Points';

  @override
  String get statisticsMin => 'Min';

  @override
  String get statisticsMax => 'Max';

  @override
  String get statisticsAvg => 'Moy';

  @override
  String get start => 'Début';

  @override
  String get end => 'Fin';

  @override
  String get minus15 => '-15';

  @override
  String get plus15 => '+15';

  @override
  String transitionAt(Object state, Object time) {
    return 'Transition à $time → $state';
  }

  @override
  String timeState(Object state, Object time) {
    return '$time : $state';
  }

  @override
  String currentState(Object state) {
    return 'Actuel: $state';
  }

  @override
  String instanceLabel(Object instance) {
    return 'Instance $instance';
  }

  @override
  String get allEquipmentNormal =>
      'Tous les équipements fonctionnent normalement';

  @override
  String agoMinutes(Object count) {
    return 'il y a $count min';
  }

  @override
  String agoHours(Object count) {
    return 'il y a $count h';
  }

  @override
  String agoDays(Object count) {
    return 'il y a $count jour(s)';
  }

  @override
  String get autoRefreshDisabled => 'Auto-refresh désactivé';

  @override
  String autoRefreshLabel(Object label) {
    return 'Auto-refresh: $label';
  }

  @override
  String get loadingValuesProgress => 'Chargement des valeurs en cours...';

  @override
  String get allPoints => 'Tous';

  @override
  String noPointSubType(Object subType) {
    return 'Aucun point $subType';
  }

  @override
  String get noPointInCategory => 'Aucun point dans cette catégorie';

  @override
  String get trendLogAvailable => 'Trend log disponible';

  @override
  String get plannings => 'Plannings';

  @override
  String get loadingError => 'Erreur de chargement';

  @override
  String get noPlanning => 'Aucun planning';

  @override
  String get noScheduleConfigured =>
      'Cet automate n\'a pas de schedules configurés.';

  @override
  String get onOff => 'On/Off';

  @override
  String get multiState => 'Multi-états';

  @override
  String get boolean => 'Booléen';

  @override
  String scheduleInstance(Object instance) {
    return 'Schedule $instance';
  }

  @override
  String get editModeTapSlot => 'Mode édition - Appuyez sur un créneau';

  @override
  String get editModeTapDay =>
      'Mode édition - Appuyez sur un jour pour modifier';

  @override
  String get legend => 'Légende :';

  @override
  String selectedCount(Object count) {
    return '$count sélectionné(s)';
  }

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get deselectAll => 'Tout désélectionner';

  @override
  String get selectionMode => 'Mode sélection';

  @override
  String get newFolder => 'Nouveau dossier';

  @override
  String get notConnected => 'Non connecté';

  @override
  String get connectToViewFavorites =>
      'Connectez-vous à un automate pour voir vos favoris';

  @override
  String get noFavorite => 'Aucun favori';

  @override
  String get addFavoritesHint =>
      'Ajoutez des points aux favoris en cliquant\\nsur l\'étoile dans la liste des points';

  @override
  String get viewPoints => 'Voir les points';

  @override
  String get assignToFolders => 'Assigner aux dossiers';

  @override
  String get deleteFavoritesConfirm => 'Supprimer les favoris ?';

  @override
  String deleteFavoritesMessage(Object count) {
    return 'Voulez-vous supprimer $count favori(s) ?';
  }

  @override
  String favoritesAssigned(Object favCount, Object folderCount) {
    return '$favCount favori(s) assigné(s) à $folderCount dossier(s)';
  }

  @override
  String favoritesDeleted(Object count) {
    return '$count favori(s) supprimé(s)';
  }

  @override
  String get createFolderFirst => 'Créez d\'abord un dossier';

  @override
  String get selectFoldersToAdd =>
      'Sélectionnez les dossiers auxquels ajouter les favoris';

  @override
  String get assign => 'Assigner';

  @override
  String get dropHereToAdd => 'Déposez ici pour ajouter';

  @override
  String favoritesCount(Object count) {
    return '$count favori(s)';
  }

  @override
  String get editFolder => 'Modifier';

  @override
  String get deleteFolder => 'Supprimer';

  @override
  String get emptyFolderHint => 'Dossier vide - glissez des favoris ici';

  @override
  String get noFolder => 'Sans dossier';

  @override
  String get deleteFolderConfirm => 'Supprimer le dossier ?';

  @override
  String deleteFolderMessage(Object name) {
    return 'Le dossier \"$name\" sera supprimé.\\n\\nLes favoris qu\'il contient ne seront pas supprimés, ils seront déplacés dans \"Sans dossier\".';
  }

  @override
  String get favoriteAddedToFolder => 'Favori ajouté au dossier';

  @override
  String removedFromFavorites(Object name) {
    return '$name retiré des favoris';
  }

  @override
  String get assignToFoldersDialog => 'Assigner aux dossiers';

  @override
  String get categoryInputs => 'Entrées';

  @override
  String get categoryOutputs => 'Sorties';

  @override
  String get categoryVariables => 'Valeurs';

  @override
  String get categoryOthers => 'Autres';

  @override
  String get categoryAll => 'Tous';

  @override
  String get sortNameAsc => 'Nom (A→Z)';

  @override
  String get sortNameDesc => 'Nom (Z→A)';

  @override
  String get sortType => 'Type';

  @override
  String get sortValueAsc => 'Valeur ↑';

  @override
  String get sortValueDesc => 'Valeur ↓';

  @override
  String get sortFavoritesFirst => 'Favoris d\'abord';

  @override
  String get subTypeAll => 'Tous';

  @override
  String get subTypeAnalog => 'Analog';

  @override
  String get subTypeBinary => 'Binary';

  @override
  String get subTypeMulti => 'Multi';

  @override
  String get autoRefreshOff => 'Désactivé';

  @override
  String autoRefreshSeconds(Object count) {
    return '$count secondes';
  }

  @override
  String get autoRefreshMinute => '1 minute';

  @override
  String get noOverride => 'Aucun forçage';

  @override
  String get allPointsNormal => 'Tous les points fonctionnent normalement';

  @override
  String get outOfServiceLabel => 'Hors service';

  @override
  String get forcedLabel => 'Forcé';

  @override
  String priorityLabel(Object priority) {
    return 'Priorité $priority';
  }

  @override
  String get bacnetLocalNetworkOnly => 'Réseau local uniquement';

  @override
  String get bacnetLocalNetworkInfo =>
      'BACnet/IP fonctionne uniquement sur le réseau local. Assurez-vous que votre appareil est connecté au même réseau que le contrôleur.';

  @override
  String get bacnetDeviceIdOptional => 'Device ID (optionnel en local)';

  @override
  String get bacnetDeviceIdHelper =>
      'Laissez vide pour découverte automatique sur le réseau local';

  @override
  String get bacnetDeviceIdRemoteRequired =>
      'Requis si vous n\'êtes pas sur le même réseau';

  @override
  String get discoverDevices => 'Découvrir les appareils';

  @override
  String get discovering => 'Recherche en cours...';

  @override
  String get noDeviceFound => 'Aucun appareil BACnet trouvé';

  @override
  String get noDeviceFoundMessage =>
      'Aucun appareil BACnet n\'a répondu sur le réseau local.\n\nVérifiez que :\n• Vous êtes sur le même réseau que le contrôleur\n• Le port UDP 47808 n\'est pas bloqué\n• Le contrôleur est allumé et accessible';

  @override
  String devicesFound(Object count) {
    return '$count appareil(s) trouvé(s)';
  }

  @override
  String get selectDevice => 'Sélectionner un appareil';

  @override
  String get deviceId => 'Device ID';

  @override
  String get vendor => 'Fabricant';

  @override
  String get model => 'Modèle';

  @override
  String get bacnetPortHelper => 'Port BACnet/IP (défaut: 47808)';

  @override
  String get broadcastDiscovery => 'Découverte broadcast';

  @override
  String get broadcastDiscoverySubtitle =>
      'Rechercher tous les appareils BACnet sur le réseau local';

  @override
  String get discoverEclypse => 'Découvrir ECLYPSE';

  @override
  String get discoverEclypseSubtitle => 'Recherche mDNS des automates Distech';

  @override
  String eclypseFound(Object count) {
    return '$count ECLYPSE trouvé(s)';
  }

  @override
  String get scanIpRange => 'Scanner une plage IP';

  @override
  String get scanIpRangeSubtitle =>
      'Scan unicast pour trouver les ECLYPSE et autres';

  @override
  String get startIp => 'IP de début';

  @override
  String get endIp => 'IP de fin';

  @override
  String scanProgress(Object current, Object total) {
    return 'Scan en cours... $current/$total';
  }

  @override
  String get scanning => 'Scan en cours...';

  @override
  String get stopScan => 'Arrêter';

  @override
  String get invalidIpRange => 'Plage IP invalide';

  @override
  String get ipRangeSameSubnet =>
      'Les IPs doivent être sur le même sous-réseau /24';

  @override
  String get scanComplete => 'Scan terminé';

  @override
  String get orManualEntry => 'ou saisie manuelle :';

  @override
  String get useIpScan => 'Scanner plage IP (ECLYPSE)';

  @override
  String get dashboards => 'Dashboards';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get noDashboard => 'Aucun dashboard';

  @override
  String get createDashboardHint =>
      'Créez des dashboards pour visualiser\nvos graphiques et courbes d\'historique';

  @override
  String get createDashboard => 'Créer un dashboard';

  @override
  String get newDashboard => 'Nouveau dashboard';

  @override
  String get editDashboard => 'Modifier le dashboard';

  @override
  String get deleteDashboard => 'Supprimer le dashboard';

  @override
  String get dashboardName => 'Nom du dashboard';

  @override
  String get dashboardNameRequired => 'Le nom est requis';

  @override
  String get deleteDashboardConfirm => 'Supprimer ce dashboard ?';

  @override
  String deleteDashboardMessage(Object name) {
    return 'Le dashboard \"$name\" et tous ses widgets seront supprimés.';
  }

  @override
  String get dashboardDeleted => 'Dashboard supprimé';

  @override
  String widgets(Object count) {
    return '$count widget(s)';
  }

  @override
  String get addWidget => 'Ajouter un widget';

  @override
  String get configureWidget => 'Configurer le widget';

  @override
  String get deleteWidget => 'Supprimer le widget';

  @override
  String get widgetDeleted => 'Widget supprimé';

  @override
  String get singleChart => 'Graphique simple';

  @override
  String get singleChartDescription => 'Affiche l\'historique d\'un seul point';

  @override
  String get multiCurveChart => 'Multi-courbes';

  @override
  String get multiCurveChartDescription =>
      'Compare plusieurs points sur un même graphique';

  @override
  String get statsCard => 'Statistiques';

  @override
  String get statsCardDescription => 'Affiche min, max et moyenne d\'un point';

  @override
  String get selectTrendLog => 'Sélectionnez un trend log';

  @override
  String get noTrendLogSelected => 'Aucun trend log sélectionné';

  @override
  String get selectTrendLogs => 'Sélectionnez les trend logs';

  @override
  String selectedTrendLogs(Object count) {
    return '$count trend log(s) sélectionné(s)';
  }

  @override
  String get minCurvesRequired => 'Sélectionnez au moins 2 trend logs';

  @override
  String get maxCurvesReached => 'Maximum 8 courbes autorisées';

  @override
  String get showMin => 'Afficher minimum';

  @override
  String get showMax => 'Afficher maximum';

  @override
  String get showAvg => 'Afficher moyenne';

  @override
  String get curveVisibility => 'Visibilité des courbes';

  @override
  String get periodDay => 'Jour';

  @override
  String get periodWeek => 'Semaine';

  @override
  String get periodMonth => 'Mois';

  @override
  String get periodYear => 'Année';

  @override
  String get networkInterface => 'Interface réseau';

  @override
  String get allInterfaces => 'Toutes les interfaces';

  @override
  String get searchingBacnetDevices => 'Recherche des appareils BACnet...';

  @override
  String get deviceIdConflict => 'Conflit Device ID';

  @override
  String get deviceIdConflictMessage =>
      'Plusieurs appareils partagent le même Device ID BACnet. Ceci est interdit par le protocole et peut causer des dysfonctionnements.';

  @override
  String get conflictingAddresses => 'Adresses IP en conflit :';

  @override
  String get conflictRecommendation =>
      'Action recommandée : Reconfigurer les appareils pour avoir des Device ID uniques.';

  @override
  String get understood => 'Compris';

  @override
  String get idConflict => 'ID conflit';

  @override
  String get alsoAt => 'Aussi à';

  @override
  String get conflicts => 'conflit(s)';

  @override
  String bacnetPortWarning(int actualPort, int standardPort) {
    return 'Port $actualPort utilisé (standard: $standardPort)';
  }

  @override
  String get bacnetPortConflict => 'Conflit de port BACnet';

  @override
  String bacnetPortConflictDetail(int standardPort, int actualPort) {
    return 'Le port standard BACnet ($standardPort) est déjà utilisé par une autre application. L\'application utilise le port $actualPort à la place.';
  }

  @override
  String get bacnetPortConflictSolution => 'Solutions :';

  @override
  String get bacnetPortSolution1 => 'Fermez YABE ou autres applications BACnet';

  @override
  String get bacnetPortSolution2 => 'Relancez cette application';

  @override
  String get envysionDesignerSection => 'Synoptique Envysion (optionnel)';

  @override
  String get designerUrl => 'URL du Designer';

  @override
  String get designerUrlHelper =>
      'Chemin vers le viewer Envysion intégré au contrôleur';

  @override
  String get synopticEnvysion => 'Synoptique Envysion';

  @override
  String get synopticLocal => 'Synoptiques locaux';

  @override
  String get openInBrowser => 'Ouvrir dans le navigateur';

  @override
  String get webViewNotSupported =>
      'WebView non supportée sur cette plateforme';

  @override
  String webViewNotSupportedMessage(Object platform) {
    return 'L\'affichage intégré n\'est pas disponible sur $platform. Voulez-vous ouvrir dans le navigateur externe ?';
  }

  @override
  String get loadingEnvysion => 'Chargement du synoptique...';

  @override
  String get envysionLoadError => 'Erreur de chargement';

  @override
  String get envysionLoadErrorMessage =>
      'Impossible de charger le synoptique Envysion. Vérifiez l\'URL et votre connexion.';

  @override
  String get certificateChangedTitle => 'Certificat de l\'automate modifié';

  @override
  String get trustNewCertificate => 'Faire confiance au nouveau certificat';

  @override
  String trustNewCertificateMessage(String expected, String received) {
    return 'Le certificat présenté par l\'automate est différent de celui enregistré lors de la première connexion.\n\nCela peut venir d\'un renouvellement du certificat (mise à jour, réinitialisation de l\'automate) ou d\'une interception du trafic. Ne faites confiance au nouveau certificat que si vous êtes sûr qu\'il est légitime.\n\nEmpreinte attendue :\n$expected\n\nNouvelle empreinte :\n$received';
  }

  @override
  String get trust => 'Faire confiance';

  @override
  String get backToConnections => 'Retour aux connexions';

  @override
  String get certificateFingerprintLabel => 'Empreinte du certificat (SHA-256)';

  @override
  String get certificateFingerprintDiffers =>
      'Différente de l\'empreinte enregistrée : le certificat de l\'automate a changé.';

  @override
  String get certificateFingerprintPinnedInfo =>
      'Elle sera enregistrée et vérifiée à chaque connexion.';

  @override
  String get httpCleartextWarning =>
      'HTTP non chiffré : le mot de passe circule en clair sur le réseau. Préférez HTTPS si l\'automate le permet.';

  @override
  String get passwordMissingBadge => 'Mot de passe à ressaisir';

  @override
  String invalidCredentialsMessage(String status) {
    return 'Identifiants invalides ($status). Vérifiez le nom d\'utilisateur et le mot de passe de la connexion.';
  }

  @override
  String get close => 'Fermer';

  @override
  String get add => 'Ajouter';

  @override
  String get rename => 'Renommer';

  @override
  String get create => 'Créer';

  @override
  String get apply => 'Appliquer';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get back => 'Retour';

  @override
  String get copy => 'Copier';

  @override
  String get clearAction => 'Effacer';

  @override
  String get validate => 'Valider';

  @override
  String get details => 'Détails';

  @override
  String get unknown => 'Inconnu';

  @override
  String errorWithMessage(String error) {
    return 'Erreur : $error';
  }

  @override
  String get trendColorBlue => 'Bleu';

  @override
  String get trendColorGreen => 'Vert';

  @override
  String get trendColorOrange => 'Orange';

  @override
  String get trendColorPurple => 'Violet';

  @override
  String get trendColorRed => 'Rouge';

  @override
  String get trendColorCyan => 'Cyan';

  @override
  String get trendColorTeal => 'Sarcelle';

  @override
  String get trendColorIndigo => 'Indigo';

  @override
  String get trendPeriodHour => '1h';

  @override
  String get trendPeriodDay => '24h';

  @override
  String get trendPeriodWeek => '7j';

  @override
  String get trendPeriodMonth => '30j';

  @override
  String get trendPeriodAll => 'Tout';

  @override
  String get trendPeriodCustom => 'Perso.';

  @override
  String get trendChangeColor => 'Changer la couleur';

  @override
  String get trendAnnotations => 'Annotations';

  @override
  String get trendMinMaxMarkers => 'Marqueurs Min/Max';

  @override
  String get trendAverageLine => 'Ligne moyenne';

  @override
  String get trendMinLine => 'Ligne minimum';

  @override
  String get trendMaxLine => 'Ligne maximum';

  @override
  String get trendHideAll => 'Tout masquer';

  @override
  String get trendNoDataForPeriod => 'Aucune donnée pour cette période';

  @override
  String get trendDateTime => 'Date/Heure';

  @override
  String get trendHistory => 'Historique';

  @override
  String get trendFullscreen => 'Plein écran';

  @override
  String get trendShowChart => 'Voir graphique';

  @override
  String get trendShowTable => 'Voir tableau';

  @override
  String get trendExportCsv => 'Exporter CSV';

  @override
  String trendExportSubject(String name) {
    return 'Export historique $name';
  }

  @override
  String get trendPortraitMode => 'Mode portrait';

  @override
  String get trendLandscapeMode => 'Mode paysage';

  @override
  String get trendNoNumericData => 'Aucune donnée numérique';

  @override
  String get trendNoDataToDisplay => 'Aucune donnée à afficher';

  @override
  String get trendInvalidData => 'Données invalides';

  @override
  String trendAvgLineLabel(String value) {
    return 'Moy : $value';
  }

  @override
  String chartComparisonTitle(int count) {
    return 'Comparaison ($count courbes)';
  }

  @override
  String get chartAddCurve => 'Ajouter une courbe';

  @override
  String chartCurvesNotLoaded(int count) {
    return '$count courbe(s) non chargée(s)';
  }

  @override
  String get chartNoVisibleCurve =>
      'Aucune courbe visible\nTouchez la légende pour afficher';

  @override
  String get chartNoCurveSelected =>
      'Aucune courbe sélectionnée\nAjoutez des trend logs à comparer';

  @override
  String get chartSelectCurves => 'Sélectionner les courbes';

  @override
  String chartSelectCurvesHint(int min, int max) {
    return 'Sélectionnez $min à $max trend logs à comparer';
  }

  @override
  String chartCurvesCount(int selected, int max) {
    return '$selected/$max courbes';
  }

  @override
  String get chartNoTrendLogAvailable => 'Aucun trend log disponible';

  @override
  String get chartSelectedCurves => 'Courbes sélectionnées :';

  @override
  String chartValidateCount(int count) {
    return 'Valider ($count)';
  }

  @override
  String get widgetPromoteSuperFavorite => 'Promouvoir en super favori';

  @override
  String get widgetDemoteToFavorite => 'Rétrograder en favori';

  @override
  String get widgetNoFolder => 'Aucun dossier';

  @override
  String get widgetCreateFolder => 'Créer un dossier';

  @override
  String get widgetNewFolderEllipsis => 'Nouveau dossier...';

  @override
  String get widgetEditFolder => 'Modifier le dossier';

  @override
  String get widgetFolderName => 'Nom du dossier';

  @override
  String get widgetColor => 'Couleur';

  @override
  String get widgetIcon => 'Icône';

  @override
  String get widgetConnecting => 'Connexion en cours';

  @override
  String get widgetStepAuth => 'Auth';

  @override
  String get widgetPumpLabel => 'POMPE';

  @override
  String get synopticsTitle => 'Synoptiques';

  @override
  String get synopticCreate => 'Créer un synoptique';

  @override
  String get synopticEmptyTitle => 'Aucun synoptique';

  @override
  String get synopticEmptyHint =>
      'Créez votre premier synoptique pour visualiser\nvos points sur un schéma graphique';

  @override
  String get synopticDeleteTitle => 'Supprimer le synoptique ?';

  @override
  String synopticDeleteMessage(String name) {
    return 'Êtes-vous sûr de vouloir supprimer \"$name\" ?\nCette action est irréversible.';
  }

  @override
  String synopticBindingsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count liaisons',
      one: '1 liaison',
      zero: '0 liaison',
    );
    return '$_temp0';
  }

  @override
  String get synopticBindingsUnknown => '-- liaisons';

  @override
  String get synopticGlobal => 'Global';

  @override
  String get synopticEditBindings => 'Éditer les liaisons';

  @override
  String get synopticNew => 'Nouveau synoptique';

  @override
  String get synopticSvgModel => 'Modèle SVG';

  @override
  String synopticConfigurableElementsCount(int count) {
    return '$count éléments configurables';
  }

  @override
  String get synopticNameLabel => 'Nom du synoptique';

  @override
  String get synopticNameHint => 'Ex: Circuit Chauffage RDC';

  @override
  String get synopticDescriptionOptional => 'Description (optionnel)';

  @override
  String get synopticDefaultName => 'Synoptique';

  @override
  String get synopticResetZoom => 'Réinitialiser le zoom';

  @override
  String get synopticNotFound => 'Synoptique non trouvé';

  @override
  String synopticUpdateError(String error) {
    return 'Erreur de mise à jour: $error';
  }

  @override
  String synopticActivePointsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count points actifs',
      one: '1 point actif',
      zero: '0 point actif',
    );
    return '$_temp0';
  }

  @override
  String get synopticPinchToZoom => 'Pincez pour zoomer';

  @override
  String get synopticSvgElement => 'Élément SVG';

  @override
  String get synopticBindingType => 'Type de liaison';

  @override
  String get synopticCurrentValue => 'Valeur actuelle';

  @override
  String get synopticViewPoint => 'Voir le point';

  @override
  String get synopticNumericValue => 'Valeur numérique';

  @override
  String get synopticColorIndicator => 'Indicateur couleur';

  @override
  String get synopticAnimation => 'Animation';

  @override
  String synopticEditTitle(String name) {
    return 'Éditer: $name';
  }

  @override
  String get synopticHelp => 'Aide';

  @override
  String get synopticPreview => 'Aperçu du synoptique';

  @override
  String get synopticConfigurableElements => 'Éléments configurables';

  @override
  String get synopticNoConfigurableElements =>
      'Aucun élément configurable détecté';

  @override
  String get synopticHowToConfigure => 'Comment configurer';

  @override
  String get synopticHelpSteps =>
      '1. Sélectionnez un élément dans la liste\n2. Choisissez le point BACnet à associer\n3. Configurez le type de liaison:\n   • Valeur: affiche la valeur du point\n   • Couleur: change la couleur selon l\'état\n   • Animation: active/désactive une animation\n4. Personnalisez le format si nécessaire';

  @override
  String get synopticStateIndicator => 'Indicateur d\'état';

  @override
  String get synopticElement => 'Élément';

  @override
  String get synopticConfigureBinding => 'Configurer la liaison';

  @override
  String get synopticDeleteBinding => 'Supprimer la liaison';

  @override
  String get synopticColor => 'Couleur';

  @override
  String get synopticDisplayFormat => 'Format d\'affichage';

  @override
  String synopticFormatHint(String placeholder) {
    return 'Ex: $placeholder°C ou $placeholder%';
  }

  @override
  String synopticFormatHelper(String placeholder) {
    return 'Utilisez $placeholder pour la valeur du point';
  }

  @override
  String get synopticColors => 'Couleurs';

  @override
  String get synopticAnimationConfig => 'Configuration Animation';

  @override
  String get synopticAnimationOnOff => 'Animation ON/OFF';

  @override
  String get synopticAnimationExplanation =>
      'L\'animation sera visible quand la valeur du point est > seuil (actif), et masquée sinon.';

  @override
  String get synopticThreshold => 'Seuil ON/OFF';

  @override
  String get synopticThresholdHelper =>
      'Valeur > seuil = ON, sinon OFF (pour booléen: 0.5)';

  @override
  String get synopticBacnetPoint => 'Point BACnet';

  @override
  String get synopticNoPointFound => 'Aucun point trouvé';

  @override
  String get synopticDeleteBindingTitle => 'Supprimer la liaison ?';

  @override
  String get synopticIrreversible => 'Cette action est irréversible.';

  @override
  String get envysionConnectionNotFound => 'Connexion introuvable';

  @override
  String get envysionAuthFailed => 'Authentification échouée (401)';

  @override
  String get envysionPageNotFound => 'Page non trouvée (404)';

  @override
  String get dashboardNotFound => 'Dashboard introuvable';

  @override
  String get dashboardDeleteWidgetConfirm => 'Supprimer le widget ?';

  @override
  String get dashboardDeleteWidgetMessage =>
      'Ce widget sera supprimé du tableau de bord.';

  @override
  String get dashboardEditTitle => 'Modifier le titre';

  @override
  String get dashboardTitleLabel => 'Titre';

  @override
  String get dashboardTitleHint => 'Laisser vide pour le titre par défaut';

  @override
  String get dashboardSettingsTitle => 'Paramètres du dashboard';

  @override
  String get dashboardColumnsWithColon => 'Colonnes : ';

  @override
  String get dashboardRowsWithColon => 'Lignes : ';

  @override
  String get dashboardDeletePermanentMessage =>
      'Ce tableau de bord et tous ses widgets seront supprimés définitivement.';

  @override
  String get dashboardSearchHint => 'Rechercher...';

  @override
  String get dashboardNewShort => 'Nouveau';

  @override
  String get dashboardEmptyHint =>
      'Créez votre premier tableau de bord pour visualiser\nplusieurs graphiques sur une seule page.';

  @override
  String dashboardGridSize(int columns, int rows) {
    return 'Grille ${columns}x$rows';
  }

  @override
  String get dashboardNameHint => 'Ex : Chauffage, Ventilation...';

  @override
  String get dashboardGridLayout => 'Disposition de la grille';

  @override
  String get dashboardColumns => 'Colonnes';

  @override
  String get dashboardRows => 'Lignes';

  @override
  String get dashboardChartDefault => 'Graphique';

  @override
  String dashboardComparisonTitle(int count) {
    return 'Comparaison ($count courbes)';
  }

  @override
  String get dashboardNotConfigured => 'Non configuré';

  @override
  String get dashboardConfigure => 'Configurer';

  @override
  String get deviceInfoProtocol => 'Protocole';

  @override
  String get deviceInfoUser => 'Utilisateur';

  @override
  String get deviceInfoLastConnection => 'Dernière connexion';

  @override
  String get deviceInfoNetwork => 'Réseau';

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
  String get deviceInfoIpAddress => 'Adresse IP';

  @override
  String get deviceInfoSubnetMask => 'Masque';

  @override
  String get deviceInfoGateway => 'Passerelle';

  @override
  String get deviceInfoPrimaryDns => 'DNS primaire';

  @override
  String get deviceInfoMacAddress => 'Adresse MAC';

  @override
  String deviceInfoCopied(String label) {
    return '$label copié';
  }

  @override
  String get deviceInfoBacnetObjects => 'Objets BACnet';

  @override
  String deviceInfoTotalObjects(int count) {
    return 'Total : $count objets';
  }

  @override
  String get deviceInfoNoDataAvailable => 'Aucune donnée disponible';

  @override
  String get deviceInfoTechnical => 'Informations techniques';

  @override
  String get deviceInfoHostName => 'Nom d\'hôte';

  @override
  String get homeAuthenticating => 'Authentification...';

  @override
  String get homeFetchingData => 'Récupération des données...';

  @override
  String get homeSynoptic => 'Synoptique';

  @override
  String homeControllerTimeTooltip(String time) {
    return 'Heure automate : $time';
  }

  @override
  String homeTimeOffsetTooltip(String offset) {
    return 'Décalage : $offset';
  }

  @override
  String get homeControllerTimeTitle => 'Heure de l\'automate';

  @override
  String get homeControllerDateTime => 'Date/Heure automate';

  @override
  String get homeLocalTime => 'Heure locale';

  @override
  String get homeTimeOffset => 'Décalage';

  @override
  String get homeTimeOffsetWarning =>
      'L\'heure de l\'automate est décalée. Les plannings peuvent ne pas s\'exécuter aux moments attendus.';

  @override
  String get homeSyncV2Info =>
      'API V2 : utilisez l\'interface web EC-NetAX ou configurez le NTP pour synchroniser l\'heure.';

  @override
  String get homeSyncSuccess => 'Synchronisation réussie avec succès !';

  @override
  String get homeSyncFailed => 'Échec de la synchronisation.';

  @override
  String get homeSyncing => 'Synchronisation...';

  @override
  String get homeSync => 'Synchroniser';

  @override
  String routerPageNotFound(String path) {
    return 'Page non trouvée : $path';
  }

  @override
  String routerInvalidId(String id) {
    return 'Identifiant invalide : \"$id\"';
  }

  @override
  String connectionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count connexions',
      one: '1 connexion',
      zero: '0 connexion',
    );
    return '$_temp0';
  }

  @override
  String get connectionsEmptyFolder => 'Dossier vide';

  @override
  String get connectionsFolderName => 'Nom du dossier';

  @override
  String get connectionsEditFolder => 'Modifier le dossier';

  @override
  String get connectionsDeleteFolder => 'Supprimer le dossier';

  @override
  String connectionsDeleteFolderMessage(String name) {
    return 'Voulez-vous supprimer le dossier \"$name\" ?\n\nLes connexions qu\'il contient seront déplacées à la racine.';
  }

  @override
  String connectionsFolderDeleted(String name) {
    return 'Dossier \"$name\" supprimé';
  }

  @override
  String connectionsDeleteConfirm(String name) {
    return 'Voulez-vous supprimer \"$name\" ?';
  }

  @override
  String connectionsDeleted(String name) {
    return 'Connexion \"$name\" supprimée';
  }

  @override
  String get connectionsMoveTo => 'Déplacer vers';

  @override
  String get connectionsMoved => 'Connexion déplacée';

  @override
  String get connectionsAddToStart => 'Ajoutez une connexion pour commencer';

  @override
  String get connectionsMove => 'Déplacer';

  @override
  String get connectionsRefreshFolderTooltip =>
      'Rafraîchir tous les super favoris du dossier';

  @override
  String get connectionsRefreshValuesTooltip => 'Rafraîchir les valeurs';

  @override
  String addConnSelected(String name) {
    return '$name sélectionné';
  }

  @override
  String get addConnUseSecure => 'Utiliser une connexion sécurisée';

  @override
  String get addConnConnectionType => 'Type de connexion';

  @override
  String addConnBacnetSuccess(String deviceId) {
    return 'Connexion BACnet réussie ! Device ID : $deviceId';
  }

  @override
  String get addConnNotDiscovered => 'non découvert';

  @override
  String get addConnBacnetFailed => 'Échec de la connexion BACnet';

  @override
  String get addConnUpdated => 'Connexion modifiée';

  @override
  String get addConnSaved => 'Connexion enregistrée';

  @override
  String get discoverMdnsError => 'Erreur mDNS';

  @override
  String get discoverSearchingEclypse =>
      'Recherche des automates ECLYPSE sur le réseau...';

  @override
  String get discoverNoEclypseFoundMessage =>
      'Aucun ECLYPSE n\'a été trouvé sur le réseau.\nVérifiez que vous êtes connecté au même réseau que l\'automate.';

  @override
  String discoverDeviceIdConflictWithId(String deviceId) {
    return 'Conflit Device ID $deviceId';
  }

  @override
  String get alarmsSortNewest => 'Plus récentes';

  @override
  String get alarmsSortOldest => 'Plus anciennes';

  @override
  String get bacnetTypeAnalogInput => 'Entrée Analogique';

  @override
  String get bacnetTypeAnalogOutput => 'Sortie Analogique';

  @override
  String get bacnetTypeAnalogValue => 'Valeur Analogique';

  @override
  String get bacnetTypeBinaryInput => 'Entrée Binaire';

  @override
  String get bacnetTypeBinaryOutput => 'Sortie Binaire';

  @override
  String get bacnetTypeBinaryValue => 'Valeur Binaire';

  @override
  String get bacnetTypeMultiStateInput => 'Entrée Multi-états';

  @override
  String get bacnetTypeMultiStateOutput => 'Sortie Multi-états';

  @override
  String get bacnetTypeMultiStateValue => 'Valeur Multi-états';

  @override
  String get bacnetTypeSchedule => 'Horaire';

  @override
  String get bacnetTypeCalendar => 'Calendrier';

  @override
  String get bacnetTypeTrendLog => 'Historique';

  @override
  String get bacnetTypeNotificationClass => 'Classe de notification';

  @override
  String get bacnetTypeDevice => 'Appareil';

  @override
  String get scheduleDayShortMonday => 'Lun';

  @override
  String get scheduleDayShortTuesday => 'Mar';

  @override
  String get scheduleDayShortWednesday => 'Mer';

  @override
  String get scheduleDayShortThursday => 'Jeu';

  @override
  String get scheduleDayShortFriday => 'Ven';

  @override
  String get scheduleDayShortSaturday => 'Sam';

  @override
  String get scheduleDayShortSunday => 'Dim';

  @override
  String get scheduleNewSlot => 'Nouveau créneau';

  @override
  String get scheduleEditSlot => 'Modifier le créneau';

  @override
  String get scheduleNewTransition => 'Nouvelle transition';

  @override
  String get scheduleAllDay => 'Toute la journée';

  @override
  String get scheduleStartTime => 'Heure de début';

  @override
  String get scheduleEndTime => 'Heure de fin';

  @override
  String get scheduleTime => 'Heure';

  @override
  String get scheduleEndAfterStartError =>
      'L\'heure de fin doit être après l\'heure de début';

  @override
  String scheduleDuration(String duration) {
    return 'Durée: $duration';
  }

  @override
  String get scheduleSelectTime => 'Sélectionner l\'heure';

  @override
  String get scheduleMidnightEndOfDay => 'Minuit (fin de journée)';

  @override
  String get scheduleCopyDay => 'Copier ce jour';

  @override
  String schedulePasteHereFrom(String day) {
    return 'Coller ici (depuis $day)';
  }

  @override
  String schedulePasteFrom(String day) {
    return 'Coller depuis $day';
  }

  @override
  String get schedulePasteToWorkDays => 'Coller sur jours ouvrés';

  @override
  String get scheduleWorkDaysRange => 'Lun-Ven';

  @override
  String get schedulePasteToAllDays => 'Coller sur tous les jours';

  @override
  String get scheduleClearDay => 'Effacer ce jour';

  @override
  String scheduleDayCopied(String day) {
    return '$day copié';
  }

  @override
  String get schedulePastedToWorkDays => 'Collé sur les jours ouvrés';

  @override
  String get schedulePastedToAllDays => 'Collé sur tous les jours';

  @override
  String get scheduleMoreActions => 'Plus d\'actions';

  @override
  String get scheduleSaveConfirmTitle => 'Sauvegarder le planning ?';

  @override
  String get scheduleSaveConfirmMessage =>
      'Les modifications seront envoyées à l\'automate et prendront effet immédiatement.';

  @override
  String get scheduleDiscardConfirmTitle => 'Annuler les modifications ?';

  @override
  String get scheduleDiscardConfirmMessage =>
      'Toutes les modifications non sauvegardées seront perdues.';

  @override
  String get scheduleContinueEditing => 'Continuer l\'édition';

  @override
  String get scheduleDeleteTransitionTitle => 'Supprimer cette transition ?';

  @override
  String get scheduleDeleteSlotTitle => 'Supprimer ce créneau ?';

  @override
  String get scheduleNoTransition => 'Aucune transition';

  @override
  String get scheduleNoScheduledTransition => 'Aucune transition programmée';

  @override
  String get scheduleTapPlusToAdd => 'Appuyez sur + pour ajouter';

  @override
  String get scheduleAddSlot => 'Ajouter un créneau';

  @override
  String get scheduleFullDay => 'Journée';

  @override
  String scheduleEditDayTitle(String day) {
    return 'Modifier - $day';
  }

  @override
  String scheduleAddDayTitle(String day) {
    return 'Ajouter - $day';
  }
}
