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
  // Existence / nullability
  exists,
  notExists,
  isNull,
  isNotNull,
  // String operations
  startsWith,
  endsWith,
  stringContains,
  // Emptiness
  isEmpty,
  isNotEmpty,
  // List operations
  containsAll,
  // Range and pattern
  between,
  regexMatch,
}

class DBFilter {
  final String fieldPath;
  final DBOperator op;
  final dynamic value;

  DBFilter._(this.fieldPath, this.op, this.value);

  static DBFilter where(String fieldPath, DBOperator op, [dynamic value]) =>
      DBFilter._(fieldPath, op, value);

  bool matches(Map<String, dynamic> data) {
    dynamic current = data;
    bool found = true;
    for (final part in fieldPath.split('.')) {
      if (current is Map<String, dynamic>) {
        if ((current as Map<String, dynamic>).containsKey(part)) {
          current = (current as Map<String, dynamic>)[part];
        } else {
          found = false;
          current = null;
          break;
        }
      } else {
        found = false;
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
      case DBOperator.exists:
        return found;
      case DBOperator.notExists:
        return !found;
      case DBOperator.isNull:
        return left == null;
      case DBOperator.isNotNull:
        return left != null;
      case DBOperator.startsWith:
        return (left is String && value is String)
            ? left.startsWith(value)
            : false;
      case DBOperator.endsWith:
        return (left is String && value is String)
            ? left.endsWith(value)
            : false;
      case DBOperator.stringContains:
        return (left is String && value is String)
            ? left.contains(value)
            : false;
      case DBOperator.isEmpty:
        if (left is String) return left.isEmpty;
        if (left is List) return left.isEmpty;
        if (left is Map) return left.isEmpty;
        return false;
      case DBOperator.isNotEmpty:
        if (left is String) return left.isNotEmpty;
        if (left is List) return left.isNotEmpty;
        if (left is Map) return left.isNotEmpty;
        return false;
      case DBOperator.containsAll:
        return (left is List && value is List)
            ? (value as List).every((v) => (left as List).contains(v))
            : false;
      case DBOperator.between:
        if (left is Comparable && value is List && value.length == 2) {
          final a = value[0];
          final b = value[1];
          if (a is Comparable && b is Comparable) {
            final cmpA = (left as Comparable).compareTo(a);
            final cmpB = (left as Comparable).compareTo(b);
            return cmpA >= 0 && cmpB <= 0;
          }
        }
        return false;
      case DBOperator.regexMatch:
        if (left is String) {
          if (value is RegExp) return value.hasMatch(left);
          if (value is String) return RegExp(value).hasMatch(left);
        }
        return false;
    }
  }
}