import '../utils/format_file_size.dart';

/// Represents a file or directory in a Git repository.
class GitStorageFile {
  /// The name of the file or directory.
  final String name;

  /// The path of the file or directory.
  final String path;

  /// The SHA hash of the file or directory.
  final String sha;

  /// The size of the file in bytes.
  final int size;

  /// The API URL of the file or directory.
  final String url;

  /// The HTML URL of the file or directory.
  final String htmlUrl;

  /// The Git URL of the file or directory.
  final String gitUrl;

  /// The download URL of the file.
  final String downloadUrl;

  /// The type of the content (`file` or `dir`).
  final String type;

  /// Creates a new [GitStorageFile] instance.
  GitStorageFile({
    required this.name,
    required this.path,
    required this.sha,
    required this.size,
    required this.url,
    required this.htmlUrl,
    required this.gitUrl,
    required this.downloadUrl,
    required this.type,
  });

  /// Creates a new [GitStorageFile] instance from a JSON object.
  factory GitStorageFile.fromJson(Map<String, dynamic> json) {
    return GitStorageFile(
      name: json['name'],
      path: json['path'],
      sha: json['sha'],
      size: json['size'],
      url: json['url'],
      htmlUrl: json['html_url'],
      gitUrl: json['git_url'],
      downloadUrl: json['download_url'] ?? '',
      type: json['type'],
    );
  }

  /// Returns the file size in a human-readable format.
  String get formattedSize => formatFileSize(size);
}
