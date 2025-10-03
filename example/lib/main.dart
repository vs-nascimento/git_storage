import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:git_storage/git_storage.dart';

void main() {
  runApp(const GitHubStorageApp());
}

class GitHubStorageApp extends StatelessWidget {
  const GitHubStorageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Storage',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GitHubStoragePage(),
    );
  }
}

class GitHubStoragePage extends StatefulWidget {
  const GitHubStoragePage({super.key});

  @override
  State<GitHubStoragePage> createState() => _GitHubStoragePageState();
}

class _GitHubStoragePageState extends State<GitHubStoragePage> {
  bool _isLoading = false;
  String _statusMessage = 'Pronto para enviar arquivo';
  GitStorageFile? _lastUploadedFile;
  List<GitStorageFile> _folderFiles = [];

  final String _repoUrl = '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';
  final String _token = 'SEU_TOKEN_AQUI';
  final String _branch = 'main';

  late final GitStorageClient _gitClient;

  @override
  void initState() {
    super.initState();
    _gitClient = GitStorageClient(
      repoUrl: _repoUrl,
      token: _token,
      branch: _branch,
    );
    _loadFolderFiles();
  }

  Future<void> _loadFolderFiles([String path = "uploads"]) async {
    try {
      final files = await _gitClient.listFiles(path);
      setState(() => _folderFiles = files);
    } catch (e) {
      setState(() => _statusMessage = 'Erro ao listar arquivos: $e');
    }
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result == null) return;

    final file = File(result.files.single.path!);
    final fileName = 'uploads/${result.files.single.name}';

    setState(() {
      _isLoading = true;
      _statusMessage = 'Enviando arquivo...';
    });

    try {
      final uploaded = await _gitClient.uploadFile(file, fileName);
      setState(() {
        _lastUploadedFile = uploaded;
        _statusMessage = 'Arquivo enviado com sucesso!';
      });
      _loadFolderFiles(); // atualizar lista de arquivos
    } catch (e) {
      setState(() => _statusMessage = 'Erro ao enviar arquivo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildFileCard(GitStorageFile file) {
    return Card(
      child: ListTile(
        title: Text(file.path),
        subtitle: Text('Tamanho: ${file.formattedSize}'),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new),
          onPressed: () => _openFile(file.downloadUrl),
        ),
      ),
    );
  }

  void _openFile(String url) {
    // Aqui você pode abrir em WebView ou navegador externo
    print("Abrir arquivo em: $url");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GitHub Storage')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadFolderFiles(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Selecionar e enviar arquivo'),
                      onPressed: _pickAndUploadFile,
                    ),
                    const SizedBox(height: 16),
                    if (_lastUploadedFile != null) ...[
                      const Text(
                        'Último arquivo enviado:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SelectableText(_lastUploadedFile!.downloadUrl),
                      SelectableText(_lastUploadedFile!.path),
                      Image.network(_lastUploadedFile!.downloadUrl),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Arquivos na pasta "uploads":',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ..._folderFiles.map(_buildFileCard),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(_statusMessage),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
