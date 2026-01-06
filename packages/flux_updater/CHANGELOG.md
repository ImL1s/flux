# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-06

### Added

- **FluxUpdateManager** - Main client for checking and applying OTA updates
- **OTA Server** - Shelf-based REST API server for release management
  - `POST /releases` - Upload new release
  - `GET /releases/:appId/latest` - Get latest version info
  - `GET /patches/:appId/:from/:to` - Download incremental patch
  - `GET /chunks/:appId/:version` - Download full bytecode chunk
- **Bytecode Diffing** - XOR + GZip compression for efficient patch delivery (~5-10% of full size)
- **Version Control** - Semantic versioning with rollback support
- **Code Signing** - HMAC-SHA256 signature generation and verification
- **CLI Tools**
  - `flux_updater compile` - Compile Flux source to bytecode
  - `flux_updater release` - Create signed release package
  - `flux_updater push` - Upload release to OTA server
  - `flux_updater info` - Display bytecode file information
- **ChunkSerializer** - Binary serialization/deserialization for bytecode chunks
- **DiffManager** - Efficient binary diff generation and application
- **VersionManager** - Local version tracking and rollback management
- **SignatureUtils** - Cryptographic utilities for code signing

### Security

- HMAC-SHA256 signature verification for all releases
- Integrity checks on downloaded patches and chunks
- Secure key management utilities

### Documentation

- Complete API reference
- Quick start guide
- App Store compliance guidelines (iOS/Android)
- Architecture overview
