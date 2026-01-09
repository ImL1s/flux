import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flux_vm/flux_vm.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Wrapper interface for static methods to enable mocking.
abstract class BleWrapper {
  Future<bool> isSupported();
  // Stream<BluetoothAdapterState> get adapterState;
  // Stream<List<ScanResult>> get scanResults;
  Future<void> startScan({Duration? timeout, List<dynamic>? withServices});
  Future<void> stopScan();
  // BluetoothDevice fromId(String remoteId);
}

/// Dummy implementation for platforms without BLE support or when dependency is disabled.
class RealBleWrapper implements BleWrapper {
  @override
  Future<bool> isSupported() async => false;

  @override
  Future<void> startScan({Duration? timeout, List<dynamic>? withServices}) async {}

  @override
  Future<void> stopScan() async {}
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
    register(
        'isAvailable', AsyncNativeFunction('ble.isAvailable', 0, _isAvailable));
    register('startScan', AsyncNativeFunction('ble.startScan', 1, _startScan));
    register('stopScan', AsyncNativeFunction('ble.stopScan', 0, _stopScan));
    register('getDiscoveredDevices',
        NativeFunction('ble.getDiscoveredDevices', 0, _getDiscoveredDevices));
    register('connect', AsyncNativeFunction('ble.connect', 1, _connect));
    register(
        'disconnect', AsyncNativeFunction('ble.disconnect', 1, _disconnect));
    register('discoverServices',
        AsyncNativeFunction('ble.discoverServices', 1, _discoverServices));
    register('read', AsyncNativeFunction('ble.read', 3, _read));
    register('write', AsyncNativeFunction('ble.write', 4, _write));
    register('subscribe', AsyncNativeFunction('ble.subscribe', 4, _subscribe));
    register(
        'unsubscribe', AsyncNativeFunction('ble.unsubscribe', 3, _unsubscribe));
  }

  // Store connected devices
  // final Map<String, BluetoothDevice> _connectedDevices = {};

  // Store subscriptions
  final Map<String, StreamSubscription> _subscriptions = {};

  // Store discovered devices for retrieval
  // final Map<String, ScanResult> _scanResults = {};
  final Map<String, dynamic> _scanResults = {};

  Future<Object?> _isAvailable(List<Object?> args) async {
    return false;
  }

  Future<Object?> _startScan(List<Object?> args) async {
    return {'success': false, 'error': 'BLE not supported on this build'};
  }

  Future<Object?> _stopScan(List<Object?> args) async {
    return {'success': true};
  }

  Object? _getDiscoveredDevices(List<Object?> args) {
    return [];
  }

  Future<Object?> _connect(List<Object?> args) async {
    return {'success': false, 'error': 'BLE not supported'};
  }

  Future<Object?> _disconnect(List<Object?> args) async {
    return {'success': false, 'error': 'BLE not supported'};
  }

  Future<Object?> _discoverServices(List<Object?> args) async {
    return {'success': false, 'error': 'BLE not supported'};
  }

  Future<Object?> _read(List<Object?> args) async {
    return {'success': false, 'error': 'BLE not supported'};
  }

  Future<Object?> _write(List<Object?> args) async {
    return {'success': false, 'error': 'BLE not supported'};
  }

  Future<Object?> _subscribe(List<Object?> args) async {
    return {'success': false, 'error': 'BLE not supported'};
  }

  Future<Object?> _unsubscribe(List<Object?> args) async {
    return {'success': false, 'error': 'BLE not supported'};
  }
}
