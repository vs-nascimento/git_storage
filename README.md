# Git Storage

[![Pub Version](https://img.shields.io/pub/v/git_storage?style=flat-square)](https://pub.dev/packages/git_storage)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)

A Flutter package for using GitHub repositories as a simple file storage service.

## Overview

This package provides a convenient way to interact with GitHub repositories for file management. You can upload, download, and list files, as well as create folders, making it easy to use a repository as a lightweight file backend for your applications.

## Features

-   **Upload Files:** Upload files to your GitHub repository.
-   **Get Download URLs:** Automatically receive the direct download URL for your files.
-   **Conflict Handling:** Automatically renames files if a file with the same name already exists.
-   **List Files and Folders:** List the contents of a directory.
-   **Create Folders:** Create "folders" by adding a `.gitkeep` file.
-   **Simple and Clean API:** Easy-to-use and straightforward integration.

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  git_storage: ^0.3.0 # Check for the latest version
```

Then, run `flutter pub get`.

## How to Use

### 1. Import the Package

```dart
import 'package:git_storage/git_storage.dart';
import 'dart:io';
```

### 2. Initialize the Client

To use `GitStorageClient`, you need a GitHub [Personal Access Token (PAT)](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) with `repo` permissions.

```dart
final client = GitStorageClient(
  repoUrl: 'https://github.com/your-user/your-repository.git',
  token: 'YOUR_GITHUB_PAT',
  branch: 'main', // Optional, defaults to 'main'
);
```

### 3. API Reference

#### Upload a File

The `uploadFile` method takes a `File` object and the desired path in the repository.

```dart
Future<void> upload(File myFile) async {
  try {
    final path = 'uploads/image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final gitFile = await client.uploadFile(myFile, path);

    print('File uploaded successfully!');
    print('Download URL: ${gitFile.downloadUrl}');
  } catch (e) {
    print('An error occurred: $e');
  }
}
```

#### List Files in a Directory

The `listFiles` method returns a list of `GitStorageFile` objects in a given path.

```dart
Future<void> list(String path) async {
  try {
    final files = await client.listFiles(path);
    for (final file in files) {
      print('File: ${file.name}, Size: ${file.formattedSize}');
    }
  } catch (e) {
    print('An error occurred: $e');
  }
}
```

#### Get a Specific File

The `getFile` method retrieves information about a single file.

```dart
Future<void> get(String path) async {
  try {
    final file = await client.getFile(path);
    print('File found: ${file.name}');
  } catch (e) {
    print('An error occurred: $e');
  }
}
```

#### Create a Folder

The `createFolder` method creates a new directory by adding a `.gitkeep` file.

```dart
Future<void> createDirectory(String path) async {
  try {
    await client.createFolder(path);
    print('Folder created successfully!');
  } catch (e) {
    print('An error occurred: $e');
  }
}
```

#### Delete a File
The `deleteFile` method removes a file from the repository.

```dart
Future<void> delete(String path) async {
  try {
    await client.deleteFile(path);
    print('File deleted successfully!');
  } catch (e) {
    print('An error occurred: $e');
  }
}
```


## Example

A complete example is available in the [`/example`](/example) directory.

## Contributions

Contributions are welcome! If you find a bug or have a suggestion, please open an [Issue](https://github.com/yourusername/git_storage/issues) or submit a [Pull Request](https://github.com/yourusername/git_storage/pulls).

## License

This package is licensed under the [MIT License](LICENSE).
