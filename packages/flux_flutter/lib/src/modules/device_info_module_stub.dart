import 'package:flux_vm/flux_vm.dart';

/// Stub implementation of DeviceInfoModule for test/web environments
/// where dart:io Platform APIs are unavailable.
class DeviceInfoModule extends FluxModule {
  DeviceInfoModule() : super('device') {
    register('getDeviceInfo', AsyncNativeFunction('device.getDeviceInfo', 0, _stubGetDeviceInfo));
    register('getPackageInfo', AsyncNativeFunction('device.getPackageInfo', 0, _stubGetPackageInfo));
  }

  Future<Object?> _stubGetDeviceInfo(List<Object?> args) async {
    return {
      'os': 'test',
      'version': 'stub',
      'model': 'test_device',
    };
  }

  Future<Object?> _stubGetPackageInfo(List<Object?> args) async {
    return {
      'appName': 'TestApp',
      'packageName': 'com.test.app',
      'version': '1.0.0',
      'buildNumber': '1',
    };
  }
}

