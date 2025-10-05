import 'dart:io';
import 'dart:math';

import 'package:git_storage/git_storage.dart';

/// Cria (se necessário) e atribui produtos aos usuários usando filtros.
/// Demonstra uso de QueryBuilder: where/orderBy/limit.
void main() async {
  final repoUrl = Platform.environment['REPO_URL'] ?? 'https://github.com/your-user/your-repository.git';
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

  // Garante que coleções existam
  await db.createCollection('users');
  await db.createCollection('products');

  // Se não houver produtos, cria alguns rapidamente
  final existingProducts = await db.listIds('products');
  if (existingProducts.isEmpty) {
    for (final p in [
      {'name': 'Kit Jardinagem', 'price': 79.90, 'stock': 12},
      {'name': 'Mangueira Flexível', 'price': 59.90, 'stock': 20},
      {'name': 'Sementes Orgânicas', 'price': 14.00, 'stock': 40},
      {'name': 'Adubo NPK', 'price': 38.50, 'stock': 30},
    ]) {
      await db.add('products', p);
    }
  }

  // Exemplo de filtros: buscar usuários com age >= 30, ordenados por nome, limit 10
  final filteredUsers = await db
      .collection('users')
      .where('age', DBOperator.greaterOrEqual, 30)
      .orderBy('name')
      .limit(10)
      .get();

  if (filteredUsers.isEmpty) {
    stdout.writeln('Nenhum usuário com age >= 30 encontrado.');
    return;
  }

  stdout.writeln('Usuários filtrados: ${filteredUsers.length}');
  final random = Random();

  // Para cada usuário filtrado, atribui 1-2 produtos aleatórios
  final productIds = await db.listIds('products');
  for (final user in filteredUsers) {
    final numProducts = 1 + random.nextInt(2); // 1 ou 2
    final picks = <String>[];
    for (var i = 0; i < numProducts && productIds.isNotEmpty; i++) {
      picks.add(productIds[random.nextInt(productIds.length)]);
    }

    final data = Map<String, dynamic>.from(user.data);
    final current = (data['products'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    for (final pid in picks) {
      if (!current.contains(pid)) current.add(pid);
    }

    // Persistir com put para evitar GET adicional
    await db.put('users', user.id, data);
    stdout.writeln('Atribuídos ${picks.length} produtos ao usuário ${user.id}.');
  }

  stdout.writeln('Atribuições concluídas com filtros.');
}