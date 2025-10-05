import '../git_storage_client.dart';
import 'crypto_service.dart';
import 'logging.dart';

/// Configuração única para instanciar o GitStorageDB.
class GitStorageDBConfig {
  /// Cliente já instanciado, opcional. Se não informado, será criado via [repoUrl] e [token].
  final GitStorageClient? client;

  /// URL do repositório GitHub, ex: https://github.com/user/repo.git
  final String? repoUrl;

  /// Token (PAT) do GitHub com permissão `repo`.
  final String? token;

  /// Branch alvo. Padrão `main`.
  final String branch;

  /// Caminho base para o banco. Padrão `db`.
  final String basePath;

  /// Senha/frase-secreta para derivação da chave de criptografia.
  /// Obrigatória quando [cryptoType] for diferente de [CryptoType.none].
  final String? passphrase;

  /// Tipo de criptografia a ser utilizado.
  final CryptoType cryptoType;

  /// Habilita logs no console (estilo Spring) para operações do DB.
  final bool enableLogs;

  /// Listener de logs para interceptar mensagens do DB/Client/Crypto.
  final LogListener? logListener;

  /// Nível de logs.
  final LogLevel logLevel;

  /// Concorrência máxima para leituras (download e descriptografia).
  /// Ajuda a acelerar `getAll` e consultas mantendo pressão razoável na API.
  final int readConcurrency;

  /// Iterações do PBKDF2 para derivação de chave.
  final int pbkdf2Iterations;

  GitStorageDBConfig({
    this.client,
    this.repoUrl,
    this.token,
    this.branch = 'main',
    this.basePath = 'db',
    this.passphrase,
    this.cryptoType = CryptoType.aesGcm256,
    this.enableLogs = false,
    this.readConcurrency = 6,
    this.logListener,
    this.logLevel = LogLevel.none,
    this.pbkdf2Iterations = 100000,
  }) {
    assert(
      client != null || (repoUrl != null && token != null),
      'Informe um client ou repoUrl+token',
    );
    if (cryptoType != CryptoType.none) {
      assert(passphrase != null && passphrase!.isNotEmpty,
          'Passphrase é obrigatória quando cryptoType != none');
    }
  }
}
