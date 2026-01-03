import 'package:flutter/foundation.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_flutter/src/modules/http_module.dart';
import 'package:flux_flutter/src/modules/storage_module.dart';
import 'package:flux_flutter/src/modules/dialog_module.dart';
import 'package:flux_flutter/src/modules/navigation_module.dart';
import 'package:flux_flutter/src/modules/camera_module.dart';

// Conditional import: use stub in web, real module in io environments
import 'package:flux_flutter/src/modules/device_info_module_stub.dart'
    if (dart.library.io) 'package:flux_flutter/src/modules/device_info_module.dart';

/// Registry for Flux native modules that depend on Flutter/Dart ecosystem
class FluxNativeModules {
  /// Register all available native modules with the VM
  static void register(VM vm) {
    vm.registerModule(HttpModule());
    vm.registerModule(StorageModule());
    vm.registerModule(DialogModule());
    vm.registerModule(DeviceInfoModule());
    vm.registerModule(NavigationModule());
    vm.registerModule(CameraModule.instance);
  }
}
