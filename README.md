# Git Storage

[![Pub Version](https://img.shields.io/pub/v/git_storage?style=flat-square)](https://pub.dev/packages/git_storage)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)

Um pacote Flutter para gerenciar repositórios Git e fazer upload de arquivos, retornando a URL de acesso.

## Visão Geral

Este pacote simplifica o processo de upload de arquivos para um repositório GitHub, tratando o repositório como um serviço de armazenamento de arquivos. Ele é útil para cenários onde você precisa de uma forma rápida e fácil de hospedar arquivos e obter um link compartilhável.

## Funcionalidades

-   **Upload de Arquivos:** Envie arquivos para o seu repositório GitHub com uma única chamada de método.
-   **Retorno de URL:** Receba a URL de download direto do arquivo após o upload.
-   **Tratamento de Conflitos:** Renomeia arquivos automaticamente se já existirem no repositório.
-   **Simples de Usar:** API limpa e direta para facilitar a integração.

## Instalação

Adicione esta linha ao seu arquivo `pubspec.yaml`:

```yaml
dependencies:
  git_storage: ^0.1.0 # Verifique a versão mais recente em pub.dev
```

Em seguida, execute `flutter pub get`.

## Como Usar

### 1. Importe o pacote

```dart
import 'package:git_storage/git_storage.dart';
import 'dart:io';
```

### 2. Inicialize o Cliente

Para usar o `GitStorageClient`, você precisa de um [Token de Acesso Pessoal (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) do GitHub com permissões de `repo`.

```dart
final client = GitStorageClient(
  repoUrl: 'https://github.com/seu-usuario/seu-repositorio.git',
  token: 'SEU_GITHUB_PAT',
  branch: 'main', // Opcional, o padrão é 'main'
);
```

### 3. Faça o Upload de um Arquivo

O método `uploadFile` recebe um objeto `File` e o nome do arquivo a ser salvo no repositório.

```dart
Future<void> upload(File myFile) async {
  try {
    // Crie um nome único para o arquivo
    final fileName = 'uploads/imagem_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Faça o upload
    final gitFile = await client.uploadFile(myFile, fileName);

    // Use a URL retornada
    print('Arquivo enviado com sucesso!');
    print('URL de Download: ${gitFile.downloadUrl}');
    print('URL da API: ${gitFile.url}');

  } catch (e) {
    print('Ocorreu um erro: $e');
  }
}
```

## Exemplo

Você pode encontrar um exemplo completo de implementação na pasta [`/example`](/example).

## Contribuições

Contribuições são bem-vindas! Se você encontrar um bug ou tiver uma sugestão de melhoria, sinta-se à vontade para abrir uma [Issue](https://github.com/yourusername/git_storage/issues) ou enviar um [Pull Request](https://github.com/yourusername/git_storage/pulls).

## Licença

Este pacote está licenciado sob a [Licença MIT](LICENSE).