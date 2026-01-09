/// Script Loader: Export logic
///
/// Exports the appropriate implementation of FluxScriptLoader based on the platform.

export 'script_loader_base.dart';

// Conditionally export IO or Web implementation
// default to IO for now, check dart.library.io
export 'script_loader_io.dart'
  if (dart.library.js_interop) 'script_loader_web.dart';
