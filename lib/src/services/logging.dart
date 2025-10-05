typedef LogListener = void Function(String tag, LogLevel level, String message);

enum LogLevel {
  none,
  error,
  info,
  debug,
}

class DefaultLogListener {
  final LogLevel level;

  DefaultLogListener({this.level = LogLevel.info});

  void call(String tag, LogLevel msgLevel, String message) {
    if (msgLevel.index > level.index) return;
    final ts = DateTime.now().toIso8601String();
    // Format: [ts] [level] [tag] message
    print('[$ts] [${_label(msgLevel)}] [$tag] $message');
  }

  String _label(LogLevel l) {
    switch (l) {
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.none:
        return 'NONE';
    }
  }
}