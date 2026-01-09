import 'dart:io';
import 'dart:convert';
import 'package:flux_vm/flux_vm.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// File I/O module for Flux
///
/// Provides local file system access with sandboxed paths.
/// All operations are restricted to the app's document directory for security.
///
/// Usage in Flux:
/// ```flux
/// // Get available directories
/// var docDir = await file.getDocumentsDirectory();
/// var tempDir = await file.getTempDirectory();
///
/// // Write text file
/// await file.writeText("notes.txt", "Hello World!");
///
/// // Read text file
/// var content = await file.readText("notes.txt");
///
/// // Write JSON
/// await file.writeJson("config.json", {theme: "dark", fontSize: 16});
///
/// // Read JSON
/// var config = await file.readJson("config.json");
///
/// // Check if file exists
/// var exists = await file.exists("notes.txt");
///
/// // Delete file
/// await file.delete("notes.txt");
///
/// // List files in directory
/// var files = await file.list("subfolder");
/// ```
class FileModule extends FluxModule {
  FileModule() : super('file') {
    _registerFunctions();
  }

  void _registerFunctions() {
    // Directory access
    register(
        'getDocumentsDirectory',
        AsyncNativeFunction(
            'file.getDocumentsDirectory', 0, _getDocumentsDirectory));
    register('getTempDirectory',
        AsyncNativeFunction('file.getTempDirectory', 0, _getTempDirectory));
    register('getCacheDirectory',
        AsyncNativeFunction('file.getCacheDirectory', 0, _getCacheDirectory));

    // File operations
    register('readText', AsyncNativeFunction('file.readText', 1, _readText));
    register('writeText', AsyncNativeFunction('file.writeText', 2, _writeText));
    register('readJson', AsyncNativeFunction('file.readJson', 1, _readJson));
    register('writeJson', AsyncNativeFunction('file.writeJson', 2, _writeJson));
    register('readBytes', AsyncNativeFunction('file.readBytes', 1, _readBytes));
    register(
        'writeBytes', AsyncNativeFunction('file.writeBytes', 2, _writeBytes));
    register('append', AsyncNativeFunction('file.append', 2, _append));

    // File management
    register('exists', AsyncNativeFunction('file.exists', 1, _exists));
    register('delete', AsyncNativeFunction('file.delete', 1, _delete));
    register('copy', AsyncNativeFunction('file.copy', 2, _copy));
    register('move', AsyncNativeFunction('file.move', 2, _move));
    register('rename', AsyncNativeFunction('file.rename', 2, _rename));

    // Directory operations
    register('list', AsyncNativeFunction('file.list', 1, _list));
    register('createDirectory',
        AsyncNativeFunction('file.createDirectory', 1, _createDirectory));
    register('deleteDirectory',
        AsyncNativeFunction('file.deleteDirectory', 1, _deleteDirectory));

    // File info
    register('getInfo', AsyncNativeFunction('file.getInfo', 1, _getInfo));
  }

  // ==================== Directory Access ====================

  Future<Object?> _getDocumentsDirectory(List<Object?> args) async {
    final dir = await getApplicationDocumentsDirectory();
    return dir.path;
  }

  Future<Object?> _getTempDirectory(List<Object?> args) async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  Future<Object?> _getCacheDirectory(List<Object?> args) async {
    final dir = await getApplicationCacheDirectory();
    return dir.path;
  }

  // ==================== File Operations ====================

  /// Read text content from a file
  Future<Object?> _readText(List<Object?> args) async {
    final relativePath = args[0] as String;
    final file = await _resolveFile(relativePath);

    if (!await file.exists()) {
      return {'error': true, 'message': 'File not found: $relativePath'};
    }

    try {
      return await file.readAsString();
    } catch (e) {
      return {'error': true, 'message': 'Failed to read file: $e'};
    }
  }

  /// Write text content to a file
  Future<Object?> _writeText(List<Object?> args) async {
    final relativePath = args[0] as String;
    final content = args[1]?.toString() ?? '';
    final file = await _resolveFile(relativePath);

    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      return {'success': true, 'path': file.path};
    } catch (e) {
      return {'error': true, 'message': 'Failed to write file: $e'};
    }
  }

  /// Read JSON from a file
  Future<Object?> _readJson(List<Object?> args) async {
    final relativePath = args[0] as String;
    final file = await _resolveFile(relativePath);

    if (!await file.exists()) {
      return {'error': true, 'message': 'File not found: $relativePath'};
    }

    try {
      final content = await file.readAsString();
      return jsonDecode(content);
    } catch (e) {
      return {'error': true, 'message': 'Failed to read JSON: $e'};
    }
  }

  /// Write JSON to a file
  Future<Object?> _writeJson(List<Object?> args) async {
    final relativePath = args[0] as String;
    final data = args[1];
    final file = await _resolveFile(relativePath);

    try {
      await file.parent.create(recursive: true);
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      await file.writeAsString(jsonString);
      return {'success': true, 'path': file.path};
    } catch (e) {
      return {'error': true, 'message': 'Failed to write JSON: $e'};
    }
  }

  /// Read bytes from a file
  Future<Object?> _readBytes(List<Object?> args) async {
    final relativePath = args[0] as String;
    final file = await _resolveFile(relativePath);

    if (!await file.exists()) {
      return {'error': true, 'message': 'File not found: $relativePath'};
    }

    try {
      final bytes = await file.readAsBytes();
      return bytes.toList();
    } catch (e) {
      return {'error': true, 'message': 'Failed to read bytes: $e'};
    }
  }

  /// Write bytes to a file
  Future<Object?> _writeBytes(List<Object?> args) async {
    final relativePath = args[0] as String;
    final data = args[1];
    final file = await _resolveFile(relativePath);

    try {
      await file.parent.create(recursive: true);

      List<int> bytes;
      if (data is List<int>) {
        bytes = data;
      } else if (data is List) {
        bytes = data.map((e) => (e as num).toInt()).toList();
      } else {
        return {'error': true, 'message': 'Invalid byte data'};
      }

      await file.writeAsBytes(bytes);
      return {'success': true, 'path': file.path};
    } catch (e) {
      return {'error': true, 'message': 'Failed to write bytes: $e'};
    }
  }

  /// Append text to a file
  Future<Object?> _append(List<Object?> args) async {
    final relativePath = args[0] as String;
    final content = args[1]?.toString() ?? '';
    final file = await _resolveFile(relativePath);

    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(content, mode: FileMode.append);
      return {'success': true, 'path': file.path};
    } catch (e) {
      return {'error': true, 'message': 'Failed to append: $e'};
    }
  }

  // ==================== File Management ====================

  /// Check if a file exists
  Future<Object?> _exists(List<Object?> args) async {
    final relativePath = args[0] as String;
    final file = await _resolveFile(relativePath);
    return await file.exists();
  }

  /// Delete a file
  Future<Object?> _delete(List<Object?> args) async {
    final relativePath = args[0] as String;
    final file = await _resolveFile(relativePath);

    if (!await file.exists()) {
      return {'error': true, 'message': 'File not found: $relativePath'};
    }

    try {
      await file.delete();
      return {'success': true};
    } catch (e) {
      return {'error': true, 'message': 'Failed to delete: $e'};
    }
  }

  /// Copy a file to a new location
  Future<Object?> _copy(List<Object?> args) async {
    final sourcePath = args[0] as String;
    final destPath = args[1] as String;
    final sourceFile = await _resolveFile(sourcePath);
    final destFile = await _resolveFile(destPath);

    if (!await sourceFile.exists()) {
      return {'error': true, 'message': 'Source file not found: $sourcePath'};
    }

    try {
      await destFile.parent.create(recursive: true);
      await sourceFile.copy(destFile.path);
      return {'success': true, 'path': destFile.path};
    } catch (e) {
      return {'error': true, 'message': 'Failed to copy: $e'};
    }
  }

  /// Move a file to a new location
  Future<Object?> _move(List<Object?> args) async {
    final sourcePath = args[0] as String;
    final destPath = args[1] as String;
    final sourceFile = await _resolveFile(sourcePath);
    final destFile = await _resolveFile(destPath);

    if (!await sourceFile.exists()) {
      return {'error': true, 'message': 'Source file not found: $sourcePath'};
    }

    try {
      await destFile.parent.create(recursive: true);
      await sourceFile.rename(destFile.path);
      return {'success': true, 'path': destFile.path};
    } catch (e) {
      return {'error': true, 'message': 'Failed to move: $e'};
    }
  }

  /// Rename a file
  Future<Object?> _rename(List<Object?> args) async {
    return _move(args);
  }

  // ==================== Directory Operations ====================

  /// List files in a directory
  Future<Object?> _list(List<Object?> args) async {
    final relativePath = args.isNotEmpty ? args[0] as String? ?? '' : '';
    final dir = await _resolveDirectory(relativePath);

    if (!await dir.exists()) {
      return {'error': true, 'message': 'Directory not found: $relativePath'};
    }

    try {
      final entities = await dir.list().toList();
      return entities.map((e) {
        final isDir = e is Directory;
        return {
          'name': p.basename(e.path),
          'path': e.path,
          'isDirectory': isDir,
        };
      }).toList();
    } catch (e) {
      return {'error': true, 'message': 'Failed to list directory: $e'};
    }
  }

  /// Create a directory
  Future<Object?> _createDirectory(List<Object?> args) async {
    final relativePath = args[0] as String;
    final dir = await _resolveDirectory(relativePath);

    try {
      await dir.create(recursive: true);
      return {'success': true, 'path': dir.path};
    } catch (e) {
      return {'error': true, 'message': 'Failed to create directory: $e'};
    }
  }

  /// Delete a directory
  Future<Object?> _deleteDirectory(List<Object?> args) async {
    final relativePath = args[0] as String;
    final dir = await _resolveDirectory(relativePath);

    if (!await dir.exists()) {
      return {'error': true, 'message': 'Directory not found: $relativePath'};
    }

    try {
      await dir.delete(recursive: true);
      return {'success': true};
    } catch (e) {
      return {'error': true, 'message': 'Failed to delete directory: $e'};
    }
  }

  // ==================== File Info ====================

  /// Get file information
  Future<Object?> _getInfo(List<Object?> args) async {
    final relativePath = args[0] as String;
    final file = await _resolveFile(relativePath);

    if (!await file.exists()) {
      return {'error': true, 'message': 'File not found: $relativePath'};
    }

    try {
      final stat = await file.stat();
      return {
        'path': file.path,
        'name': p.basename(file.path),
        'size': stat.size,
        'modified': stat.modified.toIso8601String(),
        'accessed': stat.accessed.toIso8601String(),
        'isFile': stat.type == FileSystemEntityType.file,
        'isDirectory': stat.type == FileSystemEntityType.directory,
      };
    } catch (e) {
      return {'error': true, 'message': 'Failed to get file info: $e'};
    }
  }

  // ==================== Helpers ====================

  /// Resolve a relative path to an absolute File within the documents directory
  Future<File> _resolveFile(String relativePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    // Sanitize path to prevent directory traversal attacks
    final sanitized = p.normalize(relativePath).replaceAll('..', '');
    return File(p.join(docsDir.path, 'flux_files', sanitized));
  }

  /// Resolve a relative path to an absolute Directory within the documents directory
  Future<Directory> _resolveDirectory(String relativePath) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final sanitized = p.normalize(relativePath).replaceAll('..', '');
    return Directory(p.join(docsDir.path, 'flux_files', sanitized));
  }
}
