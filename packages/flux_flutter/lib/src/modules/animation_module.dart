
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
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

    register('colorTween', NativeFunction('Animation.colorTween', 2, (args) {
      final beginHex = args[0].toString();
      final endHex = args[1].toString();
      
      final tween = ColorTween(
        begin: _parseColor(beginHex),
        end: _parseColor(endHex),
      );

      return {
        'animate': NativeFunction('ColorTween.animate', 1, (args) {
          final parent = _extractAnimation(args[0]);
          if (parent == null) {
            throw 'ColorTween.animate requires an Animation parent';
          }
          final anim = tween.animate(parent);
          return FluxAnimation(anim);
        }),
      };
    }));

    register('sizeTween', NativeFunction('Animation.sizeTween', 2, (args) {
      final begin = args[0] as Map;
      final end = args[1] as Map;
      
      final tween = SizeTween(
        begin: Size((begin['width'] as num).toDouble(), (begin['height'] as num).toDouble()),
        end: Size((end['width'] as num).toDouble(), (end['height'] as num).toDouble()),
      );

      return {
        'animate': NativeFunction('SizeTween.animate', 1, (args) {
          final parent = _extractAnimation(args[0]);
          if (parent == null) {
            throw 'SizeTween.animate requires an Animation parent';
          }
          final anim = tween.animate(parent);
          return FluxAnimation(anim);
        }),
      };
    }));

    register('spring', NativeFunction('Animation.spring', 1, (args) {
      final parent = args[0] as Map;
      final parentController = _extractController(parent);
      if (parentController == null) {
        throw 'Animation.spring requires an AnimationController';
      }

      final mass = 1.0;
      final stiffness = 100.0;
      final damping = 10.0;

      final spring = SpringSimulation(
        SpringDescription(
          mass: mass,
          stiffness: stiffness,
          damping: damping,
        ),
        0.0,
        1.0,
        0.0,
      );

      parentController.animateWith(spring);
      return null;
    }));

    register('stagger', NativeFunction('Animation.stagger', 3, (args) {
      final animations = args[0] as List;
      final delayMs = (args[1] as num).toInt();
      final durationMs = (args[2] as num).toInt();

      final results = [];
      for (var i = 0; i < animations.length; i++) {
        final anim = animations[i];
        if (anim is Map && anim.containsKey('__native__')) {
          final controller = _extractController(anim);
          if (controller != null) {
            if (durationMs > 0) {
              controller.duration = Duration(milliseconds: durationMs);
            }
            final delay = Duration(milliseconds: delayMs * i);
            Future.delayed(delay, () {
              controller.forward();
            });
            results.add(anim);
          }
        }
      }
      return results;
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
      case 'easeInBack': return Curves.easeInBack;
      case 'easeOutBack': return Curves.easeOutBack;
      case 'easeInOutBack': return Curves.easeInOutBack;
      case 'fastOutSlowIn': return Curves.fastOutSlowIn;
      case 'fastLinearToSlowEaseIn': return Curves.fastLinearToSlowEaseIn;
      case 'fastEaseInToSlowEaseOut': return Curves.fastEaseInToSlowEaseOut;
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

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }

  Animation<double>? _extractAnimation(dynamic arg) {
    if (arg is Map && arg.containsKey('__native__')) {
      final nativeObj = arg['__native__'];
      if (nativeObj is FluxAnimationController) {
        return nativeObj.native;
      } else if (nativeObj is FluxAnimation) {
        final anim = nativeObj.native;
        if (anim is Animation<double>) {
          return anim;
        }
      }
    }
    return null;
  }

  AnimationController? _extractController(dynamic arg) {
    if (arg is Map && arg.containsKey('__native__')) {
      final nativeObj = arg['__native__'];
      if (nativeObj is FluxAnimationController) {
        return nativeObj.native;
      }
    }
    return null;
  }
}
