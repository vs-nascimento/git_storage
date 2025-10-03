import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'exceptions/exceptions.dart';
import 'models/git_storage_file.dart';
import 'repositories/git_storage.dart';
import 'services/git_storage_service.dart';

/// A client for interacting with a Git repository as a storage system.
class GitStorageClient implements GitStorage {
  /// The service for interacting with the Git storage.
  late final GitStorageService service;

  /// The owner of the repository.
  late final String _owner;

  /// The name of the repository.
  late final String _repo;

  /// The GitHub personal access token.
  final String token;

  /// The branch to use.
  final String branch;

  /// The URL of the repository.
  final String repoUrl;

  /// Creates a new [GitStorageClient] instance.
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

  /// Builds the API URL for a given path.
  String _buildUrl(String path) {
    path = path.replaceAll(RegExp(r'^/|/$'), '');
    return "https://api.github.com/repos/$_owner/$_repo/contents/$path";
  }

  /// The headers for the HTTP requests.
  Map<String, String> get _headers => {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github+json',
      };

  @override
  Future<GitStorageFile> uploadFile(File file, String path) async {
    return _uploadFile(file, path);
  }

  /// Uploads a file to the repository, with a retry mechanism in case of
  /// a name conflict.
  Future<GitStorageFile> _uploadFile(File file, String path,
      {int retryCount = 0}) async {
    try {
      final content = base64Encode(await file.readAsBytes());

      String filePath = path;
      if (retryCount > 0) {
        final extension = filePath.split('.').last;
        final name =
            filePath.substring(0, filePath.length - extension.length - 1);
        filePath = '$name-$retryCount.$extension';
      }

      final url = _buildUrl(filePath);

      final response = await http.put(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          "message": "Added file: $filePath",
          "branch": branch,
          "content": content,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        return GitStorageFile.fromJson(jsonResp['content']);
      } else if (response.statusCode == 422) {
        // file already exists → try to rename
        return _uploadFile(file, path, retryCount: retryCount + 1);
      } else {
        throw GitStorageException(_mapError(response));
      }
    } catch (e) {
      throw GitStorageException('Error uploading file: $e');
    }
  }

  /// Get a specific file
  @override
  Future<GitStorageFile> getFile(String path) async {
    try {
      final url = "${_buildUrl(path)}?ref=$branch";

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        return GitStorageFile.fromJson(jsonResp);
      } else {
        throw GitStorageException(_mapError(response));
      }
    } catch (e) {
      throw GitStorageException('Error getting file: $e');
    }
  }

  /// List files and folders in a directory
  @override
  Future<List<GitStorageFile>> listFiles(String path) async {
    try {
      final url = "${_buildUrl(path)}?ref=$branch";

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body) as List;
        return jsonResp.map((item) => GitStorageFile.fromJson(item)).toList();
      } else {
        throw GitStorageException(_mapError(response));
      }
    } catch (e) {
      throw GitStorageException('Error listing files: $e');
    }
  }

  /// Create a "folder" (in practice, it creates a `.gitkeep` file)
  @override
  Future<GitStorageFile> createFolder(String folderPath) async {
    final placeholder = File('.gitkeep')..writeAsStringSync('');
    return uploadFile(placeholder, "$folderPath/.gitkeep");
  }

  @override
  Future<void> deleteFile(String path) async {
    try {
      final file = await getFile(path);
      final url = _buildUrl(path);
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          "message": "Deleted file: $path",
          "branch": branch,
          "sha": file.sha,
        }),
      );
      if (response.statusCode == 200) {
        return;
      } else {
        throw GitStorageException(_mapError(response));
      }
    } catch (e) {
      throw GitStorageException('Error deleting file: $e');
    }
  }

  /// Translates common GitHub errors
  String _mapError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        return "Invalid token or no permission.";
      case 403:
        return "Access denied: check token and permissions.";
      case 404:
        return "Repository or path not found.";
      case 409:
        return "Conflict: invalid or conflicting branch.";
      default:
        return "Error ${response.statusCode}: ${response.body}";
    }
  }
}
