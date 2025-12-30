import 'package:flutter/material.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'bindings.dart';

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
  final String source;
  
  /// The name of the widget to render from the source
  final String widgetName;
  
  /// Optional initial state values
  final Map<String, dynamic>? initialState;

  const FluxWidget({
    super.key,
    required this.source,
    required this.widgetName,
    this.initialState,
  });

  @override
  State<FluxWidget> createState() => _FluxWidgetState();
}

class _FluxWidgetState extends State<FluxWidget> {
  late FluxRuntime _runtime;
  Widget? _builtWidget;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    FluxBindings.initDefaults();
    _compile();
  }
  
  @override
  void didUpdateWidget(FluxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source || 
        oldWidget.widgetName != widget.widgetName) {
      _compile();
    }
  }
  
  void _compile() {
    try {
      _runtime = FluxRuntime(
        widget.source,
        onStateChange: _handleStateChange,
      );
      _buildWidget();
      _error = null;
    } catch (e) {
      setState(() {
        _error = e.toString();
        _builtWidget = null;
      });
    }
  }
  
  /// Hot reload with new source code, preserving widget state
  void hotReload(String newSource, {bool preserveState = true}) {
    try {
      // Save current state if preserving
      final savedState = preserveState 
          ? Map<String, Object?>.from(_runtime._vm.widgetState)
          : <String, Object?>{};
      
      // Recompile with new source
      _runtime = FluxRuntime(
        newSource,
        onStateChange: _handleStateChange,
      );
      
      // Restore state if preserving
      if (preserveState) {
        _runtime._vm.widgetState.addAll(savedState);
      }
      
      // Rebuild widget
      _buildWidget();
      _error = null;
    } catch (e) {
      setState(() {
        _error = 'Hot reload failed: $e';
      });
    }
  }
  
  /// Called when Flux state changes - triggers Flutter rebuild
  void _handleStateChange(String name, Object? value) {
    // Rebuild the widget tree when any state changes
    _buildWidget();
  }
  
  void _buildWidget() {
    try {
      final widgetDef = _runtime.getWidget(widget.widgetName);
      if (widgetDef == null) {
        throw Exception("Widget '${widget.widgetName}' not found in source.");
      }
      
      // Execute the build method and convert to Flutter widget
      final fluxTree = _runtime.executeBuild(widgetDef);
      final flutterWidget = _runtime._convertToFlutter(fluxTree);
      
      setState(() {
        _builtWidget = flutterWidget;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _builtWidget = null;
      });
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
  
  FluxWidgetNode(this.name, {
    this.args = const {},
    this.children = const [],
  });
  
  @override
  String toString() => 'FluxWidgetNode($name, args: $args, children: $children)';
}

/// Runtime for executing Flux code and managing widget state
class FluxRuntime {
  final VM _vm = VM();
  final Map<String, CompiledWidget> _widgets = {};
  
  /// Callback when state changes (for Flutter rebuild)
  final void Function(String name, Object? value)? onStateChange;
  
  // Widget constructor names that should create FluxWidgetNode
  static const _widgetConstructors = {
    'Text', 'Column', 'Row', 'Container', 'Button', 'Center', 
    'Padding', 'SizedBox', 'Icon', 'Image', 'ListView', 'GridView',
    'Stack', 'Positioned', 'Expanded', 'Flexible', 'Card', 'Scaffold',
    'AppBar', 'FloatingActionButton', 'TextField', 'Checkbox',
  };
  
  // Stack for collecting children in nested widgets
  final List<List<FluxWidgetNode>> _childrenStack = [];
  
  FluxRuntime(String source, {this.onStateChange}) {
    // Set up state change callback
    _vm.onStateChange = onStateChange;
    
    // Compile source
    debugPrint('DEBUG RUNTIME: Source: $source');
    final lexer = Lexer(source);
    final tokens = lexer.tokenize();
    final parser = Parser(tokens);
    final ast = parser.parse();
    debugPrint('DEBUG RUNTIME: Parsed unit with ${ast.declarations.length} declarations');
    
    final compiler = Compiler(unit: ast);
    final function = compiler.endCompiler();
    debugPrint('DEBUG RUNTIME: Compilation finished. Bytecode size: ${function.chunk.code.length}');
    
    // Execute to populate globals (including widget definitions)
    
    // Inject widget names into globals so they can be resolved
    for (final name in _widgetConstructors) {
      _vm.globals[name] = name;
    }
    
    // Inject registered global functions
    for (final entry in FluxBindings.functions.entries) {
      _vm.globals[entry.key] = NativeFunction(entry.key, -1, (args) {
        // NativeFunction logic wraps FluxFunction
        // FluxFunction takes List<Object?> and returns FutureOr<Object?>
        // We pass arguments dynamically.
        // NativeFunction in VM usually has fixed arity, but we can use generic 0 or -1?
        // Wait, NativeFunction constructor takes arity. 
        // Our FluxBindings don't specify arity. 
        // We can pass -1 or similar if VM supports variable arity, 
        // OR we just set a high arity and let VM pass all args?
        // Actually VM._callValue checks arity?
        // VM._callValue passes `argCount` to helper, but NativeFunction.call(args) just takes list.
        // VM._callValue line 304: final args = _stack.sublist...
        // It DOES NOT check NativeFunction.arity against argCount explicitly in _callValue!
        // So arity in NativeFunction is metadata or used by compiler?
        // Let's pass 0 or a placeholder.
        return entry.value(args);
      });
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
  
  CompiledWidget? getWidget(String name) {
    return _widgets[name];
  }
  
  Widget renderWidget(String name, [Map<String, dynamic> args = const {}]) {
    final widget = getWidget(name);
    if (widget == null) return Text('Widget not found: $name');
    
    final node = executeBuild(widget, args);
    return _convertToFlutter(node);
  }

  FluxWidgetNode executeBuild(CompiledWidget widget, [Map<String, dynamic> args = const {}]) {
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
    
    final interpretResult = _vm.executeClosure(closure, positionalArgs);
    
    // Clean up handler
    _vm.widgetCallHandler = null;

    if (interpretResult != InterpretResult.ok) {
      // If execution failed, the stack might not contain a FluxWidgetNode
      _vm.stack.clear(); 
      return FluxWidgetNode('Error', args: {'text': 'Build error'});
    }
    
    // Get result from stack (build returns a value)
    final builtNode = _vm.stack.isNotEmpty ? _vm.stack.removeLast() : null;
    
    if (builtNode is FluxWidgetNode) {
      return builtNode;
    }
    
    // Fallback
    return FluxWidgetNode(
      'Text',
      args: {'0': 'Build returned: ${builtNode?.toString() ?? "null"}'},
    );
  }

  Widget _convertToFlutter(dynamic fluxNode) {
    if (fluxNode is FluxWidgetNode) {
      final builder = FluxBindings.get(fluxNode.name);
      if (builder == null) {
        return Text('Unknown widget: ${fluxNode.name}');
      }
      
      final children = fluxNode.children
          .map((child) => _convertToFlutter(child))
          .toList();
      
      // Process args to wrap closures
      final processedArgs = Map<String, dynamic>.from(fluxNode.args);
      for (final key in processedArgs.keys) {
        final value = processedArgs[key];
        if (value is ObjClosure) {
           processedArgs[key] = (List<Object?> callArgs) {
             // Execute closure on the VM
             _vm.executeClosure(value, callArgs);
           };
        }
      }

      return builder(processedArgs, children);
    }
    
    // Fallback for primitives (e.g., strings become Text)
    if (fluxNode is String) {
      return Text(fluxNode);
    }
    
    return ErrorWidget(Exception("Cannot convert $fluxNode to Widget"));
  }
  
  /// Handle widget constructor calls during build execution
  Object? _handleWidgetCall(Object? callee, int argCount, Map<String, dynamic> namedArgs, List<Object?> stack) {
    // Check if this is a widget constructor call or a user-defined widget
    final isBuiltin = callee is String && _widgetConstructors.contains(callee);
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
      
      // Special handling for builder closures (trailing blocks)
      if (args.containsKey('_children')) {
        final builder = args.remove('_children');
        if (builder is ObjClosure) {
            // Execute closure to generate children
            _childrenStack.add([]); // Push new collector
            _vm.executeClosure(builder);
            children.addAll(_childrenStack.removeLast());
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
