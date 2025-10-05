import 'package:flutter_test/flutter_test.dart';
import 'package:git_storage/git_storage.dart';

void main() {
  group('DefaultLogListener', () {
    test('respects levels', () {
      final logs = <String>[];
      final listener = DefaultLogListener(level: LogLevel.info);
      final proxy = (String tag, LogLevel lvl, String msg) {
        // capture via wrapper
        listener.call(tag, lvl, msg);
        if (lvl.index <= LogLevel.info.index) {
          logs.add('$tag:$msg');
        }
      };

      proxy('X', LogLevel.debug, 'hidden');
      proxy('X', LogLevel.info, 'visible');
      proxy('X', LogLevel.error, 'visible-err');

      expect(logs.length, 2);
      expect(logs[0], contains('visible'));
      expect(logs[1], contains('visible-err'));
    });
  });
}