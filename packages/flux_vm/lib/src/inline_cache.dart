/// Inline Cache for VM property and method lookups
///
/// Caches the result of property/method lookups to avoid repeated
/// hash map lookups for the same property on objects of the same class.

import 'package:flux_compiler/flux_compiler.dart';

/// A single cache entry for monomorphic inline caching
class InlineCacheEntry {
  /// The class type this cache entry is for
  final CompiledClass? klassType;

  /// The cached method (null if this is a field access)
  final CompiledFunction? method;

  /// Whether this property is a field (not a method)
  final bool isField;

  /// Number of hits for this cache entry
  int hits = 0;

  InlineCacheEntry({
    this.klassType,
    this.method,
    this.isField = false,
  });
}

/// Polymorphic Inline Cache with up to 4 entries
class PolymorphicInlineCache {
  static const int maxEntries = 4;

  final List<InlineCacheEntry> _entries = [];
  final String propertyName;

  /// Total lookup count for statistics
  int totalLookups = 0;

  /// Cache hit count
  int cacheHits = 0;

  PolymorphicInlineCache(this.propertyName);

  /// Try to get cached method for the given class type
  /// Returns null if not cached (cache miss)
  CompiledFunction? lookupMethod(CompiledClass klass) {
    totalLookups++;

    for (final entry in _entries) {
      if (identical(entry.klassType, klass) && !entry.isField) {
        entry.hits++;
        cacheHits++;
        return entry.method;
      }
    }

    return null; // Cache miss
  }

  /// Check if property is cached as a field access
  bool isCachedAsField(CompiledClass klass) {
    for (final entry in _entries) {
      if (identical(entry.klassType, klass) && entry.isField) {
        entry.hits++;
        cacheHits++;
        return true;
      }
    }
    return false;
  }

  /// Add a method lookup result to the cache
  void cacheMethod(CompiledClass klass, CompiledFunction method) {
    if (_entries.length >= maxEntries) {
      // Evict least-used entry
      _entries.sort((a, b) => a.hits.compareTo(b.hits));
      _entries.removeAt(0);
    }

    _entries.add(InlineCacheEntry(
      klassType: klass,
      method: method,
      isField: false,
    ));
  }

  /// Add a field access to the cache
  void cacheField(CompiledClass klass) {
    if (_entries.length >= maxEntries) {
      _entries.sort((a, b) => a.hits.compareTo(b.hits));
      _entries.removeAt(0);
    }

    _entries.add(InlineCacheEntry(
      klassType: klass,
      isField: true,
    ));
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'property': propertyName,
      'totalLookups': totalLookups,
      'cacheHits': cacheHits,
      'hitRate': totalLookups > 0
          ? (cacheHits / totalLookups * 100).toStringAsFixed(1)
          : '0.0',
      'entries': _entries.length,
    };
  }
}

/// Global Inline Cache Manager for the VM
class InlineCacheManager {
  /// Map from bytecode offset to inline cache
  /// (Each getProperty/invoke call site has its own cache)
  final Map<int, PolymorphicInlineCache> _caches = {};

  /// Get or create an inline cache for a call site
  PolymorphicInlineCache getCache(int callSiteOffset, String propertyName) {
    return _caches.putIfAbsent(
      callSiteOffset,
      () => PolymorphicInlineCache(propertyName),
    );
  }

  /// Clear all caches (e.g., on hot reload)
  void clearAll() {
    _caches.clear();
  }

  /// Get statistics for all caches
  Map<String, dynamic> getStats() {
    int totalLookups = 0;
    int totalHits = 0;

    for (final cache in _caches.values) {
      totalLookups += cache.totalLookups;
      totalHits += cache.cacheHits;
    }

    return {
      'totalCaches': _caches.length,
      'totalLookups': totalLookups,
      'totalHits': totalHits,
      'overallHitRate': totalLookups > 0
          ? '${(totalHits / totalLookups * 100).toStringAsFixed(1)}%'
          : 'N/A',
    };
  }
}
