import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcase_app/main.dart';

void main() {
  group('Notifier Unit Tests', () {
    test('CurrentPageNotifier initial state and updates', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(currentPageProvider), 0);

      container.read(currentPageProvider.notifier).set(2);
      expect(container.read(currentPageProvider), 2);
    });

    test('StorageNotifier initial state and updates', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(storageProvider), {});

      container.read(storageProvider.notifier).save('theme', 'dark');
      expect(container.read(storageProvider)['theme'], 'dark');

      container.read(storageProvider.notifier).save('lang', 'zh');
      expect(container.read(storageProvider).length, 2);
      
      container.read(storageProvider.notifier).clear();
      expect(container.read(storageProvider), {});
    });
  });
}
