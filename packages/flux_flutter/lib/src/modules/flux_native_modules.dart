import 'package:flutter/foundation.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_flutter/src/modules/http_module.dart';
import 'package:flux_flutter/src/modules/storage_module.dart';
import 'package:flux_flutter/src/modules/dialog_module.dart';
import 'package:flux_flutter/src/modules/navigation_module.dart';
import 'package:flux_flutter/src/modules/camera_module.dart';
import 'package:flux_flutter/src/modules/ble_module.dart';
import 'package:flux_flutter/src/modules/time_module.dart';
import 'package:flux_flutter/src/modules/hive_storage_module.dart';
import 'package:flux_flutter/src/modules/secure_storage_module.dart';

// Conditional import: use stub in web, real module in io environments
import 'package:flux_flutter/src/modules/device_info_module_stub.dart'
    if (dart.library.io) 'package:flux_flutter/src/modules/device_info_module.dart';

/// Registry for Flux native modules that depend on Flutter/Dart ecosystem
class FluxNativeModules {
  /// Register all available native modules with the VM
  static void register(VM vm) {
    void reg(String name, FluxModule module) {
      try {
        vm.registerModule(module);
      } catch (e) {
        debugPrint('❌ FluxNativeModules: Failed to register $name: $e');
      }
    }

    reg('HttpModule', HttpModule());
    reg('StorageModule', StorageModule());
    reg('DialogModule', DialogModule());
    reg('DeviceInfoModule', DeviceInfoModule());
    reg('NavigationModule', NavigationModule());
    reg('CameraModule', CameraModule.instance);
    reg('BleModule', BleModule.instance);
    reg('TimeModule', TimeModule());
    reg('HiveStorageModule', HiveStorageModule());
    reg('SecureStorageModule', SecureStorageModule());
  }
}
