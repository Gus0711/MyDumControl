import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client_factory.dart';
import '../../data/services/api_service.dart';
import 'connection_providers.dart';
import 'database_provider.dart';
import 'settings_provider.dart';

/// Connection timeout configured by the user (Settings screen).
final connectionTimeoutProvider = Provider<Duration>((ref) {
  final seconds = ref.watch(settingsProvider.select((s) => s.connectionTimeoutSeconds));
  return Duration(seconds: seconds > 0 ? seconds : 10);
});

/// Provider pour le service API (test de connexion)
final apiServiceProvider = Provider<ApiService>((ref) {
  final service = ApiService(timeout: ref.watch(connectionTimeoutProvider));

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Single place where [ConnectedApiClient]s are built (password, auth,
/// default API version, timeouts, TOFU certificate pinning).
final apiClientFactoryProvider = Provider<ApiClientFactory>((ref) {
  return ApiClientFactory(
    secureStorage: ref.watch(secureStorageProvider),
    database: ref.watch(databaseProvider),
    connectTimeout: ref.watch(connectionTimeoutProvider),
  );
});
