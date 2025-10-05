# Changelog

All notable changes to this project will be documented in this file.

## 2.1.0
- Performance: Offload JSON encode/decode and UTF-8 conversions to isolates.
- Client: Parse `getFile`, `listFiles`, and `getBytes` JSON responses in isolates.
- DB: Use isolates for document encode (`put`) and bulk reads (`getAll`).
- Crypto: Use isolates for envelope JSON creation and plaintext UTF-8 conversions.
- Docs: README updated in English with performance notes and tips.
- Web/WASM: Package not compatible with Web/WASM runtime yet; see https://dart.dev/web/wasm.

## 2.0.0
- Breaking: `GitStorageDB.put`, `add`, and `update` now use named parameters.
  - `put({ required String collection, required String id, required Map<String, dynamic> json, Map<String, Type>? schema, String? message })`
  - `add({ required String collection, required Map<String, dynamic> json, IdStrategy strategy = IdStrategy.uuidV4, String? manualId, Map<String, Type>? schema, String? message })`
  - `update({ required String collection, required String id, required Map<String, dynamic> Function(Map<String, dynamic>) updater, Map<String, Type>? schema, String? message })`
- Breaking: Removed contract extension methods (`putWithContract`, `addWithContract`, `updateWithContract`). Use the integrated optional `schema` named parameter instead.
- New: Integrated schema validation for keys/types via an optional `schema` parameter on `put` and `update`. Supports nested paths (e.g., `profile.email`).
- Crypto: fixed key derivation per algorithm (AES-GCM-128, AES-GCM-256 and ChaCha20-Poly1305 now use appropriate key sizes).
- Performance: `getAll` and `QueryBuilder.get()` use bounded parallel reads and, when available, `download_url` to reduce API calls.
- Client API: added `getBytesFromUrl(url)` for direct byte reads via URL.
- Logging: improved messages and configurability via `GitStorageDBConfig`.
- Docs: README updated with named parameter examples, `download_url` usage, migrations and performance tips.

## 1.0.0
- API marked as stable; no breaking changes in this release.
- Added console examples under `example/lib/`: `main_seed.dart`, `main_assign_filters.dart`, and `main_queries.dart`.
- Documentation improvements (README and examples), including guidance to avoid branch conflicts (HTTP 409) and using `GitStorageTransaction` where appropriate.
- Increased reliability in collection cleanup operations (`dropCollection`) by serializing commits to avoid conflicts.
- Minor fixes and logging improvements.

## 0.4.0
- Added content editing APIs: `putBytes`, `putString`, `updateFile`, `getBytes`, `getString`.
- Added `GitStorageDB` for encrypted or plain JSON documents stored in the repository.
- Introduced `CryptoService` using AES-GCM 256 and PBKDF2-HMAC-SHA256.
- Improved robustness when reading bytes by falling back to the contents API.
- Added `GitStorageDB.fromConfig` with `GitStorageDBConfig` for a single configuration entry point.
- Added `QueryBuilder`, `DBFilter` and query support; added `GitStorageTransaction`.
- Added basic migrations support with `Migration` model and `runMigrations`.

## 0.3.0
- Added `deleteFile` method to remove files from the repository.

## 0.2.1
- Fixed a bug in the `uploadFile` method that caused incorrect URL returns in certain scenarios.

## 0.2.0
- Added `createFolder`, `listFiles`, and `getFile` methods.
- Improved code documentation and comments.
- Translated messages and comments to English.
- Refactored for better readability and maintainability.

## 0.1.0
- Initial release of the package.
- Includes features for file upload, URL return, and conflict handling.
