import 'package:flux_vm/flux_vm.dart';

class TimeModule extends FluxModule {
  TimeModule() : super('DateTime') {
    register('now', NativeFunction('DateTime.now', 0, (args) {
      return DateTime.now().millisecondsSinceEpoch;
    }));
    register('nowString', NativeFunction('DateTime.nowString', 0, (args) {
      return DateTime.now().toIso8601String();
    }));
  }
}
