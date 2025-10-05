import 'dart:math';

/// Estratégias de geração de ID para documentos.
enum IdStrategy {
  /// ID fornecido manualmente pelo usuário.
  manual,

  /// UUID versão 4 (aleatório, RFC 4122).
  uuidV4,

  /// Timestamp em milissegundos desde epoch.
  timestampMs,
}

/// Utilitário para gerar IDs conforme a [IdStrategy].
class IdGenerator {
  static final Random _rand = Random.secure();

  /// Gera um ID baseado na [strategy].
  /// Para [IdStrategy.manual], é obrigatório informar [manualId].
  static String generate(IdStrategy strategy, {String? manualId}) {
    switch (strategy) {
      case IdStrategy.manual:
        if (manualId == null || manualId.isEmpty) {
          throw ArgumentError('manualId é obrigatório quando strategy=manual');
        }
        return manualId;
      case IdStrategy.uuidV4:
        return _uuidV4();
      case IdStrategy.timestampMs:
        return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  static String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => _rand.nextInt(256));

    // Ajusta versão e variante (RFC 4122 v4)
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // versão 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variante 10xxxxxx

    String _hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final b = bytes.map(_hex).toList();
    return '${b[0]}${b[1]}${b[2]}${b[3]}-${b[4]}${b[5]}-${b[6]}${b[7]}-${b[8]}${b[9]}-${b[10]}${b[11]}${b[12]}${b[13]}${b[14]}${b[15]}';
  }
}