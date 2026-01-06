
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

    register('curved', NativeFunction('Animation.curved', 2, (args) {
      final parentArg = args[0];
      final curveName = args[1].toString();

      Animation<double>? parent;

      if (parentArg is Map && parentArg.containsKey('__native__')) {
        final nativeObj = parentArg['__native__'];
        if (nativeObj is FluxAnimationController) {
          parent = nativeObj.native;
        } else if (nativeObj is FluxAnimation) {
          final anim = nativeObj.native;
          if (anim is Animation<double>) {
            parent = anim;
          }
        }
      }

      if (parent == null) {
        throw 'Animation.curved requires an AnimationController or Animation<double>';
      }

      final curve = _getCurve(curveName);
      final curvedAnim = CurvedAnimation(parent: parent, curve: curve);
      return {
        '__native__': FluxAnimation(curvedAnim),
        'value': FluxAnimation(curvedAnim),
      };
    }));

    register('tween', NativeFunction('Animation.tween', 2, (args) {
      final begin = (args[0] as num).toDouble();
      final end = (args[1] as num).toDouble();
      
      final tween = Tween<double>(begin: begin, end: end);

      return {
        'animate': NativeFunction('Tween.animate', 1, (args) {
          final parentArg = args[0];
          Animation<double>? parent;
          
          if (parentArg is Map && parentArg.containsKey('__native__')) {
            final nativeObj = parentArg['__native__'];
            if (nativeObj is FluxAnimationController) {
              parent = nativeObj.native;
            } else if (nativeObj is FluxAnimation) {
               final anim = nativeObj.native;
               if (anim is Animation<double>) {
                 parent = anim;
               }
            }
          }

          if (parent == null) {
            throw 'Tween.animate requires an Animation parent';
          }

          final anim = tween.animate(parent);
          return FluxAnimation(anim);
        }),
      };
    }));
  }

  Curve _getCurve(String name) {
    switch (name) {
      case 'linear': return Curves.linear;
      case 'decelerate': return Curves.decelerate;
      case 'ease': return Curves.ease;
      case 'easeIn': return Curves.easeIn;
      case 'easeOut': return Curves.easeOut;
      case 'easeInOut': return Curves.easeInOut;
      case 'slowMiddle': return Curves.slowMiddle;
      case 'bounceIn': return Curves.bounceIn;
      case 'bounceOut': return Curves.bounceOut;
      case 'bounceInOut': return Curves.bounceInOut;
      case 'elasticIn': return Curves.elasticIn;
      case 'elasticOut': return Curves.elasticOut;
      case 'elasticInOut': return Curves.elasticInOut;
      default: return Curves.linear;
    }
  }

  int? _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
