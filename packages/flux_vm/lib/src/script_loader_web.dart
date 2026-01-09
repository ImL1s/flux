import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'script_loader_base.dart';

export 'script_loader_base.dart';

/// Web-compatible Script Loader
class FluxScriptLoader extends FluxScriptLoaderBase {
  final String cacheDir;
  final Duration maxAge;
  // In-memory cache for Web session
  final Map<String, CachedScript> _cache = {};

  FluxScriptLoader({
    required this.cacheDir, // Ignored on Web
    this.maxAge = const Duration(hours: 24),
  });

  /// Load script (Remote only)
  @override
  Future<String> loadScript(ScriptSource source) async {
    if (source.isRemote) {
      // Check cache first
      final cached = await _loadFromCache(source.url!);
      if (cached != null) return cached.source;
      
      try {
        final remoteScript = await _fetchRemote(source.url!);
        await _cacheScript(source.url!, remoteScript);
        return remoteScript;
      } catch (e) {
        throw Exception('Failed to fetch remote script: $e');
      }
    }

    if (source.isLocal) {
      throw UnsupportedError('Local file access is not supported on Web');
    }

    if (source.isBundled) {
      throw UnimplementedError('Bundled assets require Flutter context');
    }

    throw Exception('No valid source provided');
  }

  Future<bool> hasUpdate(String url) async {
    // Simple check: always true or fetch hash? 
    // For now, let's say true to force check
    return true;
  }
  
  Future<void> forceUpdate(String url) async {
     final remoteScript = await _fetchRemote(url);
     await _cacheScript(url, remoteScript);
  }

  Future<void> clearCache() async {
    _cache.clear();
  }

  Future<String> _fetchRemote(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch script: ${response.statusCode}');
    }
    return response.body;
  }

  Future<void> _cacheScript(String key, String source) async {
    final hash = md5.convert(utf8.encode(source)).toString();
    _cache[key] = CachedScript(
      hash: hash,
      source: source,
      cachedAt: DateTime.now(),
    );
  }

  Future<CachedScript?> _loadFromCache(String key) async {
    if (_cache.containsKey(key)) {
       final cached = _cache[key]!;
       if (DateTime.now().difference(cached.cachedAt) < maxAge) {
         return cached;
       }
    }
    return null;
  }
}
