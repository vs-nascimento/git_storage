# Git Storage

[![Pub Version](https://img.shields.io/pub/v/git_storage?style=flat-square)](https://pub.dev/packages/git_storage)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)

A Flutter package for managing Git repositories and uploading files, returning the access URL.

## Overview

This package simplifies the process of uploading files to a GitHub repository, treating the repository as a file storage service. It is useful for scenarios where you need a quick and easy way to host files and get a shareable link.

## Features

-   **File Upload:** Upload files to your GitHub repository with a single method call.
-   **URL Return:** Receive the direct download URL of the file after upload.
-   **Conflict Handling:** Automatically renames files if they already exist in the repository.
-   **Simple to Use:** Clean and straightforward API for easy integration.

## Installation

Add this line to your `pubspec.yaml` file:

```yaml
dependencies:
  git_storage: ^0.1.0 # Check for the latest version on pub.dev
```

Then run `flutter pub get`.

## How to Use

### 1. Import the package

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

### 3. Upload a File

The `uploadFile` method takes a `File` object and the name of the file to be saved in the repository.

```dart
Future<void> upload(File myFile) async {
  try {
    // Create a unique name for the file
    final fileName = 'uploads/image_${DateTime.now().millisecondsSinceEpoch}.jpg';

    // Upload
    final gitFile = await client.uploadFile(myFile, fileName);

    // Use the returned URL
    print('File uploaded successfully!');
    print('Download URL: ${gitFile.downloadUrl}');
    print('API URL: ${gitFile.url}');

  } catch (e) {
    print('An error occurred: $e');
  }
}
```

## Example

You can find a complete implementation example in the [`/example`](/example) folder.

## Contributions

Contributions are welcome! If you find a bug or have a suggestion for improvement, feel free to open an [Issue](https://github.com/yourusername/git_storage/issues) or submit a [Pull Request](https://github.com/yourusername/git_storage/pulls).

## License

This package is licensed under the [MIT License](LICENSE).
