import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/cache_service.dart';
import 'database_provider.dart';

/// Provider pour le service de cache
final cacheServiceProvider = Provider<CacheService>((ref) {
  final database = ref.watch(databaseProvider);
  return CacheService(database);
});

/// Provider pour les statistiques du cache de la connexion active
final cacheStatsProvider = FutureProvider.family<CacheStats, int>((ref, connectionId) async {
  final cacheService = ref.watch(cacheServiceProvider);
  return cacheService.getCacheStats(connectionId);
});
