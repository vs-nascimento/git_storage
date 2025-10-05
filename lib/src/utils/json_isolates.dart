import 'dart:convert';
import 'package:flutter/foundation.dart';

/// JSON and UTF-8 helpers that offload heavy work to isolates.
/// These are useful for large payloads to keep the UI thread responsive.
String _jsonEncodeFn(dynamic value) => jsonEncode(value);
dynamic _jsonDecodeFn(String source) => jsonDecode(source);
String _utf8DecodeFn(List<int> bytes) => utf8.decode(bytes);
List<int> _utf8EncodeFn(String text) => utf8.encode(text);

class JsonIsolates {
  /// Encode any Dart object to a JSON string using Flutter compute.
  static Future<String> encode(dynamic value) {
    return compute(_jsonEncodeFn, value);
  }

  /// Decode a JSON string to a dynamic object using Flutter compute.
  static Future<dynamic> decode(String source) {
    return compute(_jsonDecodeFn, source);
  }

  /// Decode a JSON string to Map<String, dynamic> using compute.
  static Future<Map<String, dynamic>> decodeMap(String source) async {
    final v = await decode(source);
    return v as Map<String, dynamic>;
  }

  /// Decode a JSON string to List<dynamic> using compute.
  static Future<List<dynamic>> decodeList(String source) async {
    final v = await decode(source);
    return v as List<dynamic>;
  }

  /// UTF-8 decode using compute.
  static Future<String> utf8Decode(List<int> bytes) {
    return compute(_utf8DecodeFn, bytes);
  }

  /// UTF-8 encode using compute.
  static Future<List<int>> utf8Encode(String text) {
    return compute(_utf8EncodeFn, text);
  }
}