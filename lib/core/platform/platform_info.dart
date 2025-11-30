import 'package:flutter/foundation.dart';
import 'package:universal_platform/universal_platform.dart';

/// Informations sur la plateforme d'exécution
class PlatformInfo {
  PlatformInfo._();

  /// True si l'application s'exécute sur le web
  static bool get isWeb => kIsWeb;

  /// True si l'application s'exécute sur une plateforme native (non-web)
  static bool get isNative => !kIsWeb;

  /// True si l'application s'exécute sur Android
  static bool get isAndroid => !kIsWeb && UniversalPlatform.isAndroid;

  /// True si l'application s'exécute sur iOS
  static bool get isIOS => !kIsWeb && UniversalPlatform.isIOS;

  /// True si l'application s'exécute sur un appareil mobile (Android ou iOS)
  static bool get isMobile => isAndroid || isIOS;

  /// True si l'application s'exécute sur Windows
  static bool get isWindows => !kIsWeb && UniversalPlatform.isWindows;

  /// True si l'application s'exécute sur Linux
  static bool get isLinux => !kIsWeb && UniversalPlatform.isLinux;

  /// True si l'application s'exécute sur macOS
  static bool get isMacOS => !kIsWeb && UniversalPlatform.isMacOS;

  /// True si l'application s'exécute sur un desktop (Windows, Linux ou macOS)
  static bool get isDesktop => isWindows || isLinux || isMacOS;

  /// True si la plateforme supporte la gestion des certificats auto-signés
  /// (toutes les plateformes natives)
  static bool get supportsSelfSignedCertificates => isNative;

  /// True si la plateforme nécessite un proxy pour contourner CORS
  static bool get requiresProxy => isWeb;

  /// Nom de la plateforme actuelle
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWindows) return 'Windows';
    if (isLinux) return 'Linux';
    if (isMacOS) return 'macOS';
    return 'Unknown';
  }
}
