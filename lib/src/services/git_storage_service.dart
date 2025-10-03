import 'dart:io';

import '../git_storage_client.dart';
import '../models/git_storage_file.dart';

class GitStorageService {
  final GitStorageClient client;

  GitStorageService(this.client);

  Future<GitStorageFile> uploadFile(File file, String fileName) async {
    return await client.uploadFile(file, fileName);
  }
}
