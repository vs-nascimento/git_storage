import 'dart:developer' as dev;

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
    // Use developer.log to emit structured logs with name and level
    dev.log('[$ts] [${_label(msgLevel)}] $message',
        name: tag, level: _intLevel(msgLevel), time: DateTime.now());
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

  int _intLevel(LogLevel l) {
    switch (l) {
      case LogLevel.error:
        return 1000;
      case LogLevel.info:
        return 800;
      case LogLevel.debug:
        return 500;
      case LogLevel.none:
        return 0;
    }
  }
}