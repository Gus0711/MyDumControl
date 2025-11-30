import 'package:logger/logger.dart' as log;

/// Logger global de l'application
final logger = AppLogger();

/// Wrapper autour du package logger
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
      level: log.Level.debug,
    );
  }

  /// Log de niveau debug
  void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log de niveau info
  void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log de niveau warning
  void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log de niveau erreur
  void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log de niveau fatal
  void f(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log de niveau trace (verbose)
  void t(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }
}
