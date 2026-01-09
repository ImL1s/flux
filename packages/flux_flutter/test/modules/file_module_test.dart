import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/modules/file_module.dart';

void main() {
  late FileModule module;

  setUp(() {
    module = FileModule();
  });

  group('FileModule Tests', () {
    test('Module registration has correct functions', () {
      // Directory access
      expect(module.members.containsKey('getDocumentsDirectory'), true);
      expect(module.members.containsKey('getTempDirectory'), true);
      expect(module.members.containsKey('getCacheDirectory'), true);

      // File operations
      expect(module.members.containsKey('readText'), true);
      expect(module.members.containsKey('writeText'), true);
      expect(module.members.containsKey('readJson'), true);
      expect(module.members.containsKey('writeJson'), true);
      expect(module.members.containsKey('readBytes'), true);
      expect(module.members.containsKey('writeBytes'), true);
      expect(module.members.containsKey('append'), true);

      // File management
      expect(module.members.containsKey('exists'), true);
      expect(module.members.containsKey('delete'), true);
      expect(module.members.containsKey('copy'), true);
      expect(module.members.containsKey('move'), true);
      expect(module.members.containsKey('rename'), true);

      // Directory operations
      expect(module.members.containsKey('list'), true);
      expect(module.members.containsKey('createDirectory'), true);
      expect(module.members.containsKey('deleteDirectory'), true);

      // File info
      expect(module.members.containsKey('getInfo'), true);
    });

    test('Module name is file', () {
      expect(module.name, 'file');
    });
  });
}
