enum DBOperator {
  equal,
  notEqual,
  greaterThan,
  greaterOrEqual,
  lessThan,
  lessOrEqual,
  arrayContains,
  inList,
  arrayContainsAny,
  notIn,
}

class DBFilter {
  final String fieldPath;
  final DBOperator op;
  final dynamic value;

  DBFilter._(this.fieldPath, this.op, this.value);

  static DBFilter where(String fieldPath, DBOperator op, dynamic value) =>
      DBFilter._(fieldPath, op, value);

  bool matches(Map<String, dynamic> data) {
    dynamic current = data;
    for (final part in fieldPath.split('.')) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else {
        current = null;
        break;
      }
    }
    final left = current;
    switch (op) {
      case DBOperator.equal:
        return left == value;
      case DBOperator.notEqual:
        return left != value;
      case DBOperator.greaterThan:
        return (left is Comparable && value is Comparable)
            ? (left as Comparable).compareTo(value) > 0
            : false;
      case DBOperator.greaterOrEqual:
        return (left is Comparable && value is Comparable)
            ? (left as Comparable).compareTo(value) >= 0
            : false;
      case DBOperator.lessThan:
        return (left is Comparable && value is Comparable)
            ? (left as Comparable).compareTo(value) < 0
            : false;
      case DBOperator.lessOrEqual:
        return (left is Comparable && value is Comparable)
            ? (left as Comparable).compareTo(value) <= 0
            : false;
      case DBOperator.arrayContains:
        return (left is List) ? left.contains(value) : false;
      case DBOperator.inList:
        return (value is List) ? value.contains(left) : false;
      case DBOperator.arrayContainsAny:
        return (left is List && value is List)
            ? value.any((v) => left.contains(v))
            : false;
      case DBOperator.notIn:
        return (value is List) ? !value.contains(left) : false;
    }
  }
}