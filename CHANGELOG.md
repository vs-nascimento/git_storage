# Changelog

All notable changes to this project will be documented in this file.

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
