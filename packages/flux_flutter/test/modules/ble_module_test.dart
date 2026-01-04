import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flux_flutter/src/modules/ble_module.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Mocks
class MockBleWrapper extends Mock implements BleWrapper {}

class MockBluetoothDevice extends Mock implements BluetoothDevice {}

class MockBluetoothService extends Mock implements BluetoothService {}

class MockBluetoothCharacteristic extends Mock
    implements BluetoothCharacteristic {}

void main() {
  group('BleModule', () {
    late BleModule module;
    late MockBleWrapper mockWrapper;

    setUp(() {
      mockWrapper = MockBleWrapper();
      module = BleModule.test(mockWrapper);

      // Register fallback values if needed
      registerFallbackValue(Guid('0000'));
    });

    test('isAvailable returns true when supported and adapter is on', () async {
      when(() => mockWrapper.isSupported()).thenAnswer((_) async => true);
      when(() => mockWrapper.adapterState)
          .thenAnswer((_) => Stream.value(BluetoothAdapterState.on));

      final result = await module.get('isAvailable')?.call([]);
      expect(result, isTrue);
    });

    test('isAvailable returns false when not supported', () async {
      when(() => mockWrapper.isSupported()).thenAnswer((_) async => false);

      final result = await module.get('isAvailable')?.call([]);
      expect(result, isFalse);
    });

    group('Scanning', () {
      test('startScan invokes wrapper and returns success', () async {
        when(() => mockWrapper.scanResults).thenAnswer((_) => Stream.empty());
        when(() => mockWrapper.startScan(
              timeout: any(named: 'timeout'),
              withServices: any(named: 'withServices'),
            )).thenAnswer((_) async {});

        final result = await module.get('startScan')?.call([
          {'timeout': 100}
        ]);

        verify(() => mockWrapper.startScan(
              timeout: any(named: 'timeout'),
              withServices: any(named: 'withServices'),
            )).called(1);

        expect(result, isA<Map>());
        expect((result as Map)['success'], isTrue);
      });

      test('stopScan invokes wrapper', () async {
        when(() => mockWrapper.stopScan()).thenAnswer((_) async {});

        await module.get('stopScan')?.call([]);

        verify(() => mockWrapper.stopScan()).called(1);
      });
    });

    group('Connection', () {
      late MockBluetoothDevice mockDevice;
      final deviceId = 'test-device-id';

      setUp(() {
        mockDevice = MockBluetoothDevice();
        when(() => mockWrapper.fromId(deviceId)).thenReturn(mockDevice);
        when(() => mockDevice.connect()).thenAnswer((_) async {});
        when(() => mockDevice.disconnect()).thenAnswer((_) async {});
        when(() => mockDevice.remoteId).thenReturn(DeviceIdentifier(deviceId));
      });

      test('connect calls device connect', () async {
        final result = await module.get('connect')?.call([deviceId]);

        verify(() => mockDevice.connect()).called(1);
        expect((result as Map)['success'], isTrue);
      });

      test('disconnect calls device disconnect', () async {
        // First connect
        await module.get('connect')?.call([deviceId]);

        final result = await module.get('disconnect')?.call([deviceId]);

        verify(() => mockDevice.disconnect()).called(1);
        expect((result as Map)['success'], isTrue);
      });
    });

    group('Services & Characteristics', () {
      late MockBluetoothDevice mockDevice;
      late MockBluetoothService mockService;
      late MockBluetoothCharacteristic mockChar;
      final deviceId = 'test-device-id';
      final serviceUuid = '180d';
      final charUuid = '2a37';

      setUp(() async {
        mockDevice = MockBluetoothDevice();
        mockService = MockBluetoothService();
        mockChar = MockBluetoothCharacteristic();

        when(() => mockWrapper.fromId(deviceId)).thenReturn(mockDevice);
        when(() => mockDevice.connect()).thenAnswer((_) async {});

        // Mock service discovery
        when(() => mockDevice.discoverServices())
            .thenAnswer((_) async => [mockService]);
        when(() => mockService.serviceUuid).thenReturn(Guid(serviceUuid));
        when(() => mockService.characteristics).thenReturn([mockChar]);

        // Mock characteristic
        when(() => mockChar.characteristicUuid).thenReturn(Guid(charUuid));
        when(() => mockChar.properties).thenReturn(CharacteristicProperties(
            read: true,
            write: false,
            notify: true,
            indicate: false,
            broadcast: false,
            extendedProperties: false,
            authenticatedSignedWrites: false,
            writeWithoutResponse: false));

        // Connect device first logic
        await module.get('connect')?.call([deviceId]);
        // Also ensure servicesList returns the discovered services
        when(() => mockDevice.servicesList).thenReturn([mockService]);
      });

      test('discoverServices returns mapped services', () async {
        final result = await module.get('discoverServices')?.call([deviceId]);
        expect((result as Map)['success'], isTrue);
        final services = result['services'] as List;
        expect(services.length, 1);
        expect(services[0]['uuid'], equals(serviceUuid));
      });

      test('read calls characteristic read', () async {
        when(() => mockChar.read()).thenAnswer((_) async => [123]);

        final result =
            await module.get('read')?.call([deviceId, serviceUuid, charUuid]);

        verify(() => mockChar.read()).called(1);
        expect((result as Map)['success'], isTrue);
        expect(result['value'], equals([123]));
      });

      test('write calls characteristic write', () async {
        when(() => mockChar.write(any())).thenAnswer((_) async {});

        final result = await module.get('write')?.call([
          deviceId,
          serviceUuid,
          charUuid,
          [1, 2, 3]
        ]);

        verify(() => mockChar.write([1, 2, 3])).called(1);
        expect((result as Map)['success'], isTrue);
      });

      test('subscribe and unsubscribe logic', () async {
        final controller = StreamController<List<int>>();
        when(() => mockChar.setNotifyValue(any()))
            .thenAnswer((_) async => true);
        when(() => mockChar.lastValueStream)
            .thenAnswer((_) => controller.stream);

        var callbackCalled = false;
        void callback(List<dynamic> args) {
          callbackCalled = true;
          expect(args[0], equals([42]));
        }

        // Subscribe
        final subResult = await module
            .get('subscribe')
            ?.call([deviceId, serviceUuid, charUuid, callback]);
        expect((subResult as Map)['success'], isTrue);
        verify(() => mockChar.setNotifyValue(true)).called(1);

        // Trigger notification
        controller.add([42]);
        await Future.delayed(Duration.zero); // Let stream deliver
        expect(callbackCalled, isTrue);

        // Unsubscribe
        final unsubResult = await module
            .get('unsubscribe')
            ?.call([deviceId, serviceUuid, charUuid]);
        expect((unsubResult as Map)['success'], isTrue);
        verify(() => mockChar.setNotifyValue(false)).called(1);

        controller.close();
      });

      test('read/write/subscribe fail if characteristic not found', () async {
        final result = await module
            .get('read')
            ?.call([deviceId, serviceUuid, 'invalid-char']);
        expect((result as Map)['success'], isFalse);
        expect(result['error'], contains('Characteristic not found'));
      });
    });

    group('Error Handling Edge Cases', () {
      test('connect fails gracefully on exception', () async {
        final deviceId = 'fail-device';
        final mockDevice = MockBluetoothDevice();
        when(() => mockWrapper.fromId(deviceId)).thenReturn(mockDevice);
        when(() => mockDevice.connect())
            .thenThrow(Exception('Connection failed'));

        final result = await module.get('connect')?.call([deviceId]);
        expect((result as Map)['success'], isFalse);
        expect(result['error'], contains('Connection failed'));
      });

      test('discoverServices fails if device not connected', () async {
        final result =
            await module.get('discoverServices')?.call(['not-connected']);
        expect((result as Map)['success'], isFalse);
        expect(result['error'], contains('Device not connected'));
      });
    });
  });
}
