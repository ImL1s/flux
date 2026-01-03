import 'package:flutter/widgets.dart';
import 'package:flux_vm/flux_vm.dart';

/// Bluetooth Low Energy (BLE) module for Flux scripting language.
/// 
/// Provides BLE functionality accessible from Flux scripts:
/// - `ble.isAvailable()` - Check if BLE is available on device
/// - `ble.startScan({timeout, serviceUuids})` - Start scanning for devices
/// - `ble.stopScan()` - Stop scanning
/// - `ble.connect(deviceId)` - Connect to a device
/// - `ble.disconnect(deviceId)` - Disconnect from a device
/// - `ble.discoverServices(deviceId)` - Discover services on connected device
/// - `ble.read(deviceId, serviceUuid, charUuid)` - Read characteristic value
/// - `ble.write(deviceId, serviceUuid, charUuid, data)` - Write to characteristic
/// - `ble.subscribe(deviceId, serviceUuid, charUuid, callback)` - Subscribe to notifications
class BleModule extends FluxModule {
  static BleModule? _instance;
  
  /// Singleton instance
  static BleModule get instance => _instance ??= BleModule._();
  
  // Store discovered devices
  final List<Map<String, dynamic>> _discoveredDevices = [];
  
  // Store connected devices
  final Set<String> _connectedDevices = {};
  
  // Store subscriptions
  final Map<String, Function> _subscriptions = {};
  
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
  
  // Check if BLE is available
  Future<Object?> _isAvailable(List<Object?> args) async {
    // TODO: Integrate with flutter_blue_plus
    // return await FlutterBluePlus.isAvailable;
    debugPrint('[BleModule] Checking BLE availability');
    return true;
  }
  
  // Start scanning for BLE devices
  Future<Object?> _startScan(List<Object?> args) async {
    final options = args.isNotEmpty && args[0] is Map ? args[0] as Map : {};
    final timeout = options['timeout'] ?? 5000; // Default 5 seconds
    final serviceUuids = options['serviceUuids'] as List? ?? [];
    
    debugPrint('[BleModule] Starting scan with timeout: ${timeout}ms, filters: $serviceUuids');
    
    // TODO: Integrate with flutter_blue_plus
    // FlutterBluePlus.startScan(
    //   timeout: Duration(milliseconds: timeout),
    //   withServices: serviceUuids.map((s) => Guid(s)).toList(),
    // );
    
    // Simulate discovering devices
    _discoveredDevices.clear();
    await Future.delayed(Duration(milliseconds: (timeout as int).clamp(100, 5000)));
    
    // Add mock devices for testing
    _discoveredDevices.addAll([
      {
        'id': 'mock-device-001',
        'name': 'Flux Sensor',
        'rssi': -65,
        'services': ['180d', '180f'], // Heart Rate, Battery
      },
      {
        'id': 'mock-device-002', 
        'name': 'Smart LED',
        'rssi': -72,
        'services': ['1800'], // Generic Access
      },
    ]);
    
    return _discoveredDevices.length;
  }
  
  // Stop scanning
  Future<Object?> _stopScan(List<Object?> args) async {
    debugPrint('[BleModule] Stopping scan');
    // TODO: FlutterBluePlus.stopScan();
    return null;
  }
  
  // Get list of discovered devices
  Object? _getDiscoveredDevices(List<Object?> args) {
    return List<Map<String, dynamic>>.from(_discoveredDevices);
  }
  
  // Connect to a device
  Future<Object?> _connect(List<Object?> args) async {
    final deviceId = args.isNotEmpty ? args[0].toString() : '';
    if (deviceId.isEmpty) {
      throw 'ble.connect: deviceId is required';
    }
    
    debugPrint('[BleModule] Connecting to $deviceId');
    
    // TODO: Integrate with flutter_blue_plus
    // final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
    // await device.connect();
    
    // Simulate connection
    await Future.delayed(const Duration(milliseconds: 500));
    _connectedDevices.add(deviceId);
    
    return true;
  }
  
  // Disconnect from a device
  Future<Object?> _disconnect(List<Object?> args) async {
    final deviceId = args.isNotEmpty ? args[0].toString() : '';
    if (deviceId.isEmpty) {
      throw 'ble.disconnect: deviceId is required';
    }
    
    debugPrint('[BleModule] Disconnecting from $deviceId');
    
    // TODO: Integrate with flutter_blue_plus
    // final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
    // await device.disconnect();
    
    _connectedDevices.remove(deviceId);
    
    // Remove subscriptions for this device
    _subscriptions.removeWhere((key, _) => key.startsWith(deviceId));
    
    return true;
  }
  
  // Discover services on connected device
  Future<Object?> _discoverServices(List<Object?> args) async {
    final deviceId = args.isNotEmpty ? args[0].toString() : '';
    if (deviceId.isEmpty) {
      throw 'ble.discoverServices: deviceId is required';
    }
    
    if (!_connectedDevices.contains(deviceId)) {
      throw 'ble.discoverServices: device not connected';
    }
    
    debugPrint('[BleModule] Discovering services on $deviceId');
    
    // TODO: Integrate with flutter_blue_plus
    // final device = BluetoothDevice(remoteId: DeviceIdentifier(deviceId));
    // final services = await device.discoverServices();
    // return services.map((s) => { 'uuid': s.serviceUuid.toString(), ... }).toList();
    
    // Mock services
    return [
      {
        'uuid': '180d',
        'characteristics': [
          {'uuid': '2a37', 'properties': ['read', 'notify']},
          {'uuid': '2a38', 'properties': ['read']},
        ],
      },
      {
        'uuid': '180f',
        'characteristics': [
          {'uuid': '2a19', 'properties': ['read', 'notify']},
        ],
      },
    ];
  }
  
  // Read characteristic value
  Future<Object?> _read(List<Object?> args) async {
    if (args.length < 3) {
      throw 'ble.read: requires deviceId, serviceUuid, charUuid';
    }
    
    final deviceId = args[0].toString();
    final serviceUuid = args[1].toString();
    final charUuid = args[2].toString();
    
    debugPrint('[BleModule] Reading $charUuid from $serviceUuid on $deviceId');
    
    // TODO: Integrate with flutter_blue_plus
    // final char = await _getCharacteristic(deviceId, serviceUuid, charUuid);
    // final value = await char.read();
    // return value;
    
    // Mock read value (e.g., heart rate)
    return [72]; // 72 bpm
  }
  
  // Write to characteristic
  Future<Object?> _write(List<Object?> args) async {
    if (args.length < 4) {
      throw 'ble.write: requires deviceId, serviceUuid, charUuid, data';
    }
    
    final deviceId = args[0].toString();
    final serviceUuid = args[1].toString();
    final charUuid = args[2].toString();
    final data = args[3];
    
    debugPrint('[BleModule] Writing to $charUuid on $serviceUuid ($deviceId): $data');
    
    // TODO: Integrate with flutter_blue_plus
    // final char = await _getCharacteristic(deviceId, serviceUuid, charUuid);
    // final bytes = data is List ? data.cast<int>() : utf8.encode(data.toString());
    // await char.write(bytes);
    
    return true;
  }
  
  // Subscribe to characteristic notifications
  Future<Object?> _subscribe(List<Object?> args) async {
    if (args.length < 4) {
      throw 'ble.subscribe: requires deviceId, serviceUuid, charUuid, callback';
    }
    
    final deviceId = args[0].toString();
    final serviceUuid = args[1].toString();
    final charUuid = args[2].toString();
    final callback = args[3];
    
    if (callback is! Function) {
      throw 'ble.subscribe: callback must be a function';
    }
    
    final key = '$deviceId:$serviceUuid:$charUuid';
    debugPrint('[BleModule] Subscribing to $key');
    
    // TODO: Integrate with flutter_blue_plus
    // final char = await _getCharacteristic(deviceId, serviceUuid, charUuid);
    // await char.setNotifyValue(true);
    // char.onValueReceived.listen((value) => callback([value]));
    
    _subscriptions[key] = callback;
    
    return true;
  }
  
  // Unsubscribe from characteristic notifications
  Future<Object?> _unsubscribe(List<Object?> args) async {
    if (args.length < 3) {
      throw 'ble.unsubscribe: requires deviceId, serviceUuid, charUuid';
    }
    
    final deviceId = args[0].toString();
    final serviceUuid = args[1].toString();
    final charUuid = args[2].toString();
    
    final key = '$deviceId:$serviceUuid:$charUuid';
    debugPrint('[BleModule] Unsubscribing from $key');
    
    // TODO: Integrate with flutter_blue_plus
    // final char = await _getCharacteristic(deviceId, serviceUuid, charUuid);
    // await char.setNotifyValue(false);
    
    _subscriptions.remove(key);
    
    return true;
  }
}
