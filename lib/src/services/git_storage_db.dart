import 'dart:convert';

import 'package:git_storage/git_storage.dart';
import '../models/migration.dart';
import 'logging.dart';

/// GitStorageDB: Um "banco" de documentos JSON por cima do Git.
/// Cada coleção é uma pasta; cada documento é um arquivo `<id>.json.enc`.
class GitStorageDB {
  final GitStorage client;
  final CryptoService crypto;
  final String? passphrase;
  final String basePath;
  final bool enableLogs;
  final int readConcurrency;
  final LogListener? logListener;
  final LogLevel logLevel;

  void _emit(LogLevel level, String message) {
    if (logListener != null && level.index >= logLevel.index) {
      logListener!.call('GitStorageDB', level, message);
    } else if (enableLogs && level.index >= LogLevel.info.index) {
      print('[GitStorageDB] $message');
    }
  }

  void _log(String message) => _emit(LogLevel.info, message);
  void _logError(String message) => _emit(LogLevel.error, message);

  /// Construtor antigo (compatível), usa AES-GCM por padrão.
  GitStorageDB({
    required this.client,
    required String this.passphrase,
    this.basePath = 'db',
    CryptoService? cryptoService,
    this.enableLogs = false,
    this.readConcurrency = 6,
    this.logListener,
    this.logLevel = LogLevel.none,
  }) : crypto = cryptoService ?? CryptoService();

  /// Novo construtor com configuração única.
  factory GitStorageDB.fromConfig(GitStorageDBConfig config) {
    final client = config.client ??
        GitStorageClient(
          repoUrl: config.repoUrl!,
          token: config.token!,
          branch: config.branch,
          logListener: config.logListener,
          logLevel: config.logLevel,
        );
    final crypto = CryptoService(
      type: config.cryptoType,
      pbkdf2Iterations: config.pbkdf2Iterations,
      logListener: config.logListener,
      logLevel: config.logLevel,
    );
    return GitStorageDB(
      client: client,
      passphrase:
          config.cryptoType == CryptoType.none ? '' : config.passphrase!,
      basePath: config.basePath,
      cryptoService: crypto,
      enableLogs: config.enableLogs,
      readConcurrency: config.readConcurrency,
      logListener: config.logListener,
      logLevel: config.logLevel,
    );
  }

  /// Entrada encadeada tipo Firebase: `db.collection('users').where(...).get()`
  QueryBuilder collection(String name) => QueryBuilder.withDB(this, name);

  String _docPath(String collection, String id) {
    final ext = crypto.type == CryptoType.none ? '.json' : '.json.enc';
    return '$basePath/$collection/$id$ext';
  }

  Future<void> createCollection(String collection) async {
    _log('createCollection: $collection');
    await client.createFolder('$basePath/$collection');
    _log('createCollection: $collection criada em $basePath/$collection');
  }

  /// Remove todos os documentos e a pasta da coleção.
  Future<void> dropCollection(String collection) async {
    _log('dropCollection: $collection');
    final path = '$basePath/$collection';
    final files = await client.listFiles(path);
    // Exclui todos os arquivos na pasta (inclui .gitkeep)
    var deleted = 0;
    for (final f in files) {
      if (f.type == 'file') {
        await client.deleteFile(f.path);
        deleted++;
      }
    }
    _log('dropCollection: $collection removidos $deleted arquivos');
    // Pasta em GitHub não pode ser removida diretamente, mas sem arquivos ela deixa de existir logicamente.
  }

  /// Cria/atualiza documento JSON criptografado
  Future<void> put(String collection, String id, Map<String, dynamic> json,
      {String? message}) async {
    _log('put: $collection/$id message=${message ?? ''}');
    final clear = jsonEncode(json);
    final envelope = await crypto.encryptString(clear, passphrase ?? '');
    await client.putString(envelope, _docPath(collection, id),
        message: message ?? 'DB put $collection/$id');
    _log('put: $collection/$id concluído bytes=${envelope.length}');
  }

  /// Adiciona documento gerando ID conforme [IdStrategy].
  /// Retorna o ID gerado.
  Future<String> add(String collection, Map<String, dynamic> json,
      {IdStrategy strategy = IdStrategy.uuidV4,
      String? manualId,
      String? message}) async {
    final id = IdGenerator.generate(strategy, manualId: manualId);
    _log('add: $collection strategy=$strategy id=$id');
    await put(collection, id, json, message: message);
    _log('add: $collection/$id concluído');
    return id;
  }

  /// Obtém documento JSON descriptografado
  Future<Map<String, dynamic>> get(String collection, String id) async {
    try {
      _log('get: $collection/$id');
      final content = await client.getString(_docPath(collection, id));
      final data = await crypto.decryptToJson(content, passphrase ?? '');
      _log('get: $collection/$id ok keys=${data.length}');
      return data;
    } catch (e) {
      _logError('get FAILED: $collection/$id: $e');
      throw GitStorageException('Erro ao obter documento $collection/$id: $e');
    }
  }

  /// Remove documento
  Future<void> delete(String collection, String id, {String? message}) async {
    _log('delete: $collection/$id message=${message ?? ''}');
    await client.deleteFile(_docPath(collection, id));
    _log('delete: $collection/$id concluído');
  }

  /// Carrega lista de migrations aplicadas do meta `_meta/migrations`.
  Future<List<String>> getAppliedMigrations() async {
    try {
      final meta = await get('_meta', 'migrations');
      final applied = (meta['applied'] as List?)?.map((e) => e.toString()).toList() ?? [];
      _log('migrations: carregadas ${applied.length} já aplicadas');
      return applied;
    } catch (_) {
      _log('migrations: nenhuma migration aplicada encontrada');
      return [];
    }
  }

  /// Aplica migrations em ordem de `id`. Persiste progresso em `_meta/migrations`.
  Future<void> runMigrations(List<Migration> migrations, {bool stopOnError = true}) async {
    _log('migrations: start (${migrations.length})');
    // Garante coleção meta
    await createCollection('_meta');

    // Ordena por id
    migrations.sort((a, b) => a.id.compareTo(b.id));

    final applied = await getAppliedMigrations();
    var appliedCount = 0;
    for (final m in migrations) {
      if (applied.contains(m.id)) {
        _log('migrations: skip ${m.id} (já aplicada)');
        continue;
      }
      _log('migrations: applying ${m.id}');
      try {
        await m.up(this);
        applied.add(m.id);
        appliedCount++;
        await put('_meta', 'migrations', {
          'applied': applied,
          'lastAppliedAt': DateTime.now().toIso8601String(),
        }, message: 'Apply migration ${m.id}');
        _log('migrations: applied ${m.id}');
      } catch (e) {
        _logError('migrations: FAILED ${m.id}: $e');
        if (stopOnError) {
          throw GitStorageException('Falha ao aplicar migration ${m.id}: $e');
        }
      }
    }
    _log('migrations: done applied=$appliedCount');
  }

  /// Lista documentos da coleção (ids)
  Future<List<String>> listIds(String collection) async {
    _log('listIds: $collection');
    final files = await client.listFiles('$basePath/$collection');
    final suffix = crypto.type == CryptoType.none ? '.json' : '.json.enc';
    final ids = files
        .where((f) => f.type == 'file' && f.name.endsWith(suffix))
        .map((f) => f.name.replaceAll(suffix, ''))
        .toList();
    _log('listIds: $collection retornou ${ids.length} ids');
    return ids;
  }

  /// Atualiza documento aplicando um patch lógico
  Future<void> update(String collection, String id,
      Map<String, dynamic> Function(Map<String, dynamic> current) updater,
      {String? message}) async {
    _log('update: $collection/$id message=${message ?? ''}');
    final current = await get(collection, id);
    final next = updater(current);
    await put(collection, id, next,
        message: message ?? 'DB update $collection/$id');
    _log('update: $collection/$id aplicado');
  }

  // Legacy `query(...)` removed. Use `collection(name).where(...).get()`.

  /// Retorna todos os documentos da coleção como [GitStorageDoc].
  Future<List<GitStorageDoc>> getAll(String collection) async {
    _log('getAll: $collection (concorrência=$readConcurrency)');
    // Listar arquivos evita `getFile` por documento; teremos `path` e possivelmente `downloadUrl`.
    final files = await client.listFiles('$basePath/$collection');
    final suffix = crypto.type == CryptoType.none ? '.json' : '.json.enc';
    final targets = files.where((f) => f.type == 'file' && f.name.endsWith(suffix)).toList();

    final results = <GitStorageDoc>[];
    int index = 0;
    while (index < targets.length) {
      var end = index + readConcurrency;
      if (end > targets.length) end = targets.length;
      final batch = targets.sublist(index, end);
      // Executa downloads em paralelo limitado
      final futures = batch.map((f) async {
        try {
          // Se houver downloadUrl, usa direto; caso contrário cai para contents API via getString.
          String envelope;
          if (f.downloadUrl.isNotEmpty) {
            final bytes = await client.getBytesFromUrl(f.downloadUrl);
            envelope = utf8.decode(bytes);
          } else {
            envelope = await client.getString(f.path);
          }
          final data = await crypto.decryptToJson(envelope, passphrase ?? '');
          final id = f.name.replaceAll(suffix, '');
          return GitStorageDoc(id: id, data: data);
        } catch (_) {
          return null; // Ignora documentos inválidos
        }
      }).toList();

      final batchResults = await Future.wait(futures);
      results.addAll(batchResults.whereType<GitStorageDoc>());
      index += batch.length;
    }

    _log('getAll: $collection retornou ${results.length} documentos');
    return results;
  }
}
