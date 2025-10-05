import '../services/git_storage_db.dart';

/// Representa uma migration aplicável ao GitStorageDB.
class Migration {
  /// Identificador único e ordenável da migration (ex.: `2025-10-05-001-add-users`).
  final String id;

  /// Descrição opcional.
  final String description;

  /// Função que aplica a migration.
  final Future<void> Function(GitStorageDB db) up;

  Migration({
    required this.id,
    required this.up,
    this.description = '',
  });
}