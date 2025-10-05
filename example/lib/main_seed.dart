import 'dart:io';

import 'package:git_storage/git_storage.dart';

/// Semear dados básicos: cria coleções, adiciona usuários e produtos.
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
    enableLogs: true,
  ));

  // await db.dropCollection('users');
  // await db.dropCollection('products');

  // Garante coleções
  await db.createCollection('users');
  await db.createCollection('products');

  // Usuários exemplo
  final users = [
    {'name': 'Alice', 'email': 'alice@example.com', 'age': 26},
    {'name': 'Bruno', 'email': 'bruno@example.com', 'age': 32},
    {'name': 'Carla', 'email': 'carla@example.com', 'age': 29},
    {'name': 'Diego', 'email': 'diego@example.com', 'age': 41},
  ];

  final userIds = <String>[];
  for (final u in users) {
    final GitStorageTransaction transaction = GitStorageTransaction(db);
    final id = transaction.add('users', u);
    await transaction.commit();
    userIds.add(id);
  }
  stdout.writeln('Criados ${userIds.length} usuários:');
  for (final id in userIds) {
    stdout.writeln(' - $id');
  }

  // Produtos exemplo
  final products = [
    {'name': 'Vaso de Cerâmica', 'price': 49.90, 'stock': 10},
    {'name': 'Terra Vegetal 5kg', 'price': 29.90, 'stock': 25},
    {'name': 'Regador Automático', 'price': 99.00, 'stock': 8},
  ];

  final productIds = <String>[];
  for (final p in products) {
    final id = await db.add('products', p);
    productIds.add(id);
  }
  stdout.writeln('Criados ${productIds.length} produtos:');
  for (final id in productIds) {
    stdout.writeln(' - $id');
  }

  stdout.writeln('Seed concluído.');
}
