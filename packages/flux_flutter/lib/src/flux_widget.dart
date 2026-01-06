import 'package:flutter/material.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'bindings.dart';
import 'dev_tools/flux_service_extensions.dart';
import 'modules/flux_native_modules.dart';
import 'modules/animation_module.dart';


/// A Flutter widget that executes and renders a Flux widget definition.
///
/// Example usage:
/// ```dart
/// FluxWidget(
///   source: '''
///     widget MyWidget {
///       build {
///         Column {
///           Text("Hello from Flux!")
///         }
///       }
///     }
///   ''',
///   widgetName: 'MyWidget',
/// )
/// ```
class FluxWidget extends StatefulWidget {
  /// The Flux source code containing widget definitions
  final String? source; // Made nullable to support runtime-only

  /// The name of the widget to render from the source
  final String widgetName;

  /// Optional initial state values
  final Map<String, dynamic>? initialState;

  /// Optional external runtime
  final FluxRuntime? runtime;

  const FluxWidget({
    super.key,
    this.source,
    required this.widgetName,
    this.initialState,
    this.runtime,
  }) : assert(source != null || runtime != null,
            'Either source or runtime must be provided');

  @override
  State<FluxWidget> createState() => _FluxWidgetState();
}

class _FluxWidgetState extends State<FluxWidget> with TickerProviderStateMixin {
  late FluxRuntime _runtime;
  Widget? _builtWidget;
  String? _error;

  @override
  void initState() {
    super.initState();
    FluxBindings.initDefaults();
    _initRuntime();
  }

  @override
  void didUpdateWidget(FluxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.widgetName != widget.widgetName ||
        oldWidget.runtime != widget.runtime) {
      _initRuntime();
    }
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  void _initRuntime() {
    try {
      if (widget.runtime != null) {
        _runtime = widget.runtime!;
        // Attach our state change listener to the external runtime's VM
        // This ensures widget rebuilds when state changes in the shared runtime
        _runtime._vm.onStateChange = _handleStateChange;
      } else {
        _runtime = FluxRuntime(
          widget.source!,
          onStateChange: _handleStateChange,
          moduleName: widget.widgetName,
          onRegisterModules: (vm) {
            FluxNativeModules.register(vm, this);
          },
        );
      }

      _buildWidget();
      _error = null;
    } catch (e) {
      setState(() {
        _error = e.toString();
        _builtWidget = null;
      });
    }
  }

  // NOTE: hotReload logic moved to FluxRuntime
  // ...

  /// Called when Flux state changes - triggers Flutter rebuild
  void _handleStateChange(String name, Object? value) {
    // Rebuild the widget tree when any state changes
    _buildWidget();
  }

  void _buildWidget() {
    // debugPrint('🔧 FluxWidget._buildWidget() START');
    try {
      final widgetDef = _runtime.getWidget(widget.widgetName);
      // debugPrint('🔧 Got widget definition: ${widgetDef?.name ?? "NULL"}');
      if (widgetDef == null) {
        throw Exception("Widget '${widget.widgetName}' not found in source.");
      }

      // Execute the build method and convert to Flutter widget
      // debugPrint('🔧 Executing build...');
      final fluxTree = _runtime.executeBuild(widgetDef);
      // debugPrint('🔧 executeBuild result: $fluxTree');

      // debugPrint('🔧 Converting to Flutter...');
      final flutterWidget = _runtime._convertToFlutter(fluxTree);
      // debugPrint('🔧 Converted widget: ${flutterWidget.runtimeType}');

      if (mounted) {
        setState(() {
          _builtWidget = flutterWidget;
          _error = null;
        });
      } else {
        _builtWidget = flutterWidget;
        _error = null;
      }
      // debugPrint('🔧 FluxWidget._buildWidget() SUCCESS');
    } catch (e, stackTrace) {
      debugPrint('❌ FluxWidget._buildWidget() ERROR: $e');
      debugPrint('❌ StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _builtWidget = null;
        });
      } else {
        _error = e.toString();
        _builtWidget = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          'Flux Error: $_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return _builtWidget ?? const Center(child: CircularProgressIndicator());
  }
}

/// Represents a widget node in the Flux widget tree
class FluxWidgetNode {
  final String name;
  final Map<String, dynamic> args;
  final List<dynamic> children;

  FluxWidgetNode(
    this.name, {
    this.args = const {},
    this.children = const [],
  });

  @override
  String toString() =>
      'FluxWidgetNode($name, args: $args, children: $children)';
}

/// Runtime for executing Flux code and managing widget state
class FluxRuntime {
  final VM _vm = VM();
  VM get vm => _vm; // Expose VM for module registration
  final Map<String, CompiledWidget> _widgets = {};

  /// Callback when state changes (for Flutter rebuild)
  final void Function(String name, Object? value)? onStateChange;

  // Widget constructor names that should create FluxWidgetNode
  static const _widgetConstructors = {
    'Text',
    'Column',
    'Row',
    'Container',
    'Button',
    'Center',
    'Padding',
    'SizedBox',
    'Icon',
    'Image',
    'ListView',
    'GridView',
    'Stack',
    'Positioned',
    'Expanded',
    'Flexible',
    'Card',
    'Scaffold',
    'AppBar',
    'FloatingActionButton',
    'TextField',
    'Checkbox',
  };

  // Stack for collecting children in nested widgets
  final List<List<FluxWidgetNode>> _childrenStack = [];

  FluxRuntime(String source,
      {this.onStateChange,
      String? moduleName,
      void Function(VM vm)? onRegisterModules}) {
    // Set up state change callback
    _vm.onStateChange = onStateChange;

    // Compile source
    debugPrint('DEBUG RUNTIME: Source: $source');
    final lexer = Lexer(source);
    final tokens = lexer.tokenize();
    final parser = Parser(tokens);
    final ast = parser.parse();
    debugPrint(
        'DEBUG RUNTIME: Parsed unit with ${ast.declarations.length} declarations');
    final compiler = Compiler(unit: ast, moduleName: moduleName);
    compiler.compile(ast.declarations[0]); // Compile script

    final function = compiler.endCompiler();
    debugPrint(
        'DEBUG RUNTIME: Compilation finished. Bytecode size: ${function.chunk.code.length}');

    // Register script for DevTools
    _vm.registerScript(moduleName ?? 'script_${source.hashCode}', function);

    // Inject widget names into globals so they can be resolved
    final allWidgetNames = {
      ..._widgetConstructors,
      ...FluxBindings.registeredWidgets
    };

    // Register DevTools extensions
    FluxServiceExtensions.register(_vm);
    for (final name in allWidgetNames) {
      _vm.globals[name] = name;
    }

    // Inject registered global functions
    for (final entry in FluxBindings.functions.entries) {
      _vm.globals[entry.key] = NativeFunction(entry.key, -1, (args) {
        return entry.value(args);
      });
    }

    // Set widget handler before initial execution
    _vm.widgetCallHandler = _handleWidgetCall;

    // Set coroutine resume callback for async/await support
    _vm.coroutineResumeCallback = _handleCoroutineResume;

    // 🚀 Register native modules BEFORE running the chunk
    // This allows state initialization to access native modules (like Animation)
    if (onRegisterModules != null) {
      onRegisterModules(_vm);
    }

    _vm.runChunk(function.chunk);

    // Extract widget definitions from globals
    for (final entry in _vm.globals.entries) {
      if (entry.value is CompiledWidget) {
        final widget = entry.value as CompiledWidget;
        _widgets[entry.key] = widget;

        // Initialize state for THIS widget if it hasn't been initialized
        // Note: For top-level widgets, this happens here.
        // For nested widgets, initialization happens in _handleWidgetCall.
        _initializeWidgetState(widget);
      }
    }
  }

  /// Hot reload the runtime with new code.
  ///
  /// This updates the widget definitions but keeps the state.
  void hotReload(Chunk newChunk) {
    debugPrint('🔥 FluxRuntime: Hot Reloading...');

    // 1. Capture old state
    final oldState = Map<String, Object?>.from(_vm.widgetState);

    // 2. Re-run the chunk to re-define global widget classes
    final result = _vm.runChunk(newChunk);
    if (result != InterpretResult.ok) {
      debugPrint('❌ FluxRuntime: Hot Reload failed during runChunk: $result');
      // Attempt to restore old state if possible
      _vm.widgetState.addAll(oldState);
      return;
    }

    // 3. Clear current state (so initializers run cleanly for new version)
    _vm.widgetState.clear();

    // 4. Update widget definitions and run initializers for the new version
    _widgets.clear(); // Clear cache to ensure we only have what's in the new chunk
    int widgetCount = 0;
    for (final entry in _vm.globals.entries) {
      if (entry.value is CompiledWidget) {
        final widget = entry.value as CompiledWidget;
        // Update cache
        _widgets[entry.key] = widget;
        widgetCount++;

        // Run initializer: this populates _vm.widgetState with V2 defaults
        _initializeWidgetState(widget);
      }
    }

    // 5. Restore old state (overwrite defaults with preserved values)
    _vm.widgetState.addAll(oldState);

    debugPrint('✅ Hot Reload Complete. Defined $widgetCount widgets: ${_widgets.keys.join(", ")}');

    // Notify listeners to force update
    _vm.onStateChange?.call('*', null);
  }

  void _initializeWidgetState(CompiledWidget widget) {
    for (int i = 0; i < widget.stateFields.length; i++) {
      final fieldName = widget.stateFields[i];
      if (_vm.widgetState.containsKey(fieldName)) continue;

      if (i < widget.stateInitializers.length) {
        _vm.runChunk(widget.stateInitializers[i].chunk);
        final initValue = _vm.stack.isNotEmpty ? _vm.stack.removeLast() : null;
        _vm.widgetState[fieldName] = initValue;
      } else {
        _vm.widgetState[fieldName] = null;
      }
    }
  }

  void dispose() {
    debugPrint('🗑️ FluxRuntime.dispose()');
    // Look for AnimationControllers in widgetState and dispose them
    for (final value in _vm.widgetState.values) {
      if (value is Map && value.containsKey('__native__')) {
        final native = value['__native__'];
        if (native is FluxAnimationController) {
          debugPrint('🗑️ Disposing FluxAnimationController in state');
          native.dispose();
        }
      }
    }
  }


  /// Handle coroutine resume callback from VM
  ///
  /// This is called when an awaited Future completes.
  /// Uses Flutter's event loop to schedule the resumption.
  void _handleCoroutineResume(
      FluxCoroutine coroutine, Object? result, Object? error) {
    debugPrint(
        'DEBUG COROUTINE: _handleCoroutineResume called, result=$result, error=$error');

    // Use scheduleMicrotask for faster response in tests
    // (addPostFrameCallback requires widget tree pumping)
    Future.microtask(() {
      debugPrint('DEBUG COROUTINE: Resuming coroutine ${coroutine.id}');
      if (error != null) {
        // Resume with error
        _vm.resumeCoroutineWithError(coroutine, error);
      } else {
        // Resume with result
        final interpretResult = _vm.resumeCoroutine(coroutine, result);
        debugPrint('DEBUG COROUTINE: Resume result: $interpretResult');

        // If execution completed successfully, trigger UI rebuild
        if (interpretResult == InterpretResult.ok && onStateChange != null) {
          onStateChange!('_coroutine_complete', result);
        }
      }
    });
  }

  CompiledWidget? getWidget(String name) {
    return _widgets[name];
  }

  Widget renderWidget(String name, [Map<String, dynamic> args = const {}]) {
    final widget = getWidget(name);
    if (widget == null) return Text('Widget not found: $name');

    final node = executeBuild(widget, args);
    debugPrint('DEBUG renderWidget: node=$node');
    return _convertToFlutter(node);
  }

  FluxWidgetNode executeBuild(CompiledWidget widget,
      [Map<String, dynamic> args = const {}]) {
    // Set up widget call handler to intercept widget constructor calls
    _vm.widgetCallHandler = _handleWidgetCall;

    // Use executeClosure for the buildMethod
    final closure = ObjClosure(widget.buildMethod, []);

    // Map props from args map to positional arguments based on paramNames
    final positionalArgs = <Object?>[];
    final paramNames = widget.buildMethod.paramNames;
    for (final name in paramNames) {
      positionalArgs.add(args[name]);
    }

    FluxWidgetNode? builtNode;
    
    // Push a new children collector to ensure isolation during build
    _childrenStack.add([]);
    
    try {
      final interpretResult = _vm.executeClosure(closure, positionalArgs);

      // Clean up handler
      _vm.widgetCallHandler = null;

      if (interpretResult == InterpretResult.paused) {
        _childrenStack.removeLast();
        return FluxWidgetNode('Text',
            args: {'0': 'Paused at Breakpoint (Resume in DevTools)'});
      } else if (interpretResult != InterpretResult.ok) {
        // If execution failed, the stack might not contain a FluxWidgetNode
        _vm.stack.clear();
        _childrenStack.removeLast();
        return FluxWidgetNode('Error', args: {'text': 'Build error'});
      }

      // Get result from stack (build returns a value)
      if (_vm.stack.isEmpty) {
        debugPrint('⚠️ FluxRuntime: VM stack is EMPTY after build execution!');
      } else {
        final result = _vm.stack.removeLast();
        debugPrint('🔧 Result from stack: $result (Type: ${result.runtimeType})');
        if (result is FluxWidgetNode) {
          builtNode = result;
        } else {
           debugPrint('⚠️ FluxRuntime: Result is NOT a FluxWidgetNode: $result');
        }
      }
    } catch (e, st) {
      debugPrint('❌ Flux runtime error during build: $e');
      debugPrint('❌ stacktrace: $st');
    } finally {
      _childrenStack.removeLast();
    }

    if (builtNode != null) {
      return builtNode;
    }

    // Fallback
    final fallback = FluxWidgetNode(
      'Text',
      args: {'0': 'Build returned: $builtNode'},
    );
    debugPrint('⚠️ FluxRuntime: Returning fallback: $fallback');
    return fallback;
  }

  Widget _convertToFlutter(dynamic fluxNode) {
    if (fluxNode is FluxWidgetNode) {
      final builder = FluxBindings.get(fluxNode.name);
      if (builder == null) {
        return Text('Unknown widget: ${fluxNode.name}');
      }

      final children =
          fluxNode.children.map((child) => _convertToFlutter(child)).toList();

      // Process args: convert FluxWidgetNode to Flutter Widget, wrap closures
      final processedArgs = <String, dynamic>{};
      for (final key in fluxNode.args.keys) {
        final value = fluxNode.args[key];
        if (value is FluxWidgetNode) {
          // Recursively convert nested FluxWidgetNode to Flutter Widget
          processedArgs[key] = _convertToFlutter(value);
        } else if (value is List) {
          // Handle list args (e.g., children: [...])
          processedArgs[key] = value.map((item) {
            if (item is FluxWidgetNode) {
              return _convertToFlutter(item);
            }
            return item;
          }).toList();
        } else if (value is ObjClosure) {
          processedArgs[key] = (List<Object?> callArgs) {
            // Execute closure on the VM
            debugPrint(
                'DEBUG CLOSURE: Executing $key closure, args=${callArgs.length}');
            final result = _vm.executeClosure(value, callArgs);
            debugPrint('DEBUG CLOSURE: $key closure returned $result');
            // Trigger state change notification to rebuild widget
            // This ensures list mutations (push, pop, etc.) cause UI updates
            onStateChange?.call('_closure_complete', null);
          };
        } else {
          processedArgs[key] = value;
        }
      }

      // 3. Check for animation dependencies in processedArgs
      final anims = <Listenable>[];
      processedArgs.forEach((k, v) {
        if (v is Listenable) {
          anims.add(v);
        } else if (v is Map &&
            v.containsKey('__native__') &&
            v['__native__'] is Listenable) {
          anims.add(v['__native__'] as Listenable);
        }
      });

      if (anims.isEmpty) {
        return builder(processedArgs, children);
      }

      // If we have animations, wrap in ListenableBuilder for reactive updates
      return ListenableBuilder(
        listenable: Listenable.merge(anims),
        builder: (context, _) {
          return builder(processedArgs, children);
        },
      );
    }

    // Fallback for primitives (e.g., strings become Text)
    if (fluxNode is String) {
      return Text(fluxNode);
    }

    return ErrorWidget(Exception("Cannot convert $fluxNode to Widget"));
  }

  /// Handle widget constructor calls during build execution
  Object? _handleWidgetCall(Object? callee, int argCount,
      Map<String, dynamic> namedArgs, List<Object?> stack) {
    // Check if this is a widget constructor call or a user-defined widget
    // Check both static list AND dynamically registered bindings
    final isBuiltin = callee is String &&
        (_widgetConstructors.contains(callee) ||
            FluxBindings.get(callee) != null);
    final isCustom = callee is CompiledWidget;

    if (isBuiltin || isCustom) {
      final name = isBuiltin ? callee : (callee as CompiledWidget).name;

      // Build arguments map
      final args = Map<String, dynamic>.from(namedArgs);
      final children = <FluxWidgetNode>[];

      // Pop positional arguments from stack (in reverse order)
      for (int i = argCount - 1; i >= 0; i--) {
        if (stack.isEmpty) break;
        final arg = stack.removeLast();

        if (arg is FluxWidgetNode) {
          children.insert(0, arg);
        } else {
          args['$i'] = arg;
        }
      }

      // CLEANUP: Remove any widgets passed as arguments from the parent collector.
      // If a widget was created as an argument (e.g. child: Text(...)), it was
      // inadvertently added to the parent's children list. We must remove it
      // because it's being consumed as an argument here.
      if (_childrenStack.isNotEmpty) {
        final parentCollector = _childrenStack.last;

        void removeFromCollector(dynamic value) {
          if (value is FluxWidgetNode) {
            parentCollector.remove(value);
          } else if (value is List) {
            for (final item in value) {
              removeFromCollector(item);
            }
          } else if (value is Map) {
            for (final item in value.values) {
              removeFromCollector(item);
            }
          }
        }

        for (final arg in args.values) {
          removeFromCollector(arg);
        }
      }

      // Special handling for builder closures (trailing blocks)
      if (args.containsKey('_children')) {
        final builder = args.remove('_children');
        if (builder is ObjClosure) {
          // Execute closure to generate children
          _childrenStack.add([]); // Push new collector
          // Use invokeClosure to execute on current stack (preserving upvalues)
          _vm.invokeClosure(builder);
          children.addAll(_childrenStack.removeLast());
          
          // CRITICAL: invokeClosure leaves its result (usually null for trailing blocks) 
          // on the VM stack. Since we collect results via _childrenStack, we MUST 
          // pop this redundant result to keep the stack balanced for the caller.
          if (stack.isNotEmpty) {
            stack.removeLast();
          }
        }
      }

      // Pop the callee (widget name string or CompiledWidget)
      if (stack.isNotEmpty) {
        stack.removeLast();
      }

      // Create node
      FluxWidgetNode node;
      if (isCustom) {
        // Recursive build for custom widgets
        node = executeBuild(callee, args);
      } else {
        node = FluxWidgetNode(name, args: args, children: children);
      }

      // Add to parent collector if exists
      if (_childrenStack.isNotEmpty) {
        _childrenStack.last.add(node);
      }

      // Push result to stack so VM is happy
      stack.add(node);
      return node;
    }

    // Not a widget call
    return null;
  }
}
