import 'package:test/test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/src/inline_cache.dart';

void main() {
  group('PolymorphicInlineCache', () {
    late CompiledClass testClass1;
    late CompiledClass testClass2;
    late CompiledFunction testMethod;

    setUp(() {
      testClass1 = CompiledClass('Foo', methods: {});
      testClass2 = CompiledClass('Bar', methods: {});
      testMethod = CompiledFunction('test', Chunk());
    });

    test('returns null on cache miss', () {
      final cache = PolymorphicInlineCache('testProp');
      expect(cache.lookupMethod(testClass1), isNull);
    });

    test('returns cached method on cache hit', () {
      final cache = PolymorphicInlineCache('testProp');

      cache.cacheMethod(testClass1, testMethod);
      final result = cache.lookupMethod(testClass1);

      expect(result, equals(testMethod));
    });

    test('tracks hit statistics', () {
      final cache = PolymorphicInlineCache('testProp');

      cache.cacheMethod(testClass1, testMethod);
      cache.lookupMethod(testClass1); // Hit
      cache.lookupMethod(testClass1); // Hit
      cache.lookupMethod(testClass2); // Miss

      final stats = cache.getStats();
      expect(stats['totalLookups'], equals(3));
      expect(stats['cacheHits'], equals(2));
    });

    test('supports polymorphic caching (multiple types)', () {
      final cache = PolymorphicInlineCache('testProp');
      final method2 = CompiledFunction('test2', Chunk());

      cache.cacheMethod(testClass1, testMethod);
      cache.cacheMethod(testClass2, method2);

      expect(cache.lookupMethod(testClass1), equals(testMethod));
      expect(cache.lookupMethod(testClass2), equals(method2));
    });

    test('evicts least-used entry when full', () {
      final cache = PolymorphicInlineCache('testProp');

      // Fill cache with 4 entries
      final classes =
          List.generate(4, (i) => CompiledClass('Class$i', methods: {}));
      final methods =
          List.generate(4, (i) => CompiledFunction('method$i', Chunk()));

      for (int i = 0; i < 4; i++) {
        cache.cacheMethod(classes[i], methods[i]);
      }

      // Access first entry multiple times to make it "hot"
      cache.lookupMethod(classes[0]);
      cache.lookupMethod(classes[0]);
      cache.lookupMethod(classes[0]);

      // Add new entry, should evict least-used
      final newClass = CompiledClass('NewClass', methods: {});
      final newMethod = CompiledFunction('newMethod', Chunk());
      cache.cacheMethod(newClass, newMethod);

      // First entry should still be cached (hot)
      expect(cache.lookupMethod(classes[0]), equals(methods[0]));

      // New entry should be cached
      expect(cache.lookupMethod(newClass), equals(newMethod));
    });

    test('caches field access separately from methods', () {
      final cache = PolymorphicInlineCache('testProp');

      cache.cacheField(testClass1);
      cache.cacheMethod(testClass2, testMethod);

      expect(cache.isCachedAsField(testClass1), isTrue);
      expect(cache.isCachedAsField(testClass2), isFalse);
      expect(cache.lookupMethod(testClass2), equals(testMethod));
    });
  });

  group('InlineCacheManager', () {
    test('creates cache for new call site', () {
      final manager = InlineCacheManager();

      final cache1 = manager.getCache(100, 'prop1');
      final cache2 = manager.getCache(100, 'prop1');

      expect(identical(cache1, cache2), isTrue);
    });

    test('tracks aggregate statistics', () {
      final manager = InlineCacheManager();
      final testClass = CompiledClass('Test', methods: {});
      final testMethod = CompiledFunction('method', Chunk());

      final cache1 = manager.getCache(100, 'prop1');
      final cache2 = manager.getCache(200, 'prop2');

      cache1.cacheMethod(testClass, testMethod);
      cache1.lookupMethod(testClass); // Hit
      cache2.lookupMethod(testClass); // Miss

      final stats = manager.getStats();
      expect(stats['totalCaches'], equals(2));
      expect(stats['totalLookups'], equals(2));
      expect(stats['totalHits'], equals(1));
    });

    test('clears all caches', () {
      final manager = InlineCacheManager();

      manager.getCache(100, 'prop1');
      manager.getCache(200, 'prop2');

      manager.clearAll();

      final stats = manager.getStats();
      expect(stats['totalCaches'], equals(0));
    });
  });
}
