import 'id_strategy.dart';

/// Representa um documento retornado por consultas do GitStorageDB.
class GitStorageDoc {
  final String id;
  final Map<String, dynamic> data;

  GitStorageDoc({required this.id, required this.data});

  /// Factory helper para criar documento gerando o ID conforme [IdStrategy].
  /// Para [IdStrategy.manual], informe [manualId].
  factory GitStorageDoc.create(IdStrategy strategy, Map<String, dynamic> data, {String? manualId}) {
    final id = IdGenerator.generate(strategy, manualId: manualId);
    return GitStorageDoc(id: id, data: data);
  }

  /// Obtém valor por caminho com dot-notation, ex: `profile.name`.
  dynamic getAtPath(String path) {
    final parts = path.split('.');
    dynamic current = data;
    for (final p in parts) {
      if (current is Map<String, dynamic> && current.containsKey(p)) {
        current = current[p];
      } else {
        return null;
      }
    }
    return current;
  }
}