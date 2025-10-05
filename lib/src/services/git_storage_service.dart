import 'dart:io';

import '../git_storage_client.dart';
import '../models/git_storage_file.dart';

/// A service class that provides a high-level API for interacting with the
/// Git storage.
///
/// This class acts as a wrapper around the [GitStorageClient] and provides
/// a simpler interface for common operations.
class GitStorageService {
  /// The underlying [GitStorageClient] instance.
  final GitStorageClient client;

  /// Creates a new [GitStorageService] with the given [client].
  GitStorageService(this.client);

  /// Uploads a file to the Git repository.
  ///
  /// Returns a [Future] that completes with a [GitStorageFile] object
  /// representing the uploaded file.
  Future<GitStorageFile> uploadFile(File file, String path) async {
    return await client.uploadFile(file, path);
  }

  Future<GitStorageFile> updateFile(File file, String path, {String? message}) async {
    return await client.updateFile(file, path, message: message);
  }

  /// Retrieves a file from the Git repository.
  ///
  /// Returns a [Future] that completes with a [GitStorageFile] object
  /// representing the retrieved file.
  Future<GitStorageFile> getFile(String path) async {
    return await client.getFile(path);
  }

  Future<List<int>> getBytes(String path) async {
    return await client.getBytes(path);
  }

  Future<String> getString(String path) async {
    return await client.getString(path);
  }

  /// Lists the files and directories in a given path in the Git repository.
  ///
  /// Returns a [Future] that completes with a list of [GitStorageFile] objects.
  Future<List<GitStorageFile>> listFiles(String path) async {
    return await client.listFiles(path);
  }

  /// Creates a new directory in the Git repository.
  ///
  /// Returns a [Future] that completes with a [GitStorageFile] object
  /// representing the created `.gitkeep` file.
  Future<GitStorageFile> createFolder(String path) async {
    return await client.createFolder(path);
  }

  Future<GitStorageFile> putBytes(List<int> bytes, String path, {String? message}) async {
    return await client.putBytes(bytes, path, message: message);
  }

  Future<GitStorageFile> putString(String content, String path, {String? message}) async {
    return await client.putString(content, path, message: message);
  }
}
