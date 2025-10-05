import 'db_filter.dart';

class QueryBuilder {
  final String collection;
  final List<DBFilter> _filters = [];
  String? _orderBy;
  bool _descending = false;
  int? _limit;
  int _offset = 0;

  QueryBuilder(this.collection);

  QueryBuilder where(String fieldPath, DBOperator op, dynamic value) {
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
}