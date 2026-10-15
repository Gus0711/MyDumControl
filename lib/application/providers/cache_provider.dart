import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/cache_service.dart';
import 'database_provider.dart';

/// Provider pour le service de cache
final cacheServiceProvider = Provider<CacheService>((ref) {
  final database = ref.watch(databaseProvider);
  return CacheService(database);
});
