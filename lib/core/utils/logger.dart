import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as log;

/// Logger global de l'application
final logger = AppLogger();

/// Wrapper autour du package logger.
/// [message] may be a String or a `String Function()` (evaluated lazily,
/// only when the level is enabled).
class AppLogger {
  late final log.Logger _logger;

  AppLogger() {
    _logger = log.Logger(
      printer: log.PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        dateTimeFormat: log.DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: kReleaseMode ? log.Level.warning : log.Level.debug,
    );
  }

  /// Log de niveau debug
  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log de niveau info
  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log de niveau warning
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log de niveau erreur
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log de niveau fatal
  void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log de niveau trace (verbose)
  void t(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }
}
