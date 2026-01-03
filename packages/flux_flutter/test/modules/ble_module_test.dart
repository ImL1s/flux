import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/modules/ble_module.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  group('BleModule', () {
    late BleModule module;
    
    setUp(() {
      module = BleModule.instance;
    });
    
    test('should be a singleton', () {
      final instance1 = BleModule.instance;
      final instance2 = BleModule.instance;
      expect(identical(instance1, instance2), isTrue);
    });

    test('should have correct module name', () {
      expect(module.name, equals('ble'));
    });

    test('should have all required functions registered', () {
      expect(module.get('isAvailable'), isNotNull);
      expect(module.get('startScan'), isNotNull);
      expect(module.get('stopScan'), isNotNull);
      expect(module.get('connect'), isNotNull);
      expect(module.get('disconnect'), isNotNull);
      expect(module.get('discoverServices'), isNotNull);
      expect(module.get('read'), isNotNull);
      expect(module.get('write'), isNotNull);
      expect(module.get('subscribe'), isNotNull);
      expect(module.get('unsubscribe'), isNotNull);
      expect(module.get('getDiscoveredDevices'), isNotNull);
    });
    
    test('isAvailable should return false in test environment', () async {
      // In tests, real bluetooth is not available
      final result = await module.get('isAvailable')?.call([]);
      expect(result, isFalse);
    });
    
    group('Scan Operations', () {
      test('stopScan should handle error gracefully when no adapter', () async {
        final result = await module.get('stopScan')?.call([]);
        expect(result, isA<Map>());
        // In test env, this might return success false
      });
      
      test('getDiscoveredDevices should be empty initially', () {
        final result = module.get('getDiscoveredDevices')?.call([]);
        expect(result, isA<List>());
        expect((result as List).isEmpty, isTrue);
      });
    });
    
    group('Connection Operations', () {
      test('connect should fail without deviceId', () async {
        final result = await module.get('connect')?.call([]);
        expect(result, isA<Map>());
        expect((result as Map)['success'], isFalse);
        expect(result['error'], contains('Device ID required'));
      });
      
      test('disconnect should fail for non-connected device', () async {
        final result = await module.get('disconnect')?.call(['invalid-id']);
        expect(result, isA<Map>());
        expect((result as Map)['success'], isFalse);
      });
    });
    
    group('Data Operations', () {
      test('read should require arguments', () async {
        final result = await module.get('read')?.call([]);
        expect((result as Map)['success'], isFalse);
      });
      
      test('write should require arguments', () async {
        final result = await module.get('write')?.call([]);
        expect((result as Map)['success'], isFalse);
      });
      
      test('subscribe should require arguments', () async {
        final result = await module.get('subscribe')?.call([]);
        expect((result as Map)['success'], isFalse);
      });
    });
  });
}
