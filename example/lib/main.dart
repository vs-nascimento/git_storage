import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:git_storage/git_storage.dart';

void main() {
  runApp(const GitApiExampleApp());
}

class GitApiExampleApp extends StatelessWidget {
  const GitApiExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GitHub Storage Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const GitApiExample(),
    );
  }
}

class GitApiExample extends StatefulWidget {
  const GitApiExample({super.key});

  @override
  State<GitApiExample> createState() => _GitApiExampleState();
}

class _GitApiExampleState extends State<GitApiExample> {
  // UI state
  bool _isLoading = false;
  String _statusMessage = 'Pronto para enviar o arquivo';
  GitStorageFile? _lastUploadedFile;

  // GitHub repository configuration
  final String _repoUrl = 'https://github.com/vs-nascimento/test_assets.git';
  final String _token = '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';
  final String _branch = 'main';

  late final GitStorageClient _gitStorageClient;

  @override
  void initState() {
    super.initState();
    _gitStorageClient = GitStorageClient(
      repoUrl: _repoUrl,
      token: _token,
      branch: _branch,
    );
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result == null) return;

      setState(() {
        _isLoading = true;
        _statusMessage = 'Enviando arquivo para GitHub...';
      });

      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      final uploadedFile = await _gitStorageClient.uploadFile(file, fileName);

      setState(() {
        _lastUploadedFile = uploadedFile;
        _statusMessage = 'Arquivo enviado com sucesso!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao enviar arquivo: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GitHub Storage Example')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Upload
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Upload de Arquivo',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickAndUploadFile,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Selecionar e Enviar Arquivo'),
                          ),
                          if (_lastUploadedFile != null) ...[
                            const SizedBox(height: 16),
                            const Text('Último arquivo enviado:'),
                            SelectableText(
                              _lastUploadedFile!.downloadUrl,
                              style: const TextStyle(color: Colors.blue),
                            ),
                            Image.network(_lastUploadedFile!.downloadUrl),
                            const SizedBox(height: 8),
                            Text(
                                'Tamanho: ${_lastUploadedFile!.formattedSize}'),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_statusMessage),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
