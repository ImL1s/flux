import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;

/// Interface for caching Flux updates.
abstract class FluxCacheManager {
  /// Save a chunk to cache.
  Future<void> saveChunk(String appId, String version, Uint8List chunk);

  /// Load a chunk from cache.
  Future<Uint8List?> loadChunk(String appId, String version);

  /// Save version state (JSON string).
  Future<void> saveVersionState(String state);

  /// Load version state (JSON string).
  Future<String?> loadVersionState();
}

/// File-based implementation of FluxCacheManager.
class FileCacheManager implements FluxCacheManager {
  final String rootPath;

  FileCacheManager(this.rootPath);

  Directory get _chunksDir => Directory(p.join(rootPath, 'chunks'));
  File get _versionStateFile => File(p.join(rootPath, 'version_state.json'));

  @override
  Future<void> saveChunk(String appId, String version, Uint8List chunk) async {
    final file = File(p.join(_chunksDir.path, appId, '$version.flx'));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(chunk);
  }

  @override
  Future<Uint8List?> loadChunk(String appId, String version) async {
    final file = File(p.join(_chunksDir.path, appId, '$version.flx'));
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  }

  @override
  Future<void> saveVersionState(String state) async {
    await _versionStateFile.parent.create(recursive: true);
    await _versionStateFile.writeAsString(state);
  }

  @override
  Future<String?> loadVersionState() async {
    if (!await _versionStateFile.exists()) return null;
    return await _versionStateFile.readAsString();
  }
}
