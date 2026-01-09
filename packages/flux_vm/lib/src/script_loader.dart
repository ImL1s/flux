/// Flux Script Loader
///
/// Provides hot-update capabilities with caching and versioning.
/// This is a key differentiator vs Shorebird (which requires paid subscription)
/// and vs SDUI (which requires always-online).

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
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

/// Hot-update script loader with offline caching
///
/// Key advantages over competitors:
/// - **vs Shorebird**: Free, no subscription required
/// - **vs SDUI**: Works offline with cached scripts
/// - **vs LuaDardo**: Pure Dart, no native dependencies
class FluxScriptLoader {
  final String cacheDir;
  final Duration maxAge;
  final Map<String, CachedScript> _cache = {};

  FluxScriptLoader({
    required this.cacheDir,
    this.maxAge = const Duration(hours: 24),
  });

  /// Load script with caching and fallback
  Future<String> loadScript(ScriptSource source) async {
    // Try remote first if available
    if (source.isRemote) {
      try {
        final remoteScript = await _fetchRemote(source.url!);
        await _cacheScript(source.url!, remoteScript);
        return remoteScript;
      } catch (e) {
        // Fall through to cache
      }
    }

    // Try cache
    final cached = await _loadFromCache(source.url ?? source.localPath ?? '');
    if (cached != null) {
      return cached.source;
    }

    // Try local file
    if (source.isLocal) {
      return await File(source.localPath!).readAsString();
    }

    // Try bundled asset (would need AssetBundle in Flutter)
    if (source.isBundled) {
      throw UnimplementedError('Bundled assets require Flutter context');
    }

    throw Exception('Failed to load script from any source');
  }

  /// Compile and run script
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

  /// Check if update is available (compare hash)
  Future<bool> hasUpdate(String url) async {
    final cached = await _loadFromCache(url);
    if (cached == null) return true;

    try {
      final remoteHash = await _fetchRemoteHash(url);
      return remoteHash != cached.hash;
    } catch (e) {
      return false;
    }
  }

  /// Force update script
  Future<void> forceUpdate(String url) async {
    final remoteScript = await _fetchRemote(url);
    await _cacheScript(url, remoteScript);
  }

  /// Clear all cached scripts
  Future<void> clearCache() async {
    _cache.clear();
    final cacheDirectory = Directory(cacheDir);
    if (await cacheDirectory.exists()) {
      await cacheDirectory.delete(recursive: true);
    }
  }

  // --- Private methods ---

  Future<String> _fetchRemote(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch script: ${response.statusCode}');
      }

      return await response.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  Future<String> _fetchRemoteHash(String url) async {
    // Could use HEAD request with ETag, or fetch hash endpoint
    final script = await _fetchRemote(url);
    return _computeHash(script);
  }

  String _computeHash(String content) {
    return md5.convert(utf8.encode(content)).toString();
  }

  Future<void> _cacheScript(String key, String source) async {
    final hash = _computeHash(source);
    final cached = CachedScript(
      hash: hash,
      source: source,
      cachedAt: DateTime.now(),
    );

    _cache[key] = cached;

    // Persist to disk
    final cacheFile = File('$cacheDir/${Uri.encodeComponent(key)}.json');
    await cacheFile.parent.create(recursive: true);
    await cacheFile.writeAsString(jsonEncode(cached.toJson()));
  }

  Future<CachedScript?> _loadFromCache(String key) async {
    // Check memory cache
    if (_cache.containsKey(key)) {
      final cached = _cache[key]!;
      if (DateTime.now().difference(cached.cachedAt) < maxAge) {
        return cached;
      }
    }

    // Check disk cache
    final cacheFile = File('$cacheDir/${Uri.encodeComponent(key)}.json');
    if (await cacheFile.exists()) {
      try {
        final json = jsonDecode(await cacheFile.readAsString());
        final cached = CachedScript.fromJson(json as Map<String, dynamic>);

        if (DateTime.now().difference(cached.cachedAt) < maxAge) {
          _cache[key] = cached;
          return cached;
        }
      } catch (e) {
        // Invalid cache file
      }
    }

    return null;
  }
}

/// Script update notifier for Flutter integration
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
