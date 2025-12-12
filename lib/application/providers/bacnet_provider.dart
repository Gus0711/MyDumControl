import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/bacnet_service.dart';
import '../../domain/models/network_interface_choice.dart';

// Re-export pour usage externe
export '../../domain/models/network_interface_choice.dart';
export '../../data/services/bacnet_service.dart' show DeviceIdConflict, IAmInfo;

/// Provider singleton pour le service BACnet
/// Note: Ne pas appeler init() ici car c'est asynchrone et les méthodes
/// du service l'appellent déjà automatiquement quand nécessaire
/// keepAlive() garde le service en vie entre les navigations d'écrans
final bacnetServiceProvider = Provider<BacnetService>((ref) {
  final service = BacnetService();

  // Garder le service en vie même quand plus observé
  // Évite de recréer le socket à chaque navigation
  ref.keepAlive();

  // Fermer le socket à la destruction du provider (fin de l'app)
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// =============================================================================
// Multi-Homing : Sélection d'interface réseau
// =============================================================================

/// Provider qui liste les interfaces réseau IPv4 disponibles
final availableNetworkInterfacesProvider = FutureProvider<List<NetworkInterfaceChoice>>((ref) async {
  return NetworkInterfaceChoice.listAvailable();
});

/// Provider pour l'interface réseau sélectionnée pour BACnet
/// null = utiliser toutes les interfaces (comportement par défaut)
final selectedBacnetInterfaceProvider = StateProvider<NetworkInterfaceChoice?>((ref) {
  return null;
});

/// Provider pour l'état de connexion BACnet active
final activeBacnetConnectionProvider = StateProvider<ActiveBacnetConnection?>((ref) {
  return null;
});

/// Informations de connexion BACnet active
class ActiveBacnetConnection {
  final int connectionId;
  final String host;
  final int port;
  final int? deviceId;

  ActiveBacnetConnection({
    required this.connectionId,
    required this.host,
    required this.port,
    this.deviceId,
  });
}

// =============================================================================
// Info Port BACnet
// =============================================================================

/// Provider pour les informations de port BACnet
/// Permet de savoir si le port standard 47808 est utilisé
final bacnetPortInfoProvider = Provider<BacnetPortInfo>((ref) {
  final service = ref.watch(bacnetServiceProvider);
  return BacnetPortInfo(
    isUsingStandardPort: service.isUsingStandardPort,
    actualPort: service.actualPort,
    standardPort: BacnetService.standardBacnetPort,
  );
});

/// Informations sur le port BACnet utilisé
class BacnetPortInfo {
  /// True si le port standard 47808 est utilisé
  final bool isUsingStandardPort;

  /// Port réellement utilisé (peut être dynamique si 47808 occupé)
  final int? actualPort;

  /// Port standard BACnet (47808)
  final int standardPort;

  const BacnetPortInfo({
    required this.isUsingStandardPort,
    required this.actualPort,
    required this.standardPort,
  });

  /// Message d'avertissement si port non standard
  String? get warningMessage {
    if (isUsingStandardPort || actualPort == null) return null;
    return 'Port $actualPort utilisé (port standard $standardPort occupé). '
        'Certains appareils peuvent ne pas répondre. '
        'Fermez les autres applications BACnet (YABE, etc.).';
  }
}
