import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

abstract class ILoggingService {
  void trace(dynamic message, [dynamic error, StackTrace? stackTrace]);
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]);
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]);
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]);
  void error(dynamic message, {dynamic error, StackTrace? stackTrace});
  void fatal(dynamic message, {dynamic error, StackTrace? stackTrace});
}

class LoggingService implements ILoggingService {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // Number of method calls to display
      errorMethodCount: 8, // Number of stacktrace lines for errors
      lineLength: 120,
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
    // Only log strictly in debug mode, or use custom filters
    filter: kDebugMode ? DebugFilter() : ProductionFilter(),
    output: ConsoleOutput(),
  );

  @override
  void trace(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  @override
  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
    // Add breadcrumb to Sentry so we know what happened before a crash
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message.toString(),
        level: SentryLevel.debug,
        category: 'logger',
      ),
    );
  }

  @override
  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message.toString(),
        level: SentryLevel.info,
        category: 'logger',
      ),
    );
  }

  @override
  void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message.toString(),
        level: SentryLevel.warning,
        category: 'logger',
      ),
    );
  }

  @override
  void error(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    // Send actual exception to Sentry
    Sentry.captureException(
      error ?? message,
      stackTrace: stackTrace,
      hint: Hint.withMap({'message': message.toString()}),
    );
  }

  @override
  void fatal(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
    Sentry.captureException(
      error ?? message,
      stackTrace: stackTrace,
      hint: Hint.withMap({'message': "FATAL: $message"}),
    );
  }
}

/// Production: Only log Warnings and Errors
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return event.level.index >= Level.warning.index;
  }
}

/// Debug: Log everything except Trace (unless you really need it)
class DebugFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return event.level != Level.trace;
  }
}
