import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Wrapper interface for FlutterBluePlus static methods to enable mocking.
abstract class BleWrapper {
  Future<bool> isSupported();
  Stream<BluetoothAdapterState> get adapterState;
  Stream<List<ScanResult>> get scanResults;
  Future<void> startScan({Duration? timeout, List<Guid>? withServices});
  Future<void> stopScan();
  BluetoothDevice fromId(String remoteId);
}

/// Real implementation of BleWrapper using FlutterBluePlus.
class RealBleWrapper implements BleWrapper {
  @override
  Future<bool> isSupported() => FlutterBluePlus.isSupported;

  @override
  Stream<BluetoothAdapterState> get adapterState => FlutterBluePlus.adapterState;

  @override
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  @override
  Future<void> startScan({Duration? timeout, List<Guid>? withServices}) {
    return FlutterBluePlus.startScan(timeout: timeout, withServices: withServices ?? []);
  }

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();

  @override
  BluetoothDevice fromId(String remoteId) => BluetoothDevice.fromId(remoteId);
}

/// Bluetooth Low Energy (BLE) module for Flux scripting language.
class BleModule extends FluxModule {
  static BleModule? _instance;
  
  /// The wrapper instance used for BLE operations.
  final BleWrapper _bleWrapper;
  
  /// Singleton instance
  static BleModule get instance => _instance ??= BleModule._(RealBleWrapper());

  /// Constructor for testing with mock wrapper
  @visibleForTesting
  BleModule.test(this._bleWrapper) : super('ble') {
    _registerFunctions();
  }

  BleModule._(this._bleWrapper) : super('ble') {
    _registerFunctions();
  }

  void _registerFunctions() {
    register('isAvailable', AsyncNativeFunction('ble.isAvailable', 0, _isAvailable));
    register('startScan', AsyncNativeFunction('ble.startScan', 1, _startScan));
    register('stopScan', AsyncNativeFunction('ble.stopScan', 0, _stopScan));
    register('getDiscoveredDevices', NativeFunction('ble.getDiscoveredDevices', 0, _getDiscoveredDevices));
    register('connect', AsyncNativeFunction('ble.connect', 1, _connect));
    register('disconnect', AsyncNativeFunction('ble.disconnect', 1, _disconnect));
    register('discoverServices', AsyncNativeFunction('ble.discoverServices', 1, _discoverServices));
    register('read', AsyncNativeFunction('ble.read', 3, _read));
    register('write', AsyncNativeFunction('ble.write', 4, _write));
    register('subscribe', AsyncNativeFunction('ble.subscribe', 4, _subscribe));
    register('unsubscribe', AsyncNativeFunction('ble.unsubscribe', 3, _unsubscribe));
  }
  
  // Store connected devices
  final Map<String, BluetoothDevice> _connectedDevices = {};
  
  // Store subscriptions
  final Map<String, StreamSubscription> _subscriptions = {};
  
  // Store discovered devices for retrieval
  final Map<String, ScanResult> _scanResults = {};
  
  Future<Object?> _isAvailable(List<Object?> args) async {
    try {
      // Check if hardware supports BLE
      if (!await _bleWrapper.isSupported()) {
        return false;
      }
      
      // Check if Bluetooth is on
      return await _bleWrapper.adapterState.first == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('[BleModule] Error checking availability: $e');
      return false;
    }
  }
  
  Future<Object?> _startScan(List<Object?> args) async {
    final options = args.isNotEmpty && args[0] is Map ? args[0] as Map : {};
    final timeout = (options['timeout'] as num? ?? 10000).toInt();
    final withServices = options['withServices'] as List?;
    
    final List<Guid> serviceGuids = [];
    if (withServices != null) {
      for (var s in withServices) {
        serviceGuids.add(Guid(s.toString()));
      }
    }

    try {
      final subscription = _bleWrapper.scanResults.listen((results) {
        for (var r in results) {
          _scanResults[r.device.remoteId.toString()] = r;
        }
      });
      
      debugPrint('[BleModule] Starting scan...');
      
      // Start scanning
      await _bleWrapper.startScan(
        timeout: Duration(milliseconds: timeout),
        withServices: serviceGuids,
      );
      
      // Wait for scan to complete
      await Future.delayed(Duration(milliseconds: timeout));
      
      subscription.cancel();
      
      return {
        'success': true,
        'count': _scanResults.length,
      };
    } catch (e) {
      debugPrint('[BleModule] Scan error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Object?> _stopScan(List<Object?> args) async {
    try {
      await _bleWrapper.stopScan();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Object? _getDiscoveredDevices(List<Object?> args) {
    return _scanResults.values.map((result) => {
      'id': result.device.remoteId.str,
      'name': result.device.platformName,
      'rssi': result.rssi,
      'services': result.advertisementData.serviceUuids.map((u) => u.toString()).toList(),
      'connectable': result.advertisementData.connectable,
    }).toList();
  }
  
  Future<Object?> _connect(List<Object?> args) async {
    final deviceId = args.isNotEmpty ? args[0].toString() : '';
    if (deviceId.isEmpty) return {'success': false, 'error': 'Device ID required'};
    
    try {
      final device = _bleWrapper.fromId(deviceId);
      
      await device.connect();
      _connectedDevices[deviceId] = device;
      
      return {'success': true};
    } catch (e) {
      debugPrint('[BleModule] Connect error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Object?> _disconnect(List<Object?> args) async {
    final deviceId = args.isNotEmpty ? args[0].toString() : '';
    final device = _connectedDevices[deviceId];
    
    if (device == null) {
      return {'success': false, 'error': 'Device not connected'};
    }
    
    try {
      await device.disconnect();
      _connectedDevices.remove(deviceId);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Object?> _discoverServices(List<Object?> args) async {
    final deviceId = args.isNotEmpty ? args[0].toString() : '';
    final device = _connectedDevices[deviceId];
    
    if (device == null) {
      return {'success': false, 'error': 'Device not connected'};
    }
    
    try {
      final services = await device.discoverServices();
      
      return {
        'success': true,
        'services': services.map((s) => {
          'uuid': s.serviceUuid.toString(),
          'characteristics': s.characteristics.map((c) => {
            'uuid': c.characteristicUuid.toString(),
            'properties': _getPropertiesList(c.properties),
          }).toList(),
        }).toList(),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  List<String> _getPropertiesList(CharacteristicProperties props) {
    final List<String> list = [];
    if (props.read) list.add('read');
    if (props.write) list.add('write');
    if (props.writeWithoutResponse) list.add('writeWithoutResponse');
    if (props.notify) list.add('notify');
    if (props.indicate) list.add('indicate');
    return list;
  }
  
  Future<BluetoothCharacteristic?> _findCharacteristic(
    String deviceId, String serviceUuid, String charUuid) async {
    final device = _connectedDevices[deviceId];
    if (device == null) return null;
    
    // We assume services are discovered
    for (final service in device.servicesList) {
      if (service.serviceUuid.toString().toLowerCase() == serviceUuid.toLowerCase()) {
        for (final char in service.characteristics) {
          if (char.characteristicUuid.toString().toLowerCase() == charUuid.toLowerCase()) {
            return char;
          }
        }
      }
    }
    return null;
  }
  
  Future<Object?> _read(List<Object?> args) async {
    if (args.length < 3) return {'success': false, 'error': 'Missing arguments'};
    final deviceId = args[0].toString();
    final serviceUuid = args[1].toString();
    final charUuid = args[2].toString();
    
    try {
      final char = await _findCharacteristic(deviceId, serviceUuid, charUuid);
      if (char == null) return {'success': false, 'error': 'Characteristic not found'};
      
      final value = await char.read();
      return {'success': true, 'value': value};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Object?> _write(List<Object?> args) async {
    if (args.length < 4) return {'success': false, 'error': 'Missing arguments'};
    final deviceId = args[0].toString();
    final serviceUuid = args[1].toString();
    final charUuid = args[2].toString();
    final data = args[3];
    
    if (data is! List) return {'success': false, 'error': 'Data must be a list of bytes'};
    final bytes = data.map((e) => (e as num).toInt()).toList();
    
    try {
      final char = await _findCharacteristic(deviceId, serviceUuid, charUuid);
      if (char == null) return {'success': false, 'error': 'Characteristic not found'};
      
      await char.write(bytes);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Object?> _subscribe(List<Object?> args) async {
    if (args.length < 4) return {'success': false, 'error': 'Missing arguments'};
    final deviceId = args[0].toString();
    final serviceUuid = args[1].toString();
    final charUuid = args[2].toString();
    final callback = args[3];
    
    if (callback is! Function) return {'success': false, 'error': 'Callback required'};
    
    final key = '$deviceId:$serviceUuid:$charUuid';
    
    try {
      final char = await _findCharacteristic(deviceId, serviceUuid, charUuid);
      if (char == null) return {'success': false, 'error': 'Characteristic not found'};
      
      await char.setNotifyValue(true);
      
      final sub = char.lastValueStream.listen((value) {
        try {
          // Invoke callback
          // Note: In strict mode we might need to check function type,
          // but here we rely on runtime dynamic invocation
          (callback as dynamic)([value]);
        } catch (e) {
          debugPrint('Error in notification callback: $e');
        }
      });
      
      _subscriptions[key] = sub;
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Future<Object?> _unsubscribe(List<Object?> args) async {
    if (args.length < 3) return {'success': false, 'error': 'Missing arguments'};
    final deviceId = args[0].toString();
    final serviceUuid = args[1].toString();
    final charUuid = args[2].toString();
    
    final key = '$deviceId:$serviceUuid:$charUuid';
    
    try {
      await _subscriptions[key]?.cancel();
      _subscriptions.remove(key);
      
      final char = await _findCharacteristic(deviceId, serviceUuid, charUuid);
      if (char != null) {
        await char.setNotifyValue(false);
      }
      
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
