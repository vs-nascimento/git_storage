import 'package:git_storage/git_storage.dart';

Future<void> runDbExample() async {
  final db = GitStorageDB.fromConfig(GitStorageDBConfig(
    repoUrl: '...',
    token: '...',
    branch: 'main',
    basePath: 'db',
    cryptoType: CryptoType.aesGcm256,
    passphrase: 'strong-passphrase',
    enableLogs: true,
  ));

  const collection = 'users';

  final user = GitStorageDoc(
    id: 'user_123',
    data: {
      'name': 'John Doe',
      'email': 'email@gg.com',
      'age': 30,
    },
  );
  await db.add(collection, user.data);
}

void main() async {
  await runDbExample();
}
