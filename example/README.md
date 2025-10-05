# Example: Git Storage

This Flutter example demonstrates how to use the `git_storage` package to upload files and manage them via a GitHub repository, and how to use the encrypted JSON store `GitStorageDB`.

## Setup

1. Create a GitHub Personal Access Token (PAT) with `repo` permissions.
2. In `example/lib/main.dart`, set your `repoUrl`, `token` and `branch`.

## File operations (UI)

The example app lets you:
- Pick a file and upload it to the repository
- List files in a folder (e.g., `uploads/`)
- Open file via `download_url`
- Delete files

## Encrypted JSON DB (code)

For simple `GitStorageDB` usage, check the console entrypoints under `lib/`: `main_seed.dart`, `main_assign_filters.dart`, and `main_queries.dart`.

```dart
final client = GitStorageClient(repoUrl: 'https://github.com/your/repo.git', token: 'PAT');
final db = GitStorageDB(client: client, passphrase: 'strong-passphrase');

await db.createCollection('users');
await db.put(collection: 'users', id: 'u1', json: {'name': 'Alice'});
final alice = await db.get('users', 'u1');
await db.update(collection: 'users', id: 'u1', updater: (doc) { doc['name'] = 'Alice Updated'; return doc; });
await db.delete('users', 'u1');
```

You can also configure with a single `GitStorageDBConfig` and choose encryption type:

```dart
final dbCfg = GitStorageDB.fromConfig(GitStorageDBConfig(
  repoUrl: 'https://github.com/your/repo.git',
  token: 'PAT',
  cryptoType: CryptoType.aesGcm256, // or CryptoType.none
  passphrase: 'strong-passphrase',   // required if not using none
));
```

Run the app with `flutter run`.

## CLI entrypoints (no UI)

Besides the Flutter app, there are three console entrypoints in `lib/` that you can run with `dart run`:

- `lib/main_seed.dart`: seeds `users` and `products` collections with basic data.
- `lib/main_assign_filters.dart`: filters users and assigns products using `QueryBuilder`.
- `lib/main_queries.dart`: demonstrates various queries (where, orderBy, limit, offset, arrayContains).

How to run (configure environment variables or edit the files):

```
export REPO_URL=https://github.com/your-user/your-repository.git
export GITHUB_TOKEN=YOUR_GITHUB_PAT
export BRANCH=main
export DB_PASSPHRASE=strong-passphrase

dart run lib/main_seed.dart
dart run lib/main_assign_filters.dart
dart run lib/main_queries.dart
```

Note: operations that generate a series of commits can take time due to the GitHub API. Avoid high concurrency to prevent branch conflicts (HTTP 409).
