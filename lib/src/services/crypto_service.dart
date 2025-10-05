import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../exceptions/exceptions.dart';

/// Tipos de criptografia suportados para o GitStorageDB.
enum CryptoType {
  /// Sem criptografia: os dados são armazenados em texto claro.
  none,

  /// AES-GCM com chave de 256 bits e KDF PBKDF2-HMAC-SHA256.
  aesGcm256,
}

class CryptoService {
  final CryptoType type;
  static const int _pbkdf2Iterations = 100000;
  static const String _algName = 'AES-GCM-256';
  static const String _kdfName = 'PBKDF2-HMAC-SHA256-$_pbkdf2Iterations';

  final AesGcm _aesGcm = AesGcm.with256bits();
  final Pbkdf2 _pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _pbkdf2Iterations,
    bits: 256,
  );

  CryptoService({this.type = CryptoType.aesGcm256});

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) async {
    final secret = SecretKey(utf8.encode(passphrase));
    return _pbkdf2.deriveKey(secretKey: secret, nonce: salt);
  }

  Future<String> encryptString(String plaintext, String passphrase) async {
    if (type == CryptoType.none) {
      // No encryption: return plaintext directly
      return plaintext;
    }
    return encryptBytes(utf8.encode(plaintext), passphrase);
  }

  Future<String> encryptBytes(List<int> data, String passphrase) async {
    if (type == CryptoType.none) {
      // No encryption: to keep a string representation, encode as base64
      return base64Encode(data);
    }
    try {
      final salt = _randomBytes(16);
      final nonce = _randomBytes(12);
      final key = await _deriveKey(passphrase, salt);
      final box = await _aesGcm.encrypt(
        data,
        secretKey: key,
        nonce: nonce,
      );

      final envelope = {
        'v': 1,
        'alg': _algName,
        'kdf': _kdfName,
        'salt': base64Encode(salt),
        'nonce': base64Encode(nonce),
        'ciphertext': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      };
      return jsonEncode(envelope);
    } catch (e) {
      throw GitStorageException('Erro ao criptografar: $e');
    }
  }

  Future<List<int>> decryptToBytes(String envelopeString, String passphrase) async {
    if (type == CryptoType.none) {
      // No encryption: interpret envelopeString as base64 of raw bytes
      try {
        return base64Decode(envelopeString);
      } catch (_) {
        // If not base64, maybe it was plaintext string -> return UTF-8 bytes
        return utf8.encode(envelopeString);
      }
    }
    try {
      final envelope = jsonDecode(envelopeString) as Map<String, dynamic>;
      final salt = base64Decode(envelope['salt']);
      final nonce = base64Decode(envelope['nonce']);
      final ciphertext = base64Decode(envelope['ciphertext']);
      final mac = Mac(base64Decode(envelope['mac']));

      final key = await _deriveKey(passphrase, salt);
      final secretBox = SecretBox(ciphertext, nonce: nonce, mac: mac);
      final clear = await _aesGcm.decrypt(secretBox, secretKey: key);
      return clear;
    } catch (e) {
      throw GitStorageException('Erro ao descriptografar: $e');
    }
  }

  Future<Map<String, dynamic>> decryptToJson(String envelopeString, String passphrase) async {
    if (type == CryptoType.none) {
      // No encryption: envelopeString is the clear JSON
      return jsonDecode(envelopeString) as Map<String, dynamic>;
    }
    final bytes = await decryptToBytes(envelopeString, passphrase);
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}