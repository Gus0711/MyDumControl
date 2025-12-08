// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MyDumControl';

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
}
