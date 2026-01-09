import 'package:flux_vm/flux_vm.dart';
import '../modules/camera_module.dart';

/// Camera plugin for Flux.
class CameraPlugin extends FluxPlugin {
  final CameraModule _module;

  CameraPlugin([CameraModule? module]) : _module = module ?? CameraModule.instance;

  @override
  String get id => 'flux.plugin.camera';

  @override
  String get name => 'Camera';

  @override
  String get version => '1.0.0';

  @override
  List<String> get permissions => [FluxPermissions.camera];

  @override
  void onLoad(VM vm) {
    vm.setGlobal('camera', _module);
  }

  @override
  void onUnload(VM vm) {
    _module.dispose([]);
  }
}
