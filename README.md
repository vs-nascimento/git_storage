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
 - **Crypto variants:** AES-GCM-128/256 and ChaCha20-Poly1305 with configurable PBKDF2 iterations.
  - **Logging:** Pluggable `LogListener` with levels (none, info, debug, error) for API and DB operations.

## What's New in 2.1.0

- Performance: JSON encode/decode and UTF-8 conversions are offloaded to isolates across client and DB operations.
- Client: `getFile`, `listFiles`, and `getBytes` responses are parsed in isolates for improved responsiveness.
- DB: `put` encodes documents and `getAll` performs bulk reads using isolates with bounded concurrency.
- Crypto: Envelope JSON creation and plaintext conversions use isolates for better throughput.
- Docs: README updated with performance notes and tips.

### Web/WASM Compatibility

This package currently is not compatible with the Web/WASM runtime. Some implementation aspects (e.g., isolates and `dart:io` usage) are not supported on WASM at the moment. For details on Dart WebAssembly, see `https://dart.dev/web/wasm`.

  - **Performance:** JSON encode/decode and UTF-8 conversions are offloaded to isolates for large payloads.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  git_storage: ^2.0.0 # Check for the latest version
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
```

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

#### Read bytes via download_url

When you already have the `download_url` (from `listFiles` or `getFile`), you can read the raw bytes directly using `getBytesFromUrl`, reducing extra API calls:

```dart
// List files and read bytes directly from download_url
final files = await client.listFiles('bin');
for (final f in files) {
  if (f.downloadUrl.isNotEmpty) {
    final bytes = await client.getBytesFromUrl(f.downloadUrl);
    print('Read ${bytes.length} bytes from ${f.path}');
  }
}
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
    cryptoType: CryptoType.aesGcm256, // or CryptoType.none, aesGcm128, chacha20Poly1305
    passphrase: 'strong-passphrase',   // required if not using none
    pbkdf2Iterations: 150000,
    enableLogs: true,
    logLevel: LogLevel.info,
    logListener: DefaultLogListener(level: LogLevel.info).call,
    // Performance: control maximum read concurrency (default: 6)
    readConcurrency: 8,
  ),
);

// Using no encryption (plain JSON stored in the repository)
final dbPlain = GitStorageDB.fromConfig(
  GitStorageDBConfig(
    repoUrl: 'https://github.com/your-user/your-repository.git',
    token: 'YOUR_GITHUB_PAT',
    cryptoType: CryptoType.none,
    basePath: 'db_plain',
    enableLogs: true,
    logLevel: LogLevel.debug,
    logListener: DefaultLogListener(level: LogLevel.debug).call,
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
  await db.put(collection: 'users', id: 'u1', json: {
    'name': 'Alice',
    'email': 'alice@example.com',
  });

  final alice = await db.get('users', 'u1');
  print('Alice: ' + alice.toString());

  await db.update(collection: 'users', id: 'u1', updater: (current) {
    current['email'] = 'alice@newdomain.com';
    return current;
  });

  final ids = await db.listIds('users');
  print('IDs: $ids');

  await db.delete('users', 'u1');

  // Remove entire collection (deletes documents and .gitkeep)
  await db.dropCollection('users');
}
```

Security note: choose a strong passphrase and rotate it as needed. When `cryptoType != CryptoType.none`, documents are encrypted client-side using AES-GCM, with keys derived via PBKDF2-HMAC-SHA256.

### Performance Notes

- JSON parsing and string encoding/decoding can be expensive for large documents. This package now offloads these operations to isolates when appropriate to keep the main thread responsive.
- Tune `readConcurrency` in `GitStorageDBConfig` for faster bulk reads depending on your environment and repository size.
- Prefer `getBytesFromUrl(download_url)` when available to skip extra metadata calls.

#### ID Strategy (UUID, timestamp, manual)

You can automatically generate IDs when adding documents by choosing a strategy, or set IDs manually. You can also create a `GitStorageDoc` with the desired strategy:

```dart
// Auto-generate ID (default UUID v4)
final generatedId = await db.add(collection: 'users', json: {
  'name': 'Maria',
  'email': 'maria@example.com',
});

// Use timestamp in milliseconds
final idTs = await db.add(collection: 'users', json: {
  'name': 'John',
}, strategy: IdStrategy.timestampMs);

// Set ID manually
final idManual = await db.add(collection: 'users', json: {
  'name': 'Carol',
}, strategy: IdStrategy.manual, manualId: 'user_carol');

// Create a GitStorageDoc with generated ID using convenience constructors
final doc1 = GitStorageDoc.uuidV4({ 'name': 'Luiza' });
final doc2 = GitStorageDoc.timestampMs({ 'name': 'Marc' });
final doc3 = GitStorageDoc.manual('user_anne', { 'name': 'Anne' });
await db.put(collection: 'users', id: doc1.id, json: doc1.data);
await db.put(collection: 'users', id: doc2.id, json: doc2.data);
await db.put(collection: 'users', id: doc3.id, json: doc3.data);
```

#### Query API (chainable)

Query collections using a chainable style similar to Firebase. No need to manually build or pass queries — just chain and call `get()`:

```dart
final results = await db
  .collection('users')
  .where('age', DBOperator.greaterOrEqual, 18)
  .where('tags', DBOperator.arrayContains, 'premium')
  .orderBy('profile.lastLogin', descending: true)
  .limit(10)
  .get();

for (final doc in results) {
  print('id=${doc.id} name=${doc.data['name']}');
}
```

Supported operators

- `equal`, `notEqual`, `greaterThan`, `greaterOrEqual`, `lessThan`, `lessOrEqual`
- `arrayContains`, `arrayContainsAny`, `inList`, `notIn`
- `exists`, `notExists`, `isNull`, `isNotNull`
- `startsWith`, `endsWith`, `stringContains`, `regexMatch`
- `isEmpty`, `isNotEmpty`
- `containsAll`
- `between`

Examples

```dart
// Existence / nullability (value optional)
await db
  .collection('users')
  .where('profile.lastLogin', DBOperator.exists)
  .where('middleName', DBOperator.isNull)
  .get();

// String operations
await db
  .collection('users')
  .where('name', DBOperator.startsWith, 'A')
  .where('email', DBOperator.endsWith, '@example.com')
  .where('bio', DBOperator.stringContains, 'developer')
  .where('username', DBOperator.regexMatch, r'^user_[0-9]+$')
  .get();

// Emptiness
await db
  .collection('users')
  .where('tags', DBOperator.isNotEmpty)
  .get();

// Lists
await db
  .collection('projects')
  .where('roles', DBOperator.containsAll, ['admin', 'editor'])
  .get();

// Range
await db
  .collection('users')
  .where('age', DBOperator.between, [18, 30])
  .get();
```

Notes

- `exists`/`notExists` check the presence of the key in the JSON, independent of its value (even if `null`).
- `isNull`/`isNotNull` check the value itself.
- For `exists`, `notExists`, `isNull`, `isNotNull`, `isEmpty`, and `isNotEmpty`, the `value` argument is optional and should be omitted.
- For `regexMatch`, you can pass either a `RegExp` instance or a `String` pattern.

#### Transactions

Group multiple operations and commit them sequentially from the client side:

```dart
import 'package:git_storage/git_storage.dart';

final tx = GitDBTransaction(db);
tx.put(collection: 'users', id: 'u1', json: {'name': 'Ana'});
tx.update(collection: 'users', id: 'u1', updater: (cur) => {...cur, 'age': 30});
tx.delete('users', 'u2');
await tx.commit();

// Using add inside a transaction with ID generation
final tx2 = GitDBTransaction(db);
final newId = tx2.add(collection: 'users', json: {'name': 'Bruno'}, strategy: IdStrategy.uuidV4);
tx2.update(collection: 'users', id: newId, updater: (cur) => {...cur, 'age': 22});
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
    description: 'Create users collection and add initial seed',
    up: (db) async {
      await db.createCollection('users');
      await db.add(collection: 'users', json: {
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

// Apply migrations (only applies new ones)
await db.runMigrations(migrations);

// List applied migrations
final applied = await db.getAppliedMigrations();
print('Applied: $applied');
```


#### Logging

You can enable execution logs to follow calls and results of `GitStorageDB` and client methods.
Logs are emitted via a pluggable `LogListener`. The default listener uses `dart:developer.log`, integrating with IDE consoles and observatory tools.

Enable via single configuration:

```dart
final db = GitStorageDB.fromConfig(
  GitStorageDBConfig(
    repoUrl: 'https://github.com/your-user/your-repository.git',
    token: 'YOUR_GITHUB_PAT',
    cryptoType: CryptoType.aesGcm256,
    passphrase: 'strong-passphrase',
    enableLogs: true, // enables console logs when no listener is provided
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


Notes:
- When `logListener` is provided and the message level is >= `logLevel`, the listener handles logs.
- When `logListener` is null and `enableLogs` is true, internal fallbacks emit via `developer.log`.
- Levels: `none`, `error`, `info`, `debug`. Only messages at or above `logLevel` are emitted.
- Logs are informational and do not guarantee atomicity. Transaction operations are executed sequentially on the client side.

#### Contracts (schema validation)

Use the integrated `schema` parameter to ensure your documents have expected keys and types before writing or updating:

```dart
import 'package:git_storage/git_storage.dart';

final schema = {
  'email': String,
  'age': int,
  // nested paths are supported
  'profile.active': bool,
};

// put with contract (known ID)
await db.put(
  collection: 'users',
  id: 'user-123',
  json: {'email': 'a@b.com', 'age': 30, 'profile': {'active': true}},
  schema: schema,
);

// add with contract (auto-generated ID)
final newId = await db.add(
  collection: 'users',
  json: {'email': 'c@d.com', 'age': 22, 'profile': {'active': false}},
  schema: schema,
);

// update with contract (validates updater result)
await db.update(
  collection: 'users',
  id: newId,
  updater: (cur) => {
    ...cur,
    'age': (cur['age'] as int) + 1,
  },
  schema: schema,
);
```

If a key is missing or the type doesn't match, a `GitStorageException` is thrown with details.


## Example

A complete example is available in the [`/example`](/example) directory.

## Contributions

Contributions are welcome! If you find a bug or have a suggestion, please open an [Issue](https://github.com/yourusername/git_storage/issues) or submit a [Pull Request](https://github.com/yourusername/git_storage/pulls).

## License

This package is licensed under the [MIT License](LICENSE).
### Performance Tips

- `QueryBuilder.get()` and `GitStorageDB.getAll()` use file listing and bounded parallel reads, drastically reducing calls per document.
- Tune `GitStorageDBConfig.readConcurrency` according to API limits (6–10 is typically safe for personal use). With a standard PAT: typical 5,000 req/h; avoid aggressive spikes.
- `GitStorageClient.getBytes` uses the Contents API to read base64 content directly, avoiding an extra metadata call.
- When you already have the `download_url`, prefer `getBytesFromUrl` for direct byte reading.
- For batch write operations, avoid parallelism to prevent branch conflicts (`409`). Use serialization, transactions (`GitStorageTransaction`), or backoff/retry.
