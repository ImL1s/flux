/// File Module Export
///
/// Exports platform-specific implementation of FileModule.

// Conditionally export IO or Web implementation
export 'file_module_io.dart'
  if (dart.library.js_interop) 'file_module_web.dart';
