import 'dart:io';

import '../models/git_storage_file.dart';

abstract class GitStorage {
  Future<GitStorageFile> uploadFile(File file, String fileName);
  Future<GitStorageFile> getFile(String filePath);
  Future<List<GitStorageFile>> listFiles(String path);
}
