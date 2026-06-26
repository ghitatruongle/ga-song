/// Base exception class for all app-specific exceptions.
///
/// All custom exceptions should extend [AppException] to provide
/// consistent error handling and reporting.
sealed class AppException implements Exception {
  /// A human-readable error message.
  final String message;

  /// The stack trace at the time of the exception.
  final StackTrace? stackTrace;

  const AppException(this.message, [this.stackTrace]);

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception thrown when database operations fail.
///
/// This includes SQLite errors, migration failures, and data corruption.
class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.stackTrace]);
}

/// Exception thrown when audio engine operations fail.
///
/// This includes SoLoud initialization errors, playback failures,
/// and audio effect errors.
class AudioEngineException extends AppException {
  const AudioEngineException(super.message, [super.stackTrace]);
}

/// Exception thrown when network operations fail.
///
/// This includes HTTP errors, timeout errors, and connection failures.
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException(super.message, [super.stackTrace, this.statusCode]);
}

/// Exception thrown when file operations fail.
///
/// This includes file not found, permission denied, and I/O errors.
class FileException extends AppException {
  final String? path;

  const FileException(super.message, [super.stackTrace, this.path]);
}

/// Exception thrown when cache operations fail.
///
/// This includes cache corruption, eviction errors, and storage errors.
class CacheException extends AppException {
  const CacheException(super.message, [super.stackTrace]);
}

/// Exception thrown when settings operations fail.
///
/// This includes SharedPreferences errors and invalid setting values.
class SettingsException extends AppException {
  const SettingsException(super.message, [super.stackTrace]);
}

/// Exception thrown when parsing operations fail.
///
/// This includes JSON parsing, lyric parsing, and metadata parsing errors.
class ParseException extends AppException {
  final String? input;

  const ParseException(super.message, [super.stackTrace, this.input]);
}

/// Exception thrown when platform-specific operations fail.
///
/// This includes platform channel errors and native code failures.
class PlatformException extends AppException {
  final String? platform;

  const PlatformException(super.message, [super.stackTrace, this.platform]);
}
