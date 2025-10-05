import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../exceptions/exceptions.dart';
import 'logging.dart';

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
    return encryptBytes(utf8.encode(plaintext), passphrase);
  }

  Future<String> encryptBytes(List<int> data, String passphrase) async {
    if (type == CryptoType.none) {
      // No encryption: to keep a string representation, encode as base64
      _log(LogLevel.debug, 'EncryptBytes none -> base64 length=${data.length}');
      return base64Encode(data);
    }
    try {
      final salt = _randomBytes(16);
      final nonce = _randomBytes(12);
      // Seleciona tamanho de chave por algoritmo
      final keyBits = switch (type) {
        CryptoType.aesGcm128 => 128,
        CryptoType.aesGcm256 => 256,
        CryptoType.chacha20Poly1305 => 256,
        CryptoType.none => 0,
      };
      final key = await _deriveKey(passphrase, salt, bits: keyBits);
      SecretBox box;
      String algName;
      switch (type) {
        case CryptoType.aesGcm128:
          box = await _aesGcm128.encrypt(data, secretKey: key, nonce: nonce);
          algName = 'AES-GCM-128';
          break;
        case CryptoType.aesGcm256:
          box = await _aesGcm256.encrypt(data, secretKey: key, nonce: nonce);
          algName = 'AES-GCM-256';
          break;
        case CryptoType.chacha20Poly1305:
          box = await _chacha20.encrypt(data, secretKey: key, nonce: nonce);
          algName = 'ChaCha20-Poly1305';
          break;
        case CryptoType.none:
          // already handled above
          throw StateError('Unreachable');
      }

      final envelope = {
        'v': 1,
        'alg': algName,
        'kdf': 'PBKDF2-HMAC-SHA256-$pbkdf2Iterations',
        'salt': base64Encode(salt),
        'nonce': base64Encode(nonce),
        'ciphertext': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      };
      _log(LogLevel.debug, 'EncryptBytes $algName ok len=${data.length}');
      return jsonEncode(envelope);
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
        final bytes = utf8.encode(envelopeString);
        _log(LogLevel.debug, 'DecryptBytes none plaintext -> len=${bytes.length}');
        return bytes;
      }
    }
    try {
      final envelope = jsonDecode(envelopeString) as Map<String, dynamic>;
      final salt = base64Decode(envelope['salt']);
      final nonce = base64Decode(envelope['nonce']);
      final ciphertext = base64Decode(envelope['ciphertext']);
      final mac = Mac(base64Decode(envelope['mac']));

      final keyBits = switch (type) {
        CryptoType.aesGcm128 => 128,
        CryptoType.aesGcm256 => 256,
        CryptoType.chacha20Poly1305 => 256,
        CryptoType.none => 0,
      };
      final key = await _deriveKey(passphrase, salt, bits: keyBits);
      final secretBox = SecretBox(ciphertext, nonce: nonce, mac: mac);
      List<int> clear;
      switch (type) {
        case CryptoType.aesGcm128:
          clear = await _aesGcm128.decrypt(secretBox, secretKey: key);
          break;
        case CryptoType.aesGcm256:
          clear = await _aesGcm256.decrypt(secretBox, secretKey: key);
          break;
        case CryptoType.chacha20Poly1305:
          clear = await _chacha20.decrypt(secretBox, secretKey: key);
          break;
        case CryptoType.none:
          throw StateError('Unreachable');
      }
      _log(LogLevel.debug, 'DecryptBytes ok len=${clear.length}');
      return clear;
    } catch (e) {
      throw GitStorageException('Erro ao descriptografar: $e');
    }
  }

  Future<Map<String, dynamic>> decryptToJson(String envelopeString, String passphrase) async {
    if (type == CryptoType.none) {
      // No encryption: envelopeString is the clear JSON
      final jsonObj = jsonDecode(envelopeString) as Map<String, dynamic>;
      _log(LogLevel.debug, 'DecryptJson none keys=${jsonObj.length}');
      return jsonObj;
    }
    final bytes = await decryptToBytes(envelopeString, passphrase);
    final obj = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    _log(LogLevel.debug, 'DecryptJson keys=${obj.length}');
    return obj;
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}