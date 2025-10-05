import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'exceptions/exceptions.dart';
import 'models/git_storage_file.dart';
import 'repositories/git_storage.dart';
import 'services/git_storage_service.dart';
import 'services/logging.dart';
import 'utils/json_isolates.dart';

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
    this.logListener,
    this.logLevel = LogLevel.none,
  }) {
    final parts = repoUrl.replaceAll('.git', '').split('/');
    _owner = parts[parts.length - 2];
    _repo = parts.last;

    service = GitStorageService(this);
  }

  final LogListener? logListener;
  final LogLevel logLevel;

  void _emit(LogLevel level, String message) {
    if (logListener != null && level.index >= logLevel.index) {
      logListener!.call('GitStorageClient', level, message);
    }
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
    _emit(LogLevel.debug, 'uploadFile path=$path');
    return _uploadFile(file, path);
  }

  @override
  Future<GitStorageFile> updateFile(File file, String path, {String? message}) async {
    final bytes = await file.readAsBytes();
    _emit(LogLevel.debug, 'updateFile path=$path len=${bytes.length}');
    return putBytes(bytes, path, message: message);
  }

  /// Uploads a file to the repository, with a retry mechanism in case of
  /// a name conflict.
  Future<GitStorageFile> _uploadFile(File file, String path,
      {int retryCount = 0}) async {
    try {
      final content = base64Encode(await file.readAsBytes());
      _emit(LogLevel.debug, 'upload _uploadFile path=$path retry=$retryCount len=${content.length}');

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
        final jsonResp = await JsonIsolates.decode(response.body);
        _emit(LogLevel.info, 'upload ok path=$filePath');
        return GitStorageFile.fromJson(jsonResp['content']);
      } else if (response.statusCode == 422) {
        // file already exists → try to rename
        _emit(LogLevel.info, 'upload conflict -> retry rename');
        return _uploadFile(file, path, retryCount: retryCount + 1);
      } else {
        final err = _mapError(response);
        _emit(LogLevel.error, 'upload failed: $err');
        throw GitStorageException(err);
      }
    } catch (e) {
      _emit(LogLevel.error, 'upload exception: $e');
      throw GitStorageException('Error uploading file: $e');
    }
  }

  /// Get a specific file
  @override
  Future<GitStorageFile> getFile(String path) async {
    try {
      final url = "${_buildUrl(path)}?ref=$branch";
      _emit(LogLevel.debug, 'getFile path=$path');

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final jsonResp = await JsonIsolates.decode(response.body) as Map<String, dynamic>;
        _emit(LogLevel.info, 'getFile ok path=$path');
        return GitStorageFile.fromJson(jsonResp);
      } else {
        final err = _mapError(response);
        _emit(LogLevel.error, 'getFile failed: $err');
        throw GitStorageException(err);
      }
    } catch (e) {
      _emit(LogLevel.error, 'getFile exception: $e');
      throw GitStorageException('Error getting file: $e');
    }
  }

  @override
  Future<List<int>> getBytes(String path) async {
    // Otimização: usar diretamente a API de contents para obter conteúdo base64
    // Evita uma chamada prévia a getFile() apenas para buscar download_url.
    final url = "${_buildUrl(path)}?ref=$branch";
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      final jsonResp = await JsonIsolates.decode(response.body) as Map<String, dynamic>;
      final contentBase64 = (jsonResp['content'] as String?)?.replaceAll('\n', '') ?? '';
      if (contentBase64.isEmpty) {
        _emit(LogLevel.error, 'getBytes empty content path=$path');
        throw GitStorageException('Conteúdo vazio para $path');
      }
      _emit(LogLevel.debug, 'getBytes base64 len=${contentBase64.length}');
      return base64Decode(contentBase64);
    }
    final err = _mapError(response);
    _emit(LogLevel.error, 'getBytes failed: $err');
    throw GitStorageException(err);
  }

  @override
  Future<String> getString(String path) async {
    final bytes = await getBytes(path);
    _emit(LogLevel.debug, 'getString len=${bytes.length} path=$path');
    return JsonIsolates.utf8Decode(bytes);
  }

  /// Baixa bytes diretamente de uma URL (ex.: download_url do GitHub).
  /// Útil quando já possuímos a URL e queremos evitar a chamada de metadata.
  @override
  Future<List<int>> getBytesFromUrl(String url) async {
    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      _emit(LogLevel.debug, 'getBytesFromUrl ok url=$url len=${response.bodyBytes.length}');
      return response.bodyBytes;
    }
    final err = _mapError(response);
    _emit(LogLevel.error, 'getBytesFromUrl failed: $err');
    throw GitStorageException(err);
  }

  /// List files and folders in a directory
  @override
  Future<List<GitStorageFile>> listFiles(String path) async {
    try {
      final url = "${_buildUrl(path)}?ref=$branch";
      _emit(LogLevel.debug, 'listFiles path=$path');

      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final jsonResp = await JsonIsolates.decode(response.body) as List;
        _emit(LogLevel.info, 'listFiles ok count=${jsonResp.length}');
        return jsonResp.map((item) => GitStorageFile.fromJson(item)).toList();
      } else {
        final err = _mapError(response);
        _emit(LogLevel.error, 'listFiles failed: $err');
        throw GitStorageException(err);
      }
    } catch (e) {
      _emit(LogLevel.error, 'listFiles exception: $e');
      throw GitStorageException('Error listing files: $e');
    }
  }

  /// Create a "folder" (in practice, it creates a `.gitkeep` file)
  @override
  Future<GitStorageFile> createFolder(String folderPath) async {
    // Idempotent: ensures the placeholder exists without creating duplicates
    _emit(LogLevel.debug, 'createFolder $folderPath');
    return putString('', "$folderPath/.gitkeep", message: "Ensure folder: $folderPath");
  }

  @override
  Future<void> deleteFile(String path) async {
    try {
      final file = await getFile(path);
      final url = _buildUrl(path);
      _emit(LogLevel.debug, 'deleteFile path=$path sha=${file.sha}');
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
        _emit(LogLevel.info, 'deleteFile ok path=$path');
        return;
      } else {
        final err = _mapError(response);
        _emit(LogLevel.error, 'deleteFile failed: $err');
        throw GitStorageException(err);
      }
    } catch (e) {
      _emit(LogLevel.error, 'deleteFile exception: $e');
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

  Future<GitStorageFile> _putContent(String path, List<int> bytes, {String? message}) async {
    final content = base64Encode(bytes);
    final url = _buildUrl(path);
    _emit(LogLevel.debug, 'putContent path=$path len=${bytes.length}');

    String? sha;
    try {
      final existing = await getFile(path);
      sha = existing.sha;
    } catch (_) {}

    final response = await http.put(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode({
        "message": message ?? (sha == null ? "Added file: $path" : "Updated file: $path"),
        "branch": branch,
        "content": content,
        if (sha != null) "sha": sha,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final jsonResp = await JsonIsolates.decode(response.body) as Map<String, dynamic>;
      _emit(LogLevel.info, 'putContent ok path=$path');
      return GitStorageFile.fromJson(jsonResp['content']);
    }
    final err = _mapError(response);
    _emit(LogLevel.error, 'putContent failed: $err');
    throw GitStorageException(err);
  }

  @override
  Future<GitStorageFile> putBytes(List<int> bytes, String path, {String? message}) {
    _emit(LogLevel.debug, 'putBytes path=$path len=${bytes.length}');
    return _putContent(path, bytes, message: message);
  }

  @override
  Future<GitStorageFile> putString(String content, String path, {String? message}) {
    _emit(LogLevel.debug, 'putString path=$path len=${content.length}');
    return _putContent(path, utf8.encode(content), message: message);
  }
}
