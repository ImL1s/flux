import 'dart:convert';
import 'dart:developer';
import 'package:flux_vm/flux_vm.dart';

/// Registers Flux specific service extensions for DevTools integration.
class FluxServiceExtensions {
  static bool _registered = false;

  /// Registers extensions. Should be called once per app life-cycle ideally,
  /// or handled to avoid duplicate verification.
  static void register(FluxVM vm) {
    if (_registered) return;
    _registered = true;

    // 1. Get Version
    registerExtension('ext.flux.getVersion', (method, parameters) async {
      return ServiceExtensionResponse.result(jsonEncode({
        'type': 'FluxVersion',
        'version': '2.0.0',
        'details': 'Flux V2.0 with DevTools Support'
      }));
    });

    // 2. Eval (Placeholder)
    registerExtension('ext.flux.eval', (method, parameters) async {
      final expr = parameters['expr'];
      // TODO: Implement evaluation using VM
      return ServiceExtensionResponse.result(jsonEncode({
        'type': 'EvalResult',
        'result': 'Eval not implemented yet for: $expr'
      }));
    });

    // 3. Get Status
    registerExtension('ext.flux.getStatus', (method, parameters) async {
      final isPaused = vm.debugger?.isPaused ?? false;
      String? pausedScript;
      int? pausedLine;
      
      if (isPaused) {
        // We need a way to get current location from VM or Debugger
        // Debugger._createContext() creates stack frames.
        // For simplicity, let's expose a helper in VM or just check frames.
        if (vm.frames.isNotEmpty) {
           final frame = vm.frames.last;
           pausedScript = frame.closure.function.moduleName;
           pausedLine = frame.chunk.getLine(frame.ip);
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
    });

    // 4. Get Scripts
    registerExtension('ext.flux.getScripts', (method, parameters) async {
      final scripts = vm.scripts.values.map((s) => {
        'name': s.name,
        'source': s.source,
      }).toList();
      
      return ServiceExtensionResponse.result(jsonEncode({
        'type': 'ScriptList',
        'scripts': scripts,
      }));
    });

    // 5. Pause
    registerExtension('ext.flux.pause', (method, parameters) async {
      vm.debugger?.pause();
      return ServiceExtensionResponse.result(jsonEncode({'success': true}));
    });

    // 6. Resume
    registerExtension('ext.flux.resume', (method, parameters) async {
      vm.resume();
      return ServiceExtensionResponse.result(jsonEncode({'success': true}));
    });

    // 7. Add Breakpoint
    registerExtension('ext.flux.addBreakpoint', (method, parameters) async {
      final script = parameters['script'];
      final lineStr = parameters['line'];
      int? id;
      if (script != null && lineStr != null) {
        final bp = vm.debugger?.setBreakpoint(script, int.parse(lineStr));
        id = bp?.id;
      }
      return ServiceExtensionResponse.result(jsonEncode({'success': true, 'id': id}));
    });

    // 8. Remove Breakpoint
    registerExtension('ext.flux.removeBreakpoint', (method, parameters) async {
       // Need ID or Script+Line. 
       // For simplicity MVP: pass script+line and find it, or modify API to return ID upon add.
       // Current FluxDebugger.setBreakpoint returns Breakpoint with ID.
       // UI should store ID. 
       // For now, let's implement remove by ID.
       final idStr = parameters['id'];
       if (idStr != null) {
         vm.debugger?.removeBreakpoint(int.parse(idStr));
       }
       return ServiceExtensionResponse.result(jsonEncode({'success': true}));
    });

    // 9. Step
    registerExtension('ext.flux.step', (method, parameters) async {
       final mode = parameters['mode']; // into, over, out
       if (mode == 'into') vm.debugger?.stepInto();
       else if (mode == 'over') vm.debugger?.stepOver();
       else if (mode == 'out') vm.debugger?.stepOut();
       
       // Step commands in debugger set state but don't resume VM automatically?
       // FluxDebugger.stepInto() sets _stepMode and _paused=false and calls _notifyListeners(resumed).
       // But it doesn't call vm.run().
       // So we must manually call vm.resume() after setting step mode.
       vm.resume();
       
       return ServiceExtensionResponse.result(jsonEncode({'success': true}));
    });
    
    // Setup Listener
    vm.debugger?.addListener((event, context) {
      postEvent('Flux.Debug', {
        'event': event.name,
        'script': context.source,
        'line': context.line,
        'stack': context.stackFrames.map((f) => f.toString()).toList(),
      });
    });
    
    log('Flux Service Extensions registered', name: 'Flux');
  }
}
