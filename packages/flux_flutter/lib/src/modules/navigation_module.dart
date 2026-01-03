import 'package:flutter/material.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_flutter/src/flux_context.dart';

/// Navigation module for Flux
/// 
/// Usage:
/// navigation.push("/details");
/// navigation.pop();
/// navigation.replace("/home");
class NavigationModule extends FluxModule {
  NavigationModule() : super('navigation') {
    register('push', NativeFunction('navigation.push', 1, _push));
    register('pop', NativeFunction('navigation.pop', 0, _pop));
    register('replace', NativeFunction('navigation.replace', 1, _replace));
    register('canPop', NativeFunction('navigation.canPop', 0, _canPop));
  }

  Object? _push(List<Object?> args) {
    final route = args[0] as String;
    final context = fluxNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('Flux NavigationModule: No context available for push.');
      return false;
    }
    
    Navigator.of(context).pushNamed(route);
    return true;
  }

  Object? _pop(List<Object?> args) {
    final context = fluxNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('Flux NavigationModule: No context available for pop.');
      return false;
    }
    
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return true;
    }
    return false;
  }

  Object? _replace(List<Object?> args) {
    final route = args[0] as String;
    final context = fluxNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('Flux NavigationModule: No context available for replace.');
      return false;
    }
    
    Navigator.of(context).pushReplacementNamed(route);
    return true;
  }
  
  Object? _canPop(List<Object?> args) {
    final context = fluxNavigatorKey.currentContext;
    if (context == null) {
      return false;
    }
    return Navigator.of(context).canPop();
  }
}
