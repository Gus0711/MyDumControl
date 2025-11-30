import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Log de démarrage
  logger.i('MyDumControl - Démarrage de l\'application');

  // Exécuter l'application avec Riverpod
  runApp(
    const ProviderScope(
      child: MyDumControlApp(),
    ),
  );
}
