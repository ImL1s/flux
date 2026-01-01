import 'package:flux_vm/flux_vm.dart';
import 'package:flux_flutter/src/modules/http_module.dart';
import 'package:flux_flutter/src/modules/storage_module.dart';

import 'package:flux_flutter/src/modules/device_info_module.dart';
import 'package:flux_flutter/src/modules/dialog_module.dart';

/// Registry for Flux native modules that depend on Flutter/Dart ecosystem
class FluxNativeModules {
  /// Register all available native modules with the VM
  static void register(VM vm) {
    vm.registerModule(HttpModule());
    vm.registerModule(StorageModule());
    vm.registerModule(DeviceInfoModule());
    vm.registerModule(DialogModule());
  }
}
