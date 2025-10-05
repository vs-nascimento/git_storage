import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:git_storage/git_storage.dart';

// Um client falso em memória para evitar chamadas HTTP.
class FakeClient implements GitStorage {
  final Map<String, List<int>> store = {};
  @override
  Future<GitStorageFile> uploadFile(File file, String path) async {
    throw UnimplementedError();
  }

  @override
  Future<GitStorageFile> updateFile(File file, String path,
      {String? message}) async {
    throw UnimplementedError();
  }

  @override
  Future<GitStorageFile> getFile(String path) async {
    final bytes = store[path];
    if (bytes == null) {
      throw GitStorageException('Not found');
    }
    return GitStorageFile(
      name: path.split('/').last,
      path: path,
      sha: 'sha',
      size: bytes.length,
      url: '',
      htmlUrl: '',
      gitUrl: '',
      downloadUrl: '',
      type: 'file',
    );
  }

  @override
  Future<List<int>> getBytes(String path) async {
    final bytes = store[path];
    if (bytes == null) throw GitStorageException('Not found');
    return bytes;
  }

  @override
  Future<String> getString(String path) async {
    final bytes = await getBytes(path);
    return utf8.decode(bytes);
  }

  @override
  Future<List<int>> getBytesFromUrl(String url) async {
    // Neste fake, a URL não é usada; apenas retorna conteúdo se existir
    final path = url; // assume mapping direto para simplificar testes
    final bytes = store[path];
    if (bytes == null) throw GitStorageException('Not found');
    return bytes;
  }

  @override
  Future<List<GitStorageFile>> listFiles(String path) async {
    final prefix = path.endsWith('/') ? path : '$path/';
    final result = <GitStorageFile>[];
    for (final k in store.keys) {
      if (k.startsWith(prefix)) {
        result.add(GitStorageFile(
          name: k.substring(prefix.length),
          path: k,
          sha: 'sha',
          size: store[k]!.length,
          url: '',
          htmlUrl: '',
          gitUrl: '',
          downloadUrl: '',
          type: 'file',
        ));
      }
    }
    return result;
  }

  @override
  Future<GitStorageFile> createFolder(String path) async {
    // cria .gitkeep
    return putString('', '$path/.gitkeep');
  }

  @override
  Future<void> deleteFile(String path) async {
    store.remove(path);
  }

  @override
  Future<GitStorageFile> putBytes(List<int> bytes, String path,
      {String? message}) async {
    store[path] = bytes;
    return GitStorageFile(
      name: path.split('/').last,
      path: path,
      sha: 'sha',
      size: bytes.length,
      url: '',
      htmlUrl: '',
      gitUrl: '',
      downloadUrl: '',
      type: 'file',
    );
  }

  @override
  Future<GitStorageFile> putString(String content, String path,
      {String? message}) async {
    return putBytes(utf8.encode(content), path, message: message);
  }
}

void main() {
  group('GitStorageDB integration (fake client)', () {
    late FakeClient client;
    late GitStorageDB db;

    setUp(() {
      client = FakeClient();
      db = GitStorageDB(
        client: client,
        passphrase: 'secret',
        basePath: 'db',
        cryptoService:
            CryptoService(type: CryptoType.aesGcm128, pbkdf2Iterations: 5000),
        enableLogs: false,
      );
    });

    test('create, put, get, update, delete', () async {
      await db.createCollection('users');
      await db.put(collection: 'users', id: 'u1', json: {'name': 'Ana'});
      final doc = await db.get('users', 'u1');
      expect(doc['name'], 'Ana');

      await db.update(
          collection: 'users',
          id: 'u1',
          updater: (cur) {
            cur['name'] = 'Ana Maria';
            return cur;
          });
      final doc2 = await db.get('users', 'u1');
      expect(doc2['name'], 'Ana Maria');

      final ids = await db.listIds('users');
      expect(ids, contains('u1'));

      await db.delete(collection: 'users', id: 'u1');
      final ids2 = await db.listIds('users');
      expect(ids2.contains('u1'), isFalse);
    });

    test('transaction commit', () async {
      final tx = GitDBTransaction(db);
      tx.put(collection: 'users', id: 'a', json: {'n': 1});
      tx.put(collection: 'users', id: 'b', json: {'n': 2});
      await tx.commit();
      final all = await db.getAll('users');
      expect(all.length, 2);
    });

    test('migrations run', () async {
      final m1 = Migration(
          id: '001',
          up: (d) async {
            await d.createCollection('settings');
            await d
                .put(collection: 'settings', id: 'app', json: {'version': 1});
          });
      final m2 = Migration(
          id: '002',
          up: (d) async {
            await d.update(
                collection: 'settings',
                id: 'app',
                updater: (cur) {
                  cur['version'] = (cur['version'] as int) + 1;
                  return cur;
                });
          });

      await db.runMigrations([m2, m1]); // out of order to test sorting
      final app = await db.get('settings', 'app');
      expect(app['version'], 2);

      final applied = await db.getAppliedMigrations();
      expect(applied, containsAll(['001', '002']));
    });
  });
}