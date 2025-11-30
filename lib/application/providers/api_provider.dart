import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_service.dart';

/// Provider pour le service API
final apiServiceProvider = Provider<ApiService>((ref) {
  final service = ApiService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
