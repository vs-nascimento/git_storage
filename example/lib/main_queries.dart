import 'dart:io';

import 'package:git_storage/git_storage.dart';

/// Demonstra diversas consultas com QueryBuilder e getAll.
void main() async {
  final repoUrl = Platform.environment['REPO_URL'] ??
      'https://github.com/your-user/your-repository.git';
  final token = Platform.environment['GITHUB_TOKEN'] ?? 'YOUR_GITHUB_PAT';
  final branch = Platform.environment['BRANCH'] ?? 'main';

  final db = GitStorageDB.fromConfig(GitStorageDBConfig(
    repoUrl: repoUrl,
    token: token,
    branch: branch,
    basePath: 'db',
    cryptoType: CryptoType.aesGcm256,
    passphrase: Platform.environment['DB_PASSPHRASE'] ?? 'strong-passphrase',
  ));

  await db.createCollection('users');
  await db.createCollection('products');

  // Exemplo 1: listar todos usuários
  final allUsers = await db.getAll('users');
  stdout.writeln('Total de usuários: ${allUsers.length}');

  // Exemplo 2: usuários jovens ordenados por idade desc
  final youngDesc = await db
      .collection('users')
      .where('age', DBOperator.lessThan, 30)
      .orderBy('age', descending: true)
      .get();
  stdout.writeln('Usuários <30 (desc idade): ${youngDesc.length}');

  // Exemplo 3: produtos com estoque > 10
  final inStock = await db
      .collection('products')
      .where('stock', DBOperator.greaterThan, 10)
      .get();
  stdout.writeln('Produtos com estoque > 10: ${inStock.length}');

  // Exemplo 4: usuários com produto específico via arrayContains
  if (inStock.isNotEmpty) {
    final firstProductId = inStock.first.id;
    final userHasProduct = await db
        .collection('users')
        .where('products', DBOperator.arrayContains, firstProductId)
        .get();
    stdout.writeln(
        'Usuários com produto $firstProductId: ${userHasProduct.length}');
  }

  // Exemplo 5: paginação simples com offset/limit
  final page =
      await db.collection('users').orderBy('name').offset(0).limit(2).get();
  stdout.writeln('Página 1 (5 usuários): ${page.length}');
}
