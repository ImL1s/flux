import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';

/// Script source configuration
class ScriptSource {
  final String? url;
  final String? localPath;
  final String? bundledAsset;

  const ScriptSource({this.url, this.localPath, this.bundledAsset});

  bool get isRemote => url != null;
  bool get isLocal => localPath != null;
  bool get isBundled => bundledAsset != null;
}

/// Cached script metadata
class CachedScript {
  final String hash;
  final String source;
  final DateTime cachedAt;
  final String? version;

  CachedScript({
    required this.hash,
    required this.source,
    required this.cachedAt,
    this.version,
  });

  Map<String, dynamic> toJson() => {
        'hash': hash,
        'source': source,
        'cachedAt': cachedAt.toIso8601String(),
        'version': version,
      };

  factory CachedScript.fromJson(Map<String, dynamic> json) => CachedScript(
        hash: json['hash'] as String,
        source: json['source'] as String,
        cachedAt: DateTime.parse(json['cachedAt'] as String),
        version: json['version'] as String?,
      );
}

/// Base class for platform-specific script loaders
abstract class FluxScriptLoaderBase {
  /// Load script source code specific to platform (IO/Web)
  Future<String> loadScript(ScriptSource source);

  /// Compile and run script
  /// This logic is shared across platforms
  Future<Object?> runScript(
    ScriptSource source, {
    Map<String, Object?>? globals,
  }) async {
    final scriptSource = await loadScript(source);

    final lexer = Lexer(scriptSource);
    final tokens = lexer.tokenize();
    final parser = Parser(tokens);
    final ast = parser.parse();

    final compiler = Compiler(unit: ast);
    final function = compiler.endCompiler();

    final vm = VM();

    // Inject custom globals
    if (globals != null) {
      for (final entry in globals.entries) {
        vm.globals[entry.key] = entry.value;
      }
    }

    vm.runChunk(function.chunk);

    return vm.stack.isNotEmpty ? vm.stack.last : null;
  }
}

/// Script update notifier
class ScriptUpdateNotifier {
  final List<void Function(String url)> _listeners = [];

  void addListener(void Function(String url) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(String url) listener) {
    _listeners.remove(listener);
  }

  void notifyUpdate(String url) {
    for (final listener in _listeners) {
      listener(url);
    }
  }
}
