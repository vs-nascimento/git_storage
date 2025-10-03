import '../utils/format_file_size.dart';

class GitStorageFile {
  final String name;
  final String path;
  final String sha;
  final int size;
  final String url;
  final String htmlUrl;
  final String gitUrl;
  final String downloadUrl;
  final String type;

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

  factory GitStorageFile.fromJson(Map<String, dynamic> json) {
    return GitStorageFile(
      name: json['name'],
      path: json['path'],
      sha: json['sha'],
      size: json['size'],
      url: json['url'],
      htmlUrl: json['html_url'],
      gitUrl: json['git_url'],
      downloadUrl: json['download_url'],
      type: json['type'],
    );
  }

  String get formattedSize => formatFileSize(size);
}
