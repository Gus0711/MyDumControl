import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';

/// Provider singleton pour la base de données
final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();

  // Ferme la base de données quand le provider est disposé
  ref.onDispose(() {
    database.close();
  });

  return database;
});
