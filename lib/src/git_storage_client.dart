import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'exceptions/exceptions.dart';
import 'models/git_storage_file.dart';
import 'repositories/git_storage.dart';
import 'services/git_storage_service.dart';

class GitStorageClient implements GitStorage {
  late GitStorageService service;

  late String _owner;
  late String _repo;

  final String token;
  final String branch;
  final String repoUrl;

  GitStorageClient({
    required this.repoUrl,
    required this.token,
    this.branch = 'main',
  }) {
    final parts = repoUrl.replaceAll('.git', '').split('/');
    _owner = parts[parts.length - 2];
    _repo = parts.last;

    service = GitStorageService(this);
  }

  @override
  Future<GitStorageFile> uploadFile(File file, String fileName) async {
    return _uploadFile(file, fileName);
  }

  Future<GitStorageFile> _uploadFile(
    File file, 
    String fileName, 
    {int retryCount = 0}
  ) async {
    try {
      final content = base64Encode(await file.readAsBytes());

      String newFileName = fileName;
      if (retryCount > 0) {
        final extension = fileName.split('.').last;
        final name = fileName.substring(0, fileName.length - extension.length - 1);
        newFileName = '$name-$retryCount.$extension';
      }

      final url =
          "https://api.github.com/repos/$_owner/$_repo/contents/$newFileName";

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'token $token',
          'Accept': 'application/vnd.github+json',
        },
        body: jsonEncode({
          "message": "Adicionado arquivo: $newFileName",
          "branch": branch,
          "content": content,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        return GitStorageFile.fromJson(jsonResp['content']);
      } else if (response.statusCode == 422) {
        return _uploadFile(file, fileName, retryCount: retryCount + 1);
      } else {
        throw GitStorageException(
          'Erro ao enviar: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw GitStorageException('Erro ao enviar arquivo: $e');
    }
  }
}