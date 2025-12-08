import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/bacnet_service.dart';

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
