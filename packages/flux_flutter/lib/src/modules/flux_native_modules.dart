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
    try { vm.registerModule(HttpModule()); } catch (e) { print('Failed to register HttpModule: $e'); }
    try { vm.registerModule(StorageModule()); } catch (e) { print('Failed to register StorageModule: $e'); }
    try { vm.registerModule(DialogModule()); } catch (e) { print('Failed to register DialogModule: $e'); }
    try { vm.registerModule(DeviceInfoModule()); } catch (e) { print('Failed to register DeviceInfoModule: $e'); }
    try { vm.registerModule(NavigationModule()); } catch (e) { print('Failed to register NavigationModule: $e'); }
    try { vm.registerModule(CameraModule.instance); } catch (e) { print('Failed to register CameraModule: $e'); }
    try { vm.registerModule(BleModule.instance); } catch (e) { print('Failed to register BleModule: $e'); }
    try { vm.registerModule(TimeModule()); } catch (e) { print('Failed to register TimeModule: $e'); }
    try { vm.registerModule(HiveStorageModule()); } catch (e) { print('Failed to register HiveStorageModule: $e'); }
    try { vm.registerModule(SecureStorageModule()); } catch (e) { print('Failed to register SecureStorageModule: $e'); }
  }
}
