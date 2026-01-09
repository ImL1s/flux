import 'package:flux_vm/flux_vm.dart';
import '../modules/ble_module.dart';

/// Bluetooth Low Energy (BLE) plugin for Flux.
class BlePlugin extends FluxPlugin {
  final BleModule _module;

  BlePlugin([BleModule? module]) : _module = module ?? BleModule.instance;

  @override
  String get id => 'flux.plugin.ble';

  @override
  String get name => 'Bluetooth Low Energy';

  @override
  String get version => '1.0.0';

  @override
  List<String> get permissions => [FluxPermissions.ble];

  @override
  void onLoad(VM vm) {
    vm.setGlobal('ble', _module);
  }

  @override
  void onUnload(VM vm) {
    // Optional cleanup
  }
}
