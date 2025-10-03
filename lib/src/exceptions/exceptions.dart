class GitStorageException implements Exception {
  final String message;

  GitStorageException(this.message);

  @override
  String toString() => 'GitStorageException: $message';
}
