/// A custom exception class for GitStorage-related errors.
class GitStorageException implements Exception {
  /// The error message.
  final String message;

  /// Creates a new [GitStorageException] with the given [message].
  GitStorageException(this.message);

  @override
  String toString() => 'GitStorageException: $message';
}
