import 'dart:io';

import '../models/git_storage_file.dart';

/// An abstract class that defines the contract for a Git storage service.
abstract class GitStorage {
  /// Uploads a file to the Git repository.
  ///
  /// Returns a [Future] that completes with a [GitStorageFile] object
  /// representing the uploaded file.
  Future<GitStorageFile> uploadFile(File file, String path);

  /// Updates a file's contents at the given [path]. If the file does not
  /// exist, it will be created at that path.
  Future<GitStorageFile> updateFile(File file, String path, {String? message});

  /// Retrieves a file from the Git repository.
  ///
  /// Returns a [Future] that completes with a [GitStorageFile] object
  /// representing the retrieved file.
  Future<GitStorageFile> getFile(String path);

  /// Reads raw bytes for a file.
  Future<List<int>> getBytes(String path);

  /// Reads UTF-8 string contents for a file.
  Future<String> getString(String path);

  /// Reads bytes directly from a given URL (e.g., GitHub download_url).
  Future<List<int>> getBytesFromUrl(String url);

  /// Lists the files and directories in a given path in the Git repository.
  ///
  /// Returns a [Future] that completes with a list of [GitStorageFile] objects.
  Future<List<GitStorageFile>> listFiles(String path);

  /// Creates a new directory in the Git repository.
  ///
  /// Returns a [Future] that completes with a [GitStorageFile] object
  /// representing the created `.gitkeep` file.
  Future<GitStorageFile> createFolder(String path);

  /// Deletes a file from the Git repository.
  ///
  /// Returns a [Future] that completes when the file is deleted.
  Future<void> deleteFile(String path);

  /// Writes bytes to a file path, creating or updating as necessary.
  Future<GitStorageFile> putBytes(List<int> bytes, String path, {String? message});

  /// Writes a UTF-8 string to a file path, creating or updating as necessary.
  Future<GitStorageFile> putString(String content, String path, {String? message});
}
