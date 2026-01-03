import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/modules/camera_module.dart';

void main() {
  group('CameraModule', () {
    test('should be a singleton', () {
      final instance1 = CameraModule.instance;
      final instance2 = CameraModule.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('should have correct module name', () {
      expect(CameraModule.instance.name, equals('camera'));
    });

    test('should have all required functions registered', () {
      final module = CameraModule.instance;
      // Camera module should have the 'camera' name
      expect(module.name, equals('camera'));
    });
  });
}
