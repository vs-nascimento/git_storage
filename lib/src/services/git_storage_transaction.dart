import '../git_storage_client.dart';
import 'crypto_service.dart';
import 'git_storage_db.dart';
import '../models/id_strategy.dart';

/// Representa uma transação de operações no GitStorageDB.
class GitStorageTransaction {
  final GitStorageDB db;

  final List<Future<void> Function()> _ops = [];

  GitStorageTransaction(this.db);

  void _log(String message) {
    if (db.enableLogs) {
      print('[GitStorageTransaction] $message');
    }
  }

  /// Enfileira criação/atualização de documento.
  void put(String collection, String id, Map<String, dynamic> json, {String? message}) {
    _log('queue put: $collection/$id');
    _ops.add(() => db.put(collection, id, json, message: message));
  }

  /// Enfileira adição com geração de ID por estratégia. Retorna o ID resolvido imediatamente.
  /// Observação: o ID é gerado agora, mas a gravação ocorre no commit.
  String add(String collection, Map<String, dynamic> json,
      {IdStrategy strategy = IdStrategy.uuidV4, String? manualId, String? message}) {
    final id = IdGenerator.generate(strategy, manualId: manualId);
    _log('queue add: $collection id=$id strategy=$strategy');
    _ops.add(() => db.put(collection, id, json, message: message));
    return id;
  }

  /// Enfileira exclusão de documento.
  void delete(String collection, String id, {String? message}) {
    _log('queue delete: $collection/$id');
    _ops.add(() => db.delete(collection, id, message: message));
  }

  /// Enfileira atualização com função updater.
  void update(String collection, String id,
      Map<String, dynamic> Function(Map<String, dynamic> current) updater,
      {String? message}) {
    _log('queue update: $collection/$id');
    _ops.add(() => db.update(collection, id, updater, message: message));
  }

  /// Executa todas as operações sequencialmente.
  Future<void> commit() async {
    _log('commit start: ${_ops.length} ops');
    for (final op in _ops) {
      await op();
    }
    _ops.clear();
    _log('commit done');
  }
}