/// A type-safe result wrapper for operations that can succeed or fail.
///
/// Use [Success] for successful operations and [Failure] for errors.
/// This replaces try-catch blocks with a more functional approach.
sealed class Result<T> {
  const Result();

  /// Returns true if this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a [Failure].
  bool get isFailure => this is Failure<T>;

  /// Returns the data if [Success], or null if [Failure].
  T? get data => switch (this) {
    Success(data: final d) => d,
    Failure() => null,
  };

  /// Returns the error message if [Failure], or null if [Success].
  String? get error => switch (this) {
    Success() => null,
    Failure(message: final m) => m,
  };

  /// Transforms the data if [Success], or returns the [Failure] unchanged.
  Result<R> map<R>(R Function(T) transform) => switch (this) {
    Success(data: final d) => Success(transform(d)),
    Failure(message: final m, stackTrace: final s, exception: final e) =>
      Failure(m, s, e),
  };

  /// Transforms the data if [Success], or returns the [Failure] unchanged.
  /// The transform function can return a new [Result].
  Result<R> flatMap<R>(Result<R> Function(T) transform) => switch (this) {
    Success(data: final d) => transform(d),
    Failure(message: final m, stackTrace: final s, exception: final e) =>
      Failure(m, s, e),
  };

  /// Executes [onSuccess] if [Success] or [onFailure] if [Failure].
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(String message, StackTrace? stackTrace) onFailure,
  }) => switch (this) {
    Success(data: final d) => onSuccess(d),
    Failure(message: final m, stackTrace: final s) => onFailure(m, s),
  };
}

/// Represents a successful operation with [data].
final class Success<T> extends Result<T> {
  @override
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed operation with an error [message].
final class Failure<T> extends Result<T> {
  final String message;
  final StackTrace? stackTrace;
  final Object? exception;

  const Failure(this.message, [this.stackTrace, this.exception]);

  @override
  String toString() => 'Failure($message)';
}
