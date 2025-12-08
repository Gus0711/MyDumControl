import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'application/providers/settings_provider.dart';

/// Widget racine de l'application
class MyDumControlApp extends ConsumerWidget {
  const MyDumControlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observer les paramètres pour le thème et la langue
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'MyDumControl',
      debugShowCheckedModeBanner: false,

      // Thèmes - utilise le paramètre sauvegardé
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,

      // Internationalisation - utilise le paramètre sauvegardé
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'), // Français (par défaut)
        Locale('en'), // Anglais
      ],
      locale: Locale(settings.locale),

      // Router
      routerConfig: AppRouter.router,
    );
  }
}
