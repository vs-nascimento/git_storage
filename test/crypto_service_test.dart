import 'package:flutter_test/flutter_test.dart';
import 'package:git_storage/git_storage.dart';

void main() {
  group('CryptoService', () {
    const pass = 'p@ssw0rd';
    final plaintext = '{"hello":"world","n":42}';

    test('none: encryptString returns plaintext', () async {
      final c = CryptoService(type: CryptoType.none);
      final enc = await c.encryptString(plaintext, pass);
      expect(enc, plaintext);
      final dec = await c.decryptToJson(plaintext, pass);
      expect(dec['hello'], 'world');
      expect(dec['n'], 42);
    });

    for (final t in [CryptoType.aesGcm128, CryptoType.aesGcm256, CryptoType.chacha20Poly1305]) {
      test('encrypt/decrypt $t', () async {
        final c = CryptoService(type: t, pbkdf2Iterations: 5000);
        final enc = await c.encryptString(plaintext, pass);
        expect(enc.contains('ciphertext'), isTrue);
        final dec = await c.decryptToJson(enc, pass);
        expect(dec['hello'], 'world');
        expect(dec['n'], 42);
      });
    }
  });
}