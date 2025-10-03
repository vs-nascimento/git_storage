import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'exceptions/exceptions.dart';
import 'models/git_storage_file.dart';
import 'repositories/git_storage.dart';
import 'services/git_storage_service.dart';

class GitStorageClient implements GitStorage {
  late final GitStorageService service;
  late final String _owner;
  late final String _repo;

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

  String _buildUrl(String path) {
    path = path.replaceAll(RegExp(r'^/|/$'), ''); // remove barras extras
    return "https://api.github.com/repos/$_owner/$_repo/contents/$path";
  }

  Map<String, String> get _headers => {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github+json',
      };

  @override
  Future<GitStorageFile> uploadFile(File file, String path) async {
    return _uploadFile(file, path);
  }

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
          "message": "Adicionado arquivo: $filePath",
          "branch": branch,
          "content": content,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        return GitStorageFile.fromJson(jsonResp['content']);
      } else if (response.statusCode == 422) {
        // arquivo já existe → tenta renomear
        return _uploadFile(file, path, retryCount: retryCount + 1);
      } else {
        throw GitStorageException(_mapError(response));
      }
    } catch (e) {
      throw GitStorageException('Erro ao enviar arquivo: $e');
    }
  }

  /// Obter um arquivo específico
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
      throw GitStorageException('Erro ao obter arquivo: $e');
    }
  }

  /// Listar arquivos e pastas de um diretório
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
      throw GitStorageException('Erro ao listar arquivos: $e');
    }
  }

  /// Criar uma "pasta" (na prática cria `.gitkeep`)
  Future<GitStorageFile> createFolder(String folderPath) async {
    final placeholder = File('.gitkeep')..writeAsStringSync('');
    return uploadFile(placeholder, "$folderPath/.gitkeep");
  }

  /// Traduz erros comuns do GitHub
  String _mapError(http.Response response) {
    switch (response.statusCode) {
      case 401:
        return "Token inválido ou sem permissão.";
      case 403:
        return "Acesso negado: verifique o token e permissões.";
      case 404:
        return "Repositório ou caminho não encontrado.";
      case 409:
        return "Conflito: branch inválida ou em conflito.";
      default:
        return "Erro ${response.statusCode}: ${response.body}";
    }
  }
}
