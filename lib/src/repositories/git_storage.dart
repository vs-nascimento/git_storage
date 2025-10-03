import 'dart:io';

import '../models/git_storage_file.dart';

/// An abstract class that defines the contract for a Git storage service.
abstract class GitStorage {
  /// Uploads a file to the Git repository.
  ///
  /// Returns a [Future] that completes with a [GitStorageFile] object
  /// representing the uploaded file.
  Future<GitStorageFile> uploadFile(File file, String path);

  /// Retrieves a file from the Git repository.
  ///
  /// Returns a [Future] that completes with a [GitStorageFile] object
  /// representing the retrieved file.
  Future<GitStorageFile> getFile(String path);

  /// Lists the files and directories in a given path in the Git repository.
  ///
  /// Returns a [Future] that completes with a list of [GitStorageFile] objects.
  Future<List<GitStorageFile>> listFiles(String path);

  /// Creates a new directory in the Git repository.
  ///
  /// Returns a [Future] that completes with a [GitStorageFile] object
  /// representing the created `.gitkeep` file.
  Future<GitStorageFile> createFolder(String path);
}
