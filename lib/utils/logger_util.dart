import 'package:logging/logging.dart';

/// A utility class to set up and manage logging throughout the app
class LoggerUtil {
  /// Initialize the logging system
  static void setupLogging() {
    // Set the logging level - consider using different levels for debug/release
    Logger.root.level = Level.ALL;

    // Configure how log messages are handled
    Logger.root.onRecord.listen((record) {
      // Format with colors to make logs more visible in VS Code console
      final emoji = _getEmojiForLevel(record.level);
      final levelPadded = record.level.name.padRight(7);

      // ignore: avoid_print
      print('$emoji $levelPadded [${record.loggerName}] ${record.message}');

      // If there's an error object, print it too
      if (record.error != null) {
        // ignore: avoid_print
        print('  ⚠️ ERROR: ${record.error}');
      }

      // If there's a stack trace, print it too
      if (record.stackTrace != null) {
        // ignore: avoid_print
        print('  📋 STACK: ${record.stackTrace}');
      }
    });
  }

  /// Get a logger for a specific class or component
  static Logger getLogger(String name) {
    return Logger(name);
  }

  /// Get an appropriate emoji for the log level to make logs more visible
  static String _getEmojiForLevel(Level level) {
    if (level == Level.FINEST) return '🔍'; // Detailed debugging
    if (level == Level.FINER) return '🔎'; // Detailed debugging
    if (level == Level.FINE) return '🔬'; // Debugging
    if (level == Level.CONFIG) return '⚙️'; // Configuration
    if (level == Level.INFO) return '📘'; // Information
    if (level == Level.WARNING) return '⚠️'; // Warning
    if (level == Level.SEVERE) return '🔴'; // Error
    if (level == Level.SHOUT) return '🚨'; // Critical error
    return '��'; // Default
  }
}
