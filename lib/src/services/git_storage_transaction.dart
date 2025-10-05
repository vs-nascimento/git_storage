import 'dart:developer' as dev;
import '../models/id_strategy.dart';
import 'git_storage_db.dart';
import 'logging.dart';

/// Represents a client-side transaction of operations on GitStorageDB.
class GitDBTransaction {
  final GitStorageDB db;

  final List<Future<void> Function()> _ops = [];

  GitDBTransaction(this.db);

  void _log(String message) {
    if (db.logListener != null && db.logLevel.index <= LogLevel.info.index) {
      db.logListener!.call('GitDBTransaction', LogLevel.info, message);
    } else if (db.enableLogs) {
      dev.log(message, name: 'GitDBTransaction', level: 800);
    }
  }

  /// Queues a create/update document operation.
  void put({
    required String collection,
    required String id,
    required Map<String, dynamic> json,
    Map<String, Type>? schema,
    String? message,
  }) {
    _log('queue put: $collection/$id');
    _ops.add(() => db.put(
        collection: collection,
        id: id,
        json: json,
        schema: schema,
        message: message));
  }

  /// Queues an add operation with ID generation strategy. Returns the resolved ID immediately.
  /// Note: the ID is generated now, but the write occurs on commit.
  String add({
    required String collection,
    required Map<String, dynamic> json,
    IdStrategy strategy = IdStrategy.uuidV4,
    String? manualId,
    Map<String, Type>? schema,
    String? message,
  }) {
    final id = IdGenerator.generate(strategy, manualId: manualId);
    _log('queue add: $collection id=$id strategy=$strategy');
    _ops.add(() => db.put(
        collection: collection,
        id: id,
        json: json,
        schema: schema,
        message: message));
    return id;
  }

  /// Queues a document deletion.
  void delete(String collection, String id, {String? message}) {
    _log('queue delete: $collection/$id');
    _ops.add(() => db.delete(collection: collection, id: id, message: message));
  }

  /// Queues an update with updater function.
  void update({
    required String collection,
    required String id,
    required Map<String, dynamic> Function(Map<String, dynamic> current)
        updater,
    Map<String, Type>? schema,
    String? message,
  }) {
    _log('queue update: $collection/$id');
    _ops.add(() => db.update(
        collection: collection,
        id: id,
        updater: updater,
        schema: schema,
        message: message));
  }

  /// Executes all queued operations sequentially.
  Future<void> commit() async {
    _log('commit start: ${_ops.length} ops');
    for (final op in _ops) {
      await op();
    }
    _ops.clear();
    _log('commit done');
  }
}
