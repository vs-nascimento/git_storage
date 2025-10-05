# Git Storage

[![Pub Version](https://img.shields.io/pub/v/git_storage?style=flat-square)](https://pub.dev/packages/git_storage)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)

A Flutter/Dart package to use GitHub repositories as a simple file storage, and to persist JSON documents (encrypted or not) via Git.

## Overview

This package provides a convenient way to interact with GitHub repositories for file management. You can upload, update, read and list files, and create logical folders. It also includes a mini JSON-based “DB” grouped by collection.

## Features

- **File upload:** Upload files to your repository.
- **Download URL:** Get direct download URLs for files.
- **Conflict handling:** `uploadFile` auto-renames on name conflicts.
- **Listing:** List files/folders in a path.
- **Create folders:** Create logical folders via `.gitkeep` (idempotent).
- **Read/Write content:** Read/write bytes and strings with automatic create/update.
- **GitStorageDB:** Store JSON (encrypted or plain) by collection.
- **Collections, Query and Transactions:** Create/drop collections, query with filters, and batch operations.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  git_storage: ^0.4.0 # Check for the latest version
```

Then run `flutter pub get`.

## How to Use

### 1. Import the Package

```dart
import 'package:git_storage/git_storage.dart';
import 'dart:io';
```

### 2. Initialize the Client

To use `GitStorageClient`, you need a GitHub [Personal Access Token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with `repo` permissions.

```dart
final client = GitStorageClient(
  repoUrl: 'https://github.com/your-user/your-repository.git',
  token: 'YOUR_GITHUB_PAT',
  branch: 'main', // Optional, defaults to 'main'
);
```

### 3. Client API

#### Upload a File

`uploadFile` accepts a `File` and the target repository path. If a file with the same name already exists, it automatically retries with a renamed path.

```dart
Future<void> upload(File myFile) async {
  try {
    final path = 'uploads/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final gitFile = await client.uploadFile(myFile, path);

    print('File uploaded successfully!');
    print('Download URL: ${gitFile.downloadUrl}');
  } catch (e) {
    print('An error occurred: $e');
  }
}
```

#### List Files in a Directory

`listFiles` returns a list of `GitStorageFile` for a given path.

```dart
Future<void> list(String path) async {
  try {
    final files = await client.listFiles(path);
    for (final file in files) {
      print('File: ${file.name}, Size: ${file.formattedSize}');
    }
  } catch (e) {
    print('An error occurred: $e');
  }
}
```

#### Get a Specific File

`getFile` retrieves file metadata including the `download_url`.

```dart
Future<void> get(String path) async {
  try {
    final file = await client.getFile(path);
    print('File found: ${file.name}');
  } catch (e) {
    print('An error occurred: $e');
  }
}
```

#### Create a Folder

`createFolder` creates a logical folder by adding `.gitkeep`. The operation is idempotent.

```dart
Future<void> createDirectory(String path) async {
  try {
    await client.createFolder(path);
    print('Folder created successfully!');
  } catch (e) {
    print('An error occurred: $e');
  }
}
```

#### Delete a File
`deleteFile` removes a file from the repository.

```dart
Future<void> delete(String path) async {
  try {
    await client.deleteFile(path);
    print('File deleted successfully!');
  } catch (e) {
    print('An error occurred: $e');
  }
}

#### Edit and Read Content

Write and read strings/bytes in repository paths:

```dart
// Write string content (creates or updates the file)
await client.putString('Hello World', 'notes/hello.txt');

// Read string content
final text = await client.getString('notes/hello.txt');

// Write binary data
await client.putBytes([0xDE, 0xAD, 0xBE, 0xEF], 'bin/data.bin');

// Read binary data
final data = await client.getBytes('bin/data.bin');

// Update using a local file
await client.updateFile(File('/local/path/config.json'), 'configs/config.json');
```

### 4. GitStorageDB (JSON storage — encrypted or not)

Use `GitStorageDB` to persist JSON documents in the repository. Each collection is a folder under `db/`. With encryption enabled, each document is a `<id>.json.enc` file encrypted with AES-GCM and a key derived via PBKDF2-HMAC-SHA256.

You can instantiate `GitStorageDB` using a single configuration object and choose the encryption type via the `CryptoType` enum:

```dart
import 'package:git_storage/git_storage.dart';

final db = GitStorageDB.fromConfig(
  GitStorageDBConfig(
    repoUrl: 'https://github.com/your-user/your-repository.git',
    token: 'YOUR_GITHUB_PAT',
    branch: 'main',
    basePath: 'db',
    cryptoType: CryptoType.aesGcm256, // or CryptoType.none
    passphrase: 'strong-passphrase',   // required if not using none
  ),
);

// Using no encryption (plain JSON stored in the repository)
final dbPlain = GitStorageDB.fromConfig(
  GitStorageDBConfig(
    repoUrl: 'https://github.com/your-user/your-repository.git',
    token: 'YOUR_GITHUB_PAT',
    cryptoType: CryptoType.none,
    basePath: 'db_plain',
  ),
);
```

```dart
import 'package:git_storage/git_storage.dart';

final client = GitStorageClient(
  repoUrl: 'https://github.com/your-user/your-repository.git',
  token: 'YOUR_GITHUB_PAT',
);

final db = GitStorageDB(client: client, passphrase: 'strong-passphrase');

Future<void> exampleDb() async {
  await db.createCollection('users');
  await db.put('users', 'u1', {
    'name': 'Alice',
    'email': 'alice@example.com',
  });

  final alice = await db.get('users', 'u1');
  print('Alice: ' + alice.toString());

  await db.update('users', 'u1', (current) {
    current['email'] = 'alice@newdomain.com';
    return current;
  });

  final ids = await db.listIds('users');
  print('IDs: $ids');

  await db.delete('users', 'u1');

  // Remover coleção inteira (remove documentos e .gitkeep)
  await db.dropCollection('users');
}
```

Security note: choose a strong passphrase and rotate it as needed. When `cryptoType != CryptoType.none`, documents are encrypted client-side using AES-GCM, with keys derived via PBKDF2-HMAC-SHA256.

#### ID Strategy (UUID, timestamp, manual)

You can automatically generate IDs when adding documents by choosing the desired strategy, or opt to set them manually:

```dart
// Gerar ID automaticamente (padrão UUID v4)
final generatedId = await db.add('users', {
  'name': 'Maria',
  'email': 'maria@example.com',
});

// Usar timestamp em milissegundos
final idTs = await db.add('users', {
  'name': 'João',
}, strategy: IdStrategy.timestampMs);

// Definir manualmente
final idManual = await db.add('users', {
  'name': 'Carol',
}, strategy: IdStrategy.manual, manualId: 'user_carol');

// Também é possível criar um GitStorageDoc com ID gerado
final doc = GitStorageDoc.create(IdStrategy.uuidV4, {
  'name': 'Luiza',
});
await db.put('users', doc.id, doc.data);
```
```

#### Query API (where, orderBy, limit)

Você pode consultar uma coleção usando filtros, ordenação e limite de resultados:

```dart
import 'package:git_storage/git_storage.dart';

final db = GitStorageDB.fromConfig(GitStorageDBConfig(
  repoUrl: 'https://github.com/your-user/your-repository.git',
  token: 'YOUR_GITHUB_PAT',
  cryptoType: CryptoType.aesGcm256,
  passphrase: 'strong-passphrase',
));

final results = await db.query(
  'users',
  filters: [
    DBFilter.where('age', DBOperator.greaterOrEqual, 18),
    DBFilter.where('tags', DBOperator.arrayContains, 'premium'),
  ],
  orderBy: 'profile.lastLogin',
  descending: true,
  limit: 10,
);

for (final doc in results) {
  print('id=${doc.id} name=${doc.data['name']}');
}
```

Or using the chainable `QueryBuilder`:

```dart
final qb = db.queryBuilder('orders')
  .where('status', DBOperator.equal, 'paid')
  .where('items', DBOperator.arrayContainsAny, ['sku123', 'sku456'])
  .orderBy('createdAt', descending: true)
  .offset(20)
  .limit(20);

final res = await db.query(
  qb.getCollection(),
  filters: qb.getFilters(),
  orderBy: qb.getOrderBy(),
  descending: qb.getDescending(),
  limit: qb.getLimit(),
  offset: qb.getOffset(),
);
```

#### Transactions

Group multiple operations and commit them sequentially from the client side:

```dart
import 'package:git_storage/git_storage.dart';

final tx = GitStorageTransaction(db);
tx.put('users', 'u1', {'name': 'Ana'});
tx.update('users', 'u1', (cur) => {...cur, 'age': 30});
tx.delete('users', 'u2');
await tx.commit();

// Usando add dentro da transação com geração de ID
final tx2 = GitStorageTransaction(db);
final newId = tx2.add('users', {'name': 'Bruno'}, strategy: IdStrategy.uuidV4);
tx2.update('users', newId, (cur) => {...cur, 'age': 22});
await tx2.commit();
```


#### Migrations

Add a simple migrations system to create collections, seeds or structural changes.
Progress is persisted in `_meta/migrations` inside the repository and is idempotent.

```dart
import 'package:git_storage/git_storage.dart';

final migrations = [
  Migration(
    id: '2025-10-05-001-init-users',
    description: 'Cria coleção users e adiciona seed inicial',
    up: (db) async {
      await db.createCollection('users');
      await db.add('users', {
        'name': 'Admin',
        'email': 'admin@example.com',
        'createdAt': DateTime.now().toIso8601String(),
      }, strategy: IdStrategy.uuidV4);
    },
  ),
  Migration(
    id: '2025-10-05-002-add-profiles',
    up: (db) async {
      await db.createCollection('profiles');
    },
  ),
];

// Aplica migrations (só aplica novas)
await db.runMigrations(migrations);

// Consultar migrations aplicadas
final applied = await db.getAppliedMigrations();
print('Applied: $applied');
```


#### Logging

You can enable execution logs to follow calls and results of `GitStorageDB` methods.

Enable via single configuration:

```dart
final db = GitStorageDB.fromConfig(
  GitStorageDBConfig(
    repoUrl: 'https://github.com/your-user/your-repository.git',
    token: 'YOUR_GITHUB_PAT',
    cryptoType: CryptoType.aesGcm256,
    passphrase: 'strong-passphrase',
    enableLogs: true, // habilita logs
  ),
);
```

Or in the direct constructor:

```dart
final db = GitStorageDB(
  client: client,
  passphrase: 'strong-passphrase',
  enableLogs: true,
);
```

Example output:

```
[GitStorageDB] createCollection: users
[GitStorageDB] put: users/u1 message=
[GitStorageDB] get: users/u1
[GitStorageDB] get: users/u1 ok keys=2
[GitStorageDB] query: users filters=1 orderBy=profile.lastLogin desc=true limit=10 offset=0
[GitStorageDB] query: users retornou 10 documentos (limit aplicado)
```

Note: logs are informational and do not guarantee atomicity. Transaction operations are executed sequentially on the client side.


## Example

A complete example is available in the [`/example`](/example) directory.

## Contributions

Contributions are welcome! If you find a bug or have a suggestion, please open an [Issue](https://github.com/yourusername/git_storage/issues) or submit a [Pull Request](https://github.com/yourusername/git_storage/pulls).

## License

This package is licensed under the [MIT License](LICENSE).
