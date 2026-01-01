import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flux_vm/flux_vm.dart';

class DeviceInfoModule extends FluxModule {
  DeviceInfoModule() : super('device') {
    register('getDeviceInfo', AsyncNativeFunction('device.getDeviceInfo', 0, _getDeviceInfo));
    register('getPackageInfo', AsyncNativeFunction('device.getPackageInfo', 0, _getPackageInfo));
  }

  Future<Object?> _getDeviceInfo(List<Object?> args) async {
    final deviceInfo = DeviceInfoPlugin();
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'os': 'android',
        'version': androidInfo.version.release,
        'model': androidInfo.model,
        'id': androidInfo.id,
        'brand': androidInfo.brand,
        'isPhysical': androidInfo.isPhysicalDevice,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'os': 'ios',
        'version': iosInfo.systemVersion,
        'model': iosInfo.model,
        'id': iosInfo.identifierForVendor,
        'name': iosInfo.name,
        'isPhysical': iosInfo.isPhysicalDevice,
      };
    } else if (Platform.isWindows) {
      final windowsInfo = await deviceInfo.windowsInfo;
      return {
          'os': 'windows',
          'computerName': windowsInfo.computerName,
      };
    } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return {
            'os': 'macos',
            'model': macInfo.model,
            'computerName': macInfo.computerName,
        };
    }
    
    return {'os': 'unknown'};
  }

  Future<Object?> _getPackageInfo(List<Object?> args) async {
    final info = await PackageInfo.fromPlatform();
    return {
      'appName': info.appName,
      'packageName': info.packageName,
      'version': info.version,
      'buildNumber': info.buildNumber,
    };
  }
}

