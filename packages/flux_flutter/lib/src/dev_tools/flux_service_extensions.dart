import 'dart:convert';
import 'dart:developer';
import 'package:flux_vm/flux_vm.dart';

/// Registers Flux specific service extensions for DevTools integration.
class FluxServiceExtensions {
  static bool _registered = false;

  /// Registers extensions. Should be called once per app life-cycle ideally,
  /// or handled to avoid duplicate verification.
  static void register(VM vm) {
    if (_registered) return;
    _registered = true;

    // 1. Get Version
    registerExtension('ext.flux.getVersion', (method, parameters) => 
        FluxServiceExtensionHandlers.getVersion(vm, parameters));

    // 2. Eval
    registerExtension('ext.flux.eval', (method, parameters) => 
        FluxServiceExtensionHandlers.eval(vm, parameters));

    // 3. Get Status
    registerExtension('ext.flux.getStatus', (method, parameters) => 
        FluxServiceExtensionHandlers.getStatus(vm, parameters));
    
    // ... existing getScripts ...
    
    // 10. Get Stack
    registerExtension('ext.flux.getStack', (method, parameters) => 
        FluxServiceExtensionHandlers.getStack(vm, parameters));

    // 11. Get Locals
    registerExtension('ext.flux.getLocals', (method, parameters) => 
        FluxServiceExtensionHandlers.getLocals(vm, parameters));

    // Setup Listener
    vm.debugger?.addListener((event, context) {
      postEvent('Flux.Debug', {
        'event': event.name,
        'script': context.source,
        'line': context.line,
      });
    });
    
    log('Flux Service Extensions registered', name: 'Flux');
  }
}

/// Testable handlers for Flux service extensions
class FluxServiceExtensionHandlers {
  
  static Future<ServiceExtensionResponse> getVersion(VM vm, Map<String, String> parameters) async {
      return ServiceExtensionResponse.result(jsonEncode({
        'type': 'FluxVersion',
        'version': '2.0.0',
        'details': 'Flux V2.0 with DevTools Support'
      }));
  }

  static Future<ServiceExtensionResponse> eval(VM vm, Map<String, String> parameters) async {
      final expr = parameters['expr'];
      final frameIndexStr = parameters['frameIndex'];
      final frameIndex = frameIndexStr != null ? int.tryParse(frameIndexStr) : 0;
      
      if (expr == null) {
        return ServiceExtensionResponse.error(
          ServiceExtensionResponse.invalidParams, 
          'Expression "expr" is required'
        );
      }

      try {
        final result = vm.debugger?.evaluate(expr, frameIndex: frameIndex ?? 0);
        final isError = result is String && result.startsWith('Error: ');
        
        return ServiceExtensionResponse.result(jsonEncode({
          'type': 'EvalResult',
          'result': result.toString(),
          'isError': isError
        }));
      } catch (e) {
        return ServiceExtensionResponse.result(jsonEncode({
          'type': 'EvalResult',
          'result': e.toString(),
          'isError': true
        }));
      }
  }

  static Future<ServiceExtensionResponse> getStatus(VM vm, Map<String, String> parameters) async {
      final isPaused = vm.debugger?.isPaused ?? false;
      String? pausedScript;
      int? pausedLine;
      
      if (isPaused) {
        final stack = vm.debugger?.getCallStack() ?? [];
        if (stack.isNotEmpty) {
           final top = stack.first;
           pausedScript = top.source;
           pausedLine = top.line;
        }
      }

      return ServiceExtensionResponse.result(jsonEncode({
        'type': 'FluxStatus',
        'vmState': isPaused ? 'Paused' : 'Running',
        'debuggerAttached': vm.debugger != null,
        'isPaused': isPaused,
        'pausedScript': pausedScript,
        'pausedLine': pausedLine,
      }));
  }

  static Future<ServiceExtensionResponse> getStack(VM vm, Map<String, String> parameters) async {
      final frames = vm.debugger?.getCallStack() ?? [];
      final framesJson = <Map<String, dynamic>>[];
      
      for (var i = 0; i < frames.length; i++) {
        final f = frames[i];
        framesJson.add({
          'index': i,
          'function': f.functionName,
          'script': f.source,
          'line': f.line,
        });
      }
      
      return ServiceExtensionResponse.result(jsonEncode({
        'type': 'Stack',
        'frames': framesJson,
      }));
  }

  static Future<ServiceExtensionResponse> getLocals(VM vm, Map<String, String> parameters) async {
      final frameIndexStr = parameters['frameIndex'];
      final frameIndex = frameIndexStr != null ? int.tryParse(frameIndexStr) ?? 0 : 0;
      
      final locals = vm.debugger?.getLocals(frameIndex) ?? {};
      final safeLocals = <String, String>{};
      locals.forEach((key, value) {
        safeLocals[key] = value.toString();
      });
      
      return ServiceExtensionResponse.result(jsonEncode({
        'type': 'Locals',
        'locals': safeLocals,
      }));
  }
}

