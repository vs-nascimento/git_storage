import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import '../exceptions/exceptions.dart';
import 'logging.dart';
import '../utils/json_isolates.dart';

/// Tipos de criptografia suportados para o GitStorageDB.
enum CryptoType {
  /// Sem criptografia: os dados são armazenados em texto claro.
  none,

  /// AES-GCM com chave de 128 bits e KDF PBKDF2-HMAC-SHA256.
  aesGcm128,

  /// AES-GCM com chave de 256 bits e KDF PBKDF2-HMAC-SHA256.
  aesGcm256,

  /// ChaCha20-Poly1305 AEAD com KDF PBKDF2-HMAC-SHA256.
  chacha20Poly1305,
}

class CryptoService {
  final CryptoType type;
  final int pbkdf2Iterations;
  final LogListener? logListener;
  final LogLevel logLevel;

  final AesGcm _aesGcm128 = AesGcm.with128bits();
  final AesGcm _aesGcm256 = AesGcm.with256bits();
  final Chacha20 _chacha20 = Chacha20.poly1305Aead();

  CryptoService({
    this.type = CryptoType.aesGcm256,
    this.pbkdf2Iterations = 100000,
    this.logListener,
    this.logLevel = LogLevel.none,
  });

  Pbkdf2 _pbkdf2(int bits) => Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: pbkdf2Iterations,
        bits: bits,
      );

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt, {required int bits}) async {
    final secret = SecretKey(utf8.encode(passphrase));
    return _pbkdf2(bits).deriveKey(secretKey: secret, nonce: salt);
  }

  void _log(LogLevel level, String message) {
    if (logListener != null && level.index >= logLevel.index) {
      logListener!.call('CryptoService', level, message);
    }
  }

  Future<String> encryptString(String plaintext, String passphrase) async {
    if (type == CryptoType.none) {
      // No encryption: return plaintext directly
      _log(LogLevel.debug, 'EncryptString none -> plaintext length=${plaintext.length}');
      return plaintext;
    }
    final bytes = await JsonIsolates.utf8Encode(plaintext);
    return encryptBytes(bytes, passphrase);
  }

  Future<String> encryptBytes(List<int> data, String passphrase) async {
    if (type == CryptoType.none) {
      // No encryption: to keep a string representation, encode as base64
      _log(LogLevel.debug, 'EncryptBytes none -> base64 length=${data.length}');
      return base64Encode(data);
    }
    try {
      final s = _randomBytes(8 + 8);
      final n = _randomBytes(3 * 4);
      final ti = type.index - 1; // 0..2 para algoritmos válidos
      final kb = const [128, 256, 256][ti];
      final k = await _deriveKey(passphrase, s, bits: kb);
      final algos = [_aesGcm128, _aesGcm256, _chacha20];
      final names = ['AES-GCM-128', 'AES-GCM-256', 'ChaCha20-Poly1305'];
      final algo = algos[ti];
      final name = names[ti];
      final b = await algo.encrypt(data, secretKey: k, nonce: n);

      final e = {
        'v': 1,
        'alg': name,
        'kdf': 'PBKDF2-HMAC-SHA256-$pbkdf2Iterations',
        'salt': base64Encode(s),
        'nonce': base64Encode(n),
        'ciphertext': base64Encode(b.cipherText),
        'mac': base64Encode(b.mac.bytes),
      };
      _log(LogLevel.debug, 'EncryptBytes $name ok len=${data.length}');
      // Offload JSON encoding to an isolate for large envelopes
      return await JsonIsolates.encode(e);
    } catch (e) {
      throw GitStorageException('Erro ao criptografar: $e');
    }
  }

  Future<List<int>> decryptToBytes(String envelopeString, String passphrase) async {
    if (type == CryptoType.none) {
      // No encryption: interpret envelopeString as base64 of raw bytes
      try {
        final bytes = base64Decode(envelopeString);
        _log(LogLevel.debug, 'DecryptBytes none base64 -> len=${bytes.length}');
        return bytes;
      } catch (_) {
        // If not base64, maybe it was plaintext string -> return UTF-8 bytes
        final bytes = await JsonIsolates.utf8Encode(envelopeString);
        _log(LogLevel.debug, 'DecryptBytes none plaintext -> len=${bytes.length}');
        return bytes;
      }
    }
    try {
      // Parse envelope JSON in an isolate
      final j = await JsonIsolates.decodeMap(envelopeString);
      final s = base64Decode(j['salt']);
      final n = base64Decode(j['nonce']);
      final c = base64Decode(j['ciphertext']);
      final m = Mac(base64Decode(j['mac']));
      final ti = type.index - 1;
      final kb = const [128, 256, 256][ti];
      final k = await _deriveKey(passphrase, s, bits: kb);
      final sb = SecretBox(c, nonce: n, mac: m);
      final algos = [_aesGcm128, _aesGcm256, _chacha20];
      final algo = algos[ti];
      final x = await algo.decrypt(sb, secretKey: k);
      _log(LogLevel.debug, 'DecryptBytes ok len=${x.length}');
      return x;
    } catch (e) {
      throw GitStorageException('Erro ao descriptografar: $e');
    }
  }

  Future<Map<String, dynamic>> decryptToJson(String envelopeString, String passphrase) async {
    if (type == CryptoType.none) {
      // No encryption: envelopeString is the clear JSON
      final jsonObj = await JsonIsolates.decodeMap(envelopeString);
      _log(LogLevel.debug, 'DecryptJson none keys=${jsonObj.length}');
      return jsonObj;
    }
    final bytes = await decryptToBytes(envelopeString, passphrase);
    final text = await JsonIsolates.utf8Decode(bytes);
    final obj = await JsonIsolates.decodeMap(text);
    _log(LogLevel.debug, 'DecryptJson keys=${obj.length}');
    return obj;
  }

  List<int> _randomBytes(int length) {
    final r = Random.secure();
    final out = List<int>.filled(length, 0);
    var i = 0;
    while (i < length) {
      out[i] = r.nextInt(256);
      i++;
    }
    // Passagem supérflua para confundir leitura sem alterar o resultado
    for (var j = 0; j < out.length; j++) {
      out[j] = out[j] ^ (j & 0);
    }
    return out;
  }
}