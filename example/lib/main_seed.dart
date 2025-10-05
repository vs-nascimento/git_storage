import 'dart:io';

import 'package:git_storage/git_storage.dart';

GitStorageDB createDb() {
  final repoUrl = Platform.environment['REPO_URL'] ??
      'https://github.com/your-user/your-repository.git';
  final token = Platform.environment['GITHUB_TOKEN'] ?? 'YOUR_GITHUB_PAT';
  final branch = Platform.environment['BRANCH'] ?? 'main';

  return GitStorageDB.fromConfig(GitStorageDBConfig(
    repoUrl: repoUrl,
    token: token,
    branch: branch,
    basePath: 'db',
    cryptoType: CryptoType.aesGcm256,
    passphrase: Platform.environment['DB_PASSPHRASE'] ?? 'strong-passphrase',
  ));
}

/// MAIN 1 — Initial seed: create collections, users, and products
Future<void> mainSeed() async {
  final db = createDb();

  await db.dropCollection('users');
  await db.dropCollection('products');
  await db.createCollection('users');
  await db.createCollection('products');

  final users = [
    {'name': 'Alice', 'email': 'alice@example.com', 'age': 26},
    {'name': 'Bruno', 'email': 'bruno@example.com', 'age': 32},
    {'name': 'Carla', 'email': 'carla@example.com', 'age': 29},
    {'name': 'Diego', 'email': 'diego@example.com', 'age': 41},
  ];

  for (final u in users) {
    final tx = GitDBTransaction(db);
    tx.add(collection: 'users', json: u);
    await tx.commit();
  }

  final products = [
    {'name': 'Ceramic Pot', 'price': 49.90, 'stock': 10},
    {'name': 'Vegetable Soil 5kg', 'price': 29.90, 'stock': 25},
    {'name': 'Automatic Watering Can', 'price': 33.0, 'stock': 8},
  ];

  for (final p in products) {
    await db.add(collection: 'products', json: p);
  }

  stdout.writeln('✅ Seed completed');
}

/// MAIN 2 — Migration: add "products" field to all users
Future<void> mainMigrate() async {
  final db = createDb();
  final allUsers = await db.getAll('users');

  await db.runMigrations([
    Migration(
      id: '001_add_products_field',
      up: (d) async {
        for (final user in allUsers) {
          final data = Map<String, dynamic>.from(user.data);
          if (!data.containsKey('products')) {
            data['products'] = [];
            await d.put(collection: 'users', id: user.id, json: data);
            stdout.writeln('🧩 User ${user.id} migrated.');
          }
        }
      },
    )
  ]);

  stdout.writeln('✅ Migration completed');
}

/// MAIN 3 — Link random products to each user
Future<void> mainLinkProducts() async {
  final db = createDb();
  final users = await db.getAll('users');
  final products = await db.getAll('products');

  for (final user in users) {
    final selected = (products..shuffle()).take(2).map((p) => p.id).toList();
    final updated = {...user.data, 'products': selected};
    final GitDBTransaction tx = GitDBTransaction(db);
    tx.update(
      collection: 'users',
      id: user.id,
      updater: (cur) => updated,
    );
    await tx.commit();
    stdout.writeln('🔗 User ${user.data['name']} linked to $selected');
  }

  stdout.writeln('✅ Linking completed');
}

/// MAIN 4 — Query: list all users and their associated products
Future<void> mainListUsersWithProducts() async {
  final db = createDb();
  final users = await db.getAll('users');
  final products = await db.getAll('products');

  stdout.writeln('\n📋 Users and their products:\n');
  for (final user in users) {
    final userProducts = (user.data['products'] ?? []) as List;
    final names = products
        .where((p) => userProducts.contains(p.id))
        .map((p) => p.data['name'])
        .toList();
    stdout.writeln('- ${user.data['name']} => $names');
  }
}

/// MAIN 5 — Delete a specific user
Future<void> mainDeleteUser() async {
  final db = createDb();
  final users = await db.getAll('users');
  if (users.isEmpty) {
    stdout.writeln('No users found.');
    return;
  }

  final first = users.first;
  await db.delete(collection: 'users', id: first.id);
  stdout.writeln('🗑️ User ${first.data['name']} deleted successfully.');
}

/// MAIN 6 — Clear all collections
Future<void> mainClear() async {
  final db = createDb();
  await db.dropCollection('users');
  await db.dropCollection('products');
  stdout.writeln('🧹 Database cleared!');
}

/// MAIN 7 — Query example: find users older than 30
Future<void> mainQuery() async {
  final db = createDb();
  final results = await db
      .collection('users')
      .where('age', DBOperator.greaterThan, 30)
      .get();

  stdout.writeln('👥 Users older than 30:');
  for (final r in results) {
    stdout.writeln('- ${r.data['name']} (${r.data['age']})');
  }
}

/// Switch between main functions here:
void main() async {
  // await mainSeed();
  // await mainMigrate();
  // await mainLinkProducts();
  // await mainListUsersWithProducts();
  // await mainDeleteUser();
  // await mainClear();
  // await mainQuery();
}
