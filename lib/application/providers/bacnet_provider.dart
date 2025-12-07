import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/bacnet_service.dart';

/// Provider singleton pour le service BACnet
final bacnetServiceProvider = Provider<BacnetService>((ref) {
  final service = BacnetService();

  // Initialiser le service au démarrage
  service.init();

  // Fermer le socket à la destruction du provider
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
