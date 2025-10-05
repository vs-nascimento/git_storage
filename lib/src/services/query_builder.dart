import 'db_filter.dart';
import 'git_storage_db.dart';
import '../models/git_storage_doc.dart';

class QueryBuilder {
  final String collection;
  final List<DBFilter> _filters = [];
  String? _orderBy;
  bool _descending = false;
  int? _limit;
  int _offset = 0;
  GitStorageDB? _db;

  QueryBuilder(this.collection);

  /// Named constructor para usar com contexto de DB e permitir `.get()`
  QueryBuilder.withDB(GitStorageDB db, String collection)
      : collection = collection,
        _db = db;

  QueryBuilder where(String fieldPath, DBOperator op, [dynamic value]) {
    _filters.add(DBFilter.where(fieldPath, op, value));
    return this;
  }

  QueryBuilder orderBy(String fieldPath, {bool descending = false}) {
    _orderBy = fieldPath;
    _descending = descending;
    return this;
  }

  QueryBuilder limit(int n) {
    _limit = n;
    return this;
  }

  QueryBuilder offset(int n) {
    _offset = n;
    return this;
  }

  String getCollection() => collection;
  List<DBFilter> getFilters() => List.unmodifiable(_filters);
  String? getOrderBy() => _orderBy;
  bool getDescending() => _descending;
  int? getLimit() => _limit;
  int getOffset() => _offset;

  /// Executa a consulta usando o contexto de DB.
  Future<List<GitStorageDoc>> get() async {
    if (_db == null) {
      throw StateError(
          'QueryBuilder sem contexto de DB. Use db.collection(name) para encadear e chamar get().');
    }
    // Carrega documentos da coleção usando getAll otimizado (concorrência limitada)
    final docs = await _db!.getAll(collection);

    // Aplica filtros
    final filtered = docs.where((doc) {
      for (final f in _filters) {
        if (!f.matches(doc.data)) return false;
      }
      return true;
    }).toList();

    // Ordena
    if (_orderBy != null) {
      filtered.sort((a, b) {
        final va = a.getAtPath(_orderBy!);
        final vb = b.getAtPath(_orderBy!);
        if (va is Comparable && vb is Comparable) {
          final cmp = (va as Comparable).compareTo(vb);
          return _descending ? -cmp : cmp;
        }
        return 0;
      });
    }

    // Offset
    if (_offset > 0) {
      final start = _offset < filtered.length ? _offset : filtered.length;
      if (start > 0) {
        filtered.removeRange(0, start);
      }
    }

    // Limita
    if (_limit != null && _limit! > 0 && filtered.length > _limit!) {
      return filtered.sublist(0, _limit!);
    }

    return filtered;
  }
}