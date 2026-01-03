import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Bluetooth Low Energy (BLE) module for Flux scripting language.
/// 
/// Provides BLE functionality accessible from Flux scripts:
/// - `ble.isAvailable()` - Check if BLE is available
/// - `ble.startScan({timeout, serviceUuids})` - Start scanning
/// - `ble.stopScan()` - Stop scanning
/// - `ble.connect(deviceId)` - Connect to device
/// - `ble.disconnect(deviceId)` - Disconnect
/// - `ble.discoverServices(deviceId)` - Discover services
/// - `ble.read(deviceId, serviceUuid, charUuid)` - Read value
/// - `ble.write(deviceId, serviceUuid, charUuid, data)` - Write value
/// - `ble.subscribe(deviceId, serviceUuid, charUuid, callback)` - Subscribe to notifications
class BleModule extends FluxModule {
  static BleModule? _instance;
  
  /// Singleton instance
  static BleModule get instance => _instance ??= BleModule._();
  
  // Store connected devices
  final Map<String, BluetoothDevice> _connectedDevices = {};
  
  // Store subscriptions
  final Map<String, StreamSubscription> _subscriptions = {};
  
  // Store discovered devices for retrieval
  final List<ScanResult> _scanResults = [];
  
  BleModule._() : super('ble') {
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
  
  Future<Object?> _isAvailable(List<Object?> args) async {
    try {
      // Check if hardware supports BLE
      if (!await FlutterBluePlus.isSupported) {
        return false;
      }
      
      // Check if Bluetooth is on
      return await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on;
    } catch (e) {
      debugPrint('[BleModule] Error checking availability: $e');
      return false;
    }
  }
  
  Future<Object?> _startScan(List<Object?> args) async {
    final options = args.isNotEmpty && args[0] is Map ? args[0] as Map : {};
    final timeout = options['timeout'] ?? 5000;
    final serviceUuidsStr = options['serviceUuids'] as List? ?? [];
    
    // Convert UUID strings to Guids
    final serviceGuids = serviceUuidsStr
        .map((s) => Guid(s.toString()))
        .toList();
    
    try {
      // Clear previous results
      _scanResults.clear();
      
      // Listen to scan results
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        _scanResults.clear();
        _scanResults.addAll(results);
      });
      
      debugPrint('[BleModule] Starting scan...');
      
      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: Duration(milliseconds: (timeout as num).toInt()),
        withServices: serviceGuids,
      );
      
      // Wait for scan to complete
      await Future.delayed(Duration(milliseconds: (timeout as num).toInt()));
      
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
      await FlutterBluePlus.stopScan();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  Object? _getDiscoveredDevices(List<Object?> args) {
    return _scanResults.map((result) => {
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
      // Find device instance not just from scan results but generically
      // FlutterBluePlus requires a device instance.
      // If found in scan results use that, otherwise verify ID format
      
      final device = BluetoothDevice.fromId(deviceId);
      
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
