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

See `lib/db_example.dart` for a simple usage of `GitStorageDB`:

```dart
final client = GitStorageClient(repoUrl: 'https://github.com/your/repo.git', token: 'PAT');
final db = GitStorageDB(client: client, passphrase: 'strong-passphrase');

await db.createCollection('users');
await db.put('users', 'u1', {'name': 'Alice'});
final alice = await db.get('users', 'u1');
await db.update('users', 'u1', (doc) { doc['name'] = 'Alice Updated'; return doc; });
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

## CLI mains (sem UI)

Além do app Flutter, há três entrypoints de console em `lib/` que você pode executar com `dart run`:

- `lib/main_seed.dart`: semeia coleções `users` e `products` com dados básicos.
- `lib/main_assign_filters.dart`: filtra usuários e atribui produtos usando `QueryBuilder`.
- `lib/main_queries.dart`: demonstra consultas diversas (where, orderBy, limit, offset, arrayContains).

Como executar (configure variáveis de ambiente ou edite o arquivo):

```
export REPO_URL=https://github.com/your-user/your-repository.git
export GITHUB_TOKEN=YOUR_GITHUB_PAT
export BRANCH=main
export DB_PASSPHRASE=strong-passphrase

dart run lib/main_seed.dart
dart run lib/main_assign_filters.dart
dart run lib/main_queries.dart
```

Observação: operações que geram commits em série podem demorar devido à API do GitHub. Evite concorrência alta para não gerar conflitos de branch (HTTP 409).
