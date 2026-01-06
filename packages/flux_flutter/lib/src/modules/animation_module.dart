
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flux_vm/flux_vm.dart';

/// Base class for animation objects exposed to Flux
abstract class FluxAnimationBase extends Listenable {
  dynamic get value;
}

/// A wrapper for Flutter's [AnimationController] that can be accessed from Flux
class FluxAnimationController extends FluxAnimationBase {
  final AnimationController native;

  FluxAnimationController(this.native);

  @override
  void addListener(VoidCallback listener) => native.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => native.removeListener(listener);

  @override
  dynamic get value => native.value;

  void forward() => native.forward();
  void reverse() => native.reverse();
  void stop() => native.stop();
  void repeat({bool reverse = false}) => native.repeat(reverse: reverse);
  void reset() => native.reset();
  
  void animateTo(double target) {
    native.animateTo(target);
  }

  void dispose() => native.dispose();
}

/// A wrapper for Flutter's [Animation] (e.g. from Tween) that can be accessed from Flux
class FluxAnimation extends FluxAnimationBase {
  final Animation native;

  FluxAnimation(this.native);

  @override
  void addListener(VoidCallback listener) => native.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => native.removeListener(listener);

  @override
  dynamic get value => native.value;
}

/// The Animation module for Flux
class AnimationModule extends FluxModule {
  final TickerProvider vsync;

  AnimationModule(this.vsync) : super('Animation') {
    _init();
  }

  void _init() {
    register('createController', NativeFunction('Animation.createController', -1, (args) {
      final duration = args.isNotEmpty ? _asInt(args[0]) ?? 300 : 300;
      
      final controller = AnimationController(
        vsync: vsync,
        duration: Duration(milliseconds: duration),
      );

      final fluxController = FluxAnimationController(controller);

      return {
        'forward': NativeFunction('AnimationController.forward', 0, (_) {
          fluxController.forward();
          return null;
        }),
        'reverse': NativeFunction('AnimationController.reverse', 0, (_) {
          fluxController.reverse();
          return null;
        }),
        'stop': NativeFunction('AnimationController.stop', 0, (_) {
          fluxController.stop();
          return null;
        }),
        'repeat': NativeFunction('AnimationController.repeat', 0, (_) {
          fluxController.repeat();
          return null;
        }),
        'reset': NativeFunction('AnimationController.reset', 0, (_) {
          fluxController.reset();
          return null;
        }),
        'value': fluxController,
        '__native__': fluxController,
      };
    }));

    register('tween', NativeFunction('Animation.tween', 2, (args) {
      final begin = (args[0] as num).toDouble();
      final end = (args[1] as num).toDouble();
      
      final tween = Tween<double>(begin: begin, end: end);

      return {
        'animate': NativeFunction('Tween.animate', 1, (args) {
          final controllerArg = args[0];
          AnimationController? nativeController;
          
          if (controllerArg is Map && controllerArg.containsKey('__native__')) {
            final nativeObj = controllerArg['__native__'];
            if (nativeObj is FluxAnimationController) {
              nativeController = nativeObj.native;
            }
          }

          if (nativeController == null) {
            throw 'Tween.animate requires an AnimationController';
          }

          final anim = tween.animate(nativeController);
          return FluxAnimation(anim);
        }),
      };
    }));
  }

  int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
