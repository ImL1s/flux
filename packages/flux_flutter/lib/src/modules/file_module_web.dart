import 'package:flux_vm/flux_vm.dart';

/// File I/O module for Flux (Web Stub)
///
/// Local file system access is not supported on Web.
class FileModule extends FluxModule {
  FileModule() : super('file') {
    _registerFunctions();
  }

  void _registerFunctions() {
    // Directory access
    register('getDocumentsDirectory', AsyncNativeFunction('file.getDocumentsDirectory', 0, _notSupported));
    register('getTempDirectory', AsyncNativeFunction('file.getTempDirectory', 0, _notSupported));
    register('getCacheDirectory', AsyncNativeFunction('file.getCacheDirectory', 0, _notSupported));

    // File operations
    register('readText', AsyncNativeFunction('file.readText', 1, _notSupported));
    register('writeText', AsyncNativeFunction('file.writeText', 2, _notSupported));
    register('readJson', AsyncNativeFunction('file.readJson', 1, _notSupported));
    register('writeJson', AsyncNativeFunction('file.writeJson', 2, _notSupported));
    register('readBytes', AsyncNativeFunction('file.readBytes', 1, _notSupported));
    register('writeBytes', AsyncNativeFunction('file.writeBytes', 2, _notSupported));
    register('append', AsyncNativeFunction('file.append', 2, _notSupported));

    // File management
    register('exists', AsyncNativeFunction('file.exists', 1, _notSupported));
    register('delete', AsyncNativeFunction('file.delete', 1, _notSupported));
    register('copy', AsyncNativeFunction('file.copy', 2, _notSupported));
    register('move', AsyncNativeFunction('file.move', 2, _notSupported));
    register('rename', AsyncNativeFunction('file.rename', 2, _notSupported));

    // Directory operations
    register('list', AsyncNativeFunction('file.list', 1, _notSupported));
    register('createDirectory', AsyncNativeFunction('file.createDirectory', 1, _notSupported));
    register('deleteDirectory', AsyncNativeFunction('file.deleteDirectory', 1, _notSupported));

    // File info
    register('getInfo', AsyncNativeFunction('file.getInfo', 1, _notSupported));
  }

  Future<Object?> _notSupported(List<Object?> args) async {
    return {'error': true, 'message': 'File I/O is not supported on Web platform'};
  }
}
