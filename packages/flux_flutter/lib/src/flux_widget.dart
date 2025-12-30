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
      final flutterWidget = _convertToFlutter(fluxTree);
      
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
  
  Widget _convertToFlutter(dynamic fluxNode) {
    if (fluxNode == null) {
      return const SizedBox.shrink();
    }
    
    if (fluxNode is FluxWidgetNode) {
      final builder = FluxBindings.get(fluxNode.name);
      if (builder == null) {
        return ErrorWidget(Exception("Unknown widget: ${fluxNode.name}"));
      }
      
      final children = fluxNode.children
          .map((child) => _convertToFlutter(child))
          .toList();
      
      return builder(fluxNode.args, children);
    }
    
    // Fallback for primitives (e.g., strings become Text)
    if (fluxNode is String) {
      return Text(fluxNode);
    }
    
    return ErrorWidget(Exception("Cannot convert $fluxNode to Widget"));
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
    final lexer = Lexer(source);
    final tokens = lexer.tokenize();
    final parser = Parser(tokens);
    final ast = parser.parse();
    
    final compiler = Compiler(unit: ast);
    final function = compiler.endCompiler();
    
    // Execute to populate globals (including widget definitions)
    
    // Inject widget names into globals so they can be resolved
    for (final name in _widgetConstructors) {
      _vm.globals[name] = name;
    }
    
    _vm.runChunk(function.chunk);
    
    // Extract widget definitions from globals
    for (final entry in _vm.globals.entries) {
      if (entry.value is CompiledWidget) {
        _widgets[entry.key] = entry.value as CompiledWidget;
      }
    }
  }
  
  CompiledWidget? getWidget(String name) {
    return _widgets[name];
  }
  
  FluxWidgetNode executeBuild(CompiledWidget widget) {
    // Set up widget call handler to intercept widget constructor calls
    _vm.widgetCallHandler = _handleWidgetCall;
    
    // Initialize state fields with their initial values
    for (int i = 0; i < widget.stateFields.length; i++) {
      final fieldName = widget.stateFields[i];
      // Execute the state initializer to get the initial value
      if (i < widget.stateInitializers.length) {
        _vm.runChunk(widget.stateInitializers[i].chunk);
        final initValue = _vm.stack.isNotEmpty ? _vm.stack.removeLast() : null;
        _vm.widgetState[fieldName] = initValue;
      } else {
        _vm.widgetState[fieldName] = null;
      }
    }
    
    // Execute the build method
    _vm.runChunk(widget.buildMethod.chunk);
    
    // Get result from stack (build returns a value)
    final result = _vm.stack.isNotEmpty ? _vm.stack.last : null;
    
    // Clean up handler
    _vm.widgetCallHandler = null;
    
    if (result is FluxWidgetNode) {
      return result;
    }
    
    // Fallback
    return FluxWidgetNode(
      'Text',
      args: {'0': 'Build returned: ${result?.toString() ?? "null"}'},
    );
  }
  
  /// Handle widget constructor calls during build execution
  Object? _handleWidgetCall(Object? callee, int argCount, List<Object?> stack) {
    // Check if this is a widget constructor call
    if (callee is String && _widgetConstructors.contains(callee)) {
      // Build FluxWidgetNode from stack arguments
      final args = <String, dynamic>{};
      final children = <FluxWidgetNode>[];
      
      // Pop arguments from stack (in reverse order)
      for (int i = argCount - 1; i >= 0; i--) {
        if (stack.isEmpty) break;
        final arg = stack.removeLast();
        
        if (arg is ObjClosure) {
           // Execute closure to generate children
           _childrenStack.add([]); // Push new collector
           _vm.executeClosure(arg);
           children.addAll(_childrenStack.removeLast());
        } else if (arg is FluxWidgetNode) {
          children.insert(0, arg);
        } else {
          args['$i'] = arg;
        }
      }
      
      // Pop the callee (widget name string)
      if (stack.isNotEmpty) {
        stack.removeLast();
      }
      
      // Create node
      final node = FluxWidgetNode(callee, args: args, children: children);
      
      // Add to parent collector if exists
      if (_childrenStack.isNotEmpty) {
        _childrenStack.last.add(node);
      }
      
      stack.add(node);
      
      return node; // Non-null indicates we handled it
    }
    
    return null; // Let VM handle normally
  }
}
