/// Flux-Riverpod Integration (Modern Notifier API)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_vm/flux_vm.dart';
import 'flux_widget.dart';
import 'bindings.dart';

/// A Flux widget that integrates with Riverpod for state management.
/// 
/// This widget uses the modern Riverpod Notifier API. Flux scripts can
/// interact with Riverpod providers using `getProvider` and `setProvider`.
/// 
/// Example usage:
/// ```dart
/// // Define a Notifier
/// class CounterNotifier extends Notifier<int> {
///   @override
///   int build() => 0;
///   
///   void increment() => state++;
///   void set(int value) => state = value;
/// }
/// 
/// final counterProvider = NotifierProvider<CounterNotifier, int>(
///   CounterNotifier.new,
/// );
/// 
/// // Use in widget
/// ProviderScope(
///   child: FluxRiverpodWidget(
///     source: fluxSource,
///     widgetName: 'Counter',
///     notifierProviders: {
///       'counter': counterProvider,
///     },
///   ),
/// )
/// ```
/// 
/// In your Flux script:
/// - `getProvider("counter")` - Read current value
/// - `setProvider("counter", value)` - Update via notifier
class FluxRiverpodWidget extends ConsumerStatefulWidget {
  /// The Flux source code
  final String source;
  
  /// Name of the widget to instantiate
  final String widgetName;
  
  /// Map of provider names to NotifierProviders
  final Map<String, NotifierProvider<Notifier<Object?>, Object?>> notifierProviders;
  
  /// Optional properties to pass to the widget
  final Map<String, dynamic> props;

  const FluxRiverpodWidget({
    super.key,
    required this.source,
    required this.widgetName,
    this.notifierProviders = const {},
    this.props = const {},
  });

  @override
  ConsumerState<FluxRiverpodWidget> createState() => _FluxRiverpodWidgetState();
}

class _FluxRiverpodWidgetState extends ConsumerState<FluxRiverpodWidget> {
  late _FluxRiverpodRuntime _runtime;
  bool _initialized = false;

  void _initRuntime() {
    _runtime = _FluxRiverpodRuntime(
      source: widget.source,
      notifierProviders: widget.notifierProviders,
      ref: ref,
      onStateChange: (name, value) => setState(() {}),
    );
    _initialized = true;
  }

  @override
  void didUpdateWidget(covariant FluxRiverpodWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source || 
        oldWidget.widgetName != widget.widgetName) {
      _initialized = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch all registered providers to trigger rebuilds
    for (final provider in widget.notifierProviders.values) {
      ref.watch(provider);
    }
    
    if (!_initialized) {
      _initRuntime();
    }

    try {
      final widgetDef = _runtime.getWidget(widget.widgetName);
      if (widgetDef == null) {
        return Center(child: Text('Widget "${widget.widgetName}" not found'));
      }
      final tree = _runtime.executeBuild(widgetDef, widget.props);
      return _runtime.convertToFlutter(tree);
    } catch (e, stackTrace) {
      debugPrint('Flux Error: $e');
      debugPrint('$stackTrace');
      return Center(
        child: Text('Flux Error: $e', style: const TextStyle(color: Colors.red)),
      );
    }
  }
}

/// Internal runtime with Riverpod support
class _FluxRiverpodRuntime {
  final VM _vm = VM();
  final Map<String, CompiledWidget> _widgets = {};
  final Map<String, NotifierProvider<Notifier<Object?>, Object?>> _notifierProviders;
  final WidgetRef _ref;
  final void Function(String name, Object? value)? onStateChange;
  
  final List<List<FluxWidgetNode>> _childrenStack = [];
  
  static const _widgetConstructors = {
    'Text', 'Column', 'Row', 'Container', 'Button', 'Center', 
    'Padding', 'SizedBox', 'Icon', 'Image', 'ListView', 'GridView',
    'Stack', 'Positioned', 'Expanded', 'Flexible', 'Card', 'Scaffold',
    'AppBar', 'FloatingActionButton', 'TextField', 'Checkbox',
  };

  _FluxRiverpodRuntime({
    required String source,
    required Map<String, NotifierProvider<Notifier<Object?>, Object?>> notifierProviders,
    required WidgetRef ref,
    this.onStateChange,
  }) : _notifierProviders = notifierProviders, _ref = ref {
    _vm.onStateChange = onStateChange;
    FluxBindings.initDefaults(); // Ensure default bindings are registered
    
    // Register Riverpod functions
    _registerRiverpodFunctions();
    
    // Compile source
    final lexer = Lexer(source);
    final parser = Parser(lexer.tokenize());
    final ast = parser.parse();
    final compiler = Compiler(unit: ast);
    final function = compiler.endCompiler();
    
    // Inject widget names
    for (final name in _widgetConstructors) {
      _vm.globals[name] = name;
    }
    
    // Inject bindings
    for (final entry in FluxBindings.functions.entries) {
      _vm.globals[entry.key] = NativeFunction(entry.key, -1, (args) {
        return entry.value(args);
      });
    }
    
    // Set widget handler before initial execution
    _vm.widgetCallHandler = _handleWidgetCall;
    
    _vm.runChunk(function.chunk);
    
    // Extract widget definitions
    for (final entry in _vm.globals.entries) {
      if (entry.value is CompiledWidget) {
        _widgets[entry.key] = entry.value as CompiledWidget;
        _initializeWidgetState(entry.value as CompiledWidget);
      }
    }
  }

  void _registerRiverpodFunctions() {
    // getProvider(name) - Read current value from a Notifier
    _vm.globals['getProvider'] = NativeFunction('getProvider', 1, (args) {
      if (args.isEmpty) {
        throw ArgumentError('getProvider requires a provider name');
      }
      final name = args[0] as String;
      final provider = _notifierProviders[name];
      if (provider == null) {
        throw ArgumentError('Provider "$name" not found');
      }
      return _ref.read(provider);
    });
    
    // setProvider(name, value) - Update state via Notifier
    // Note: The Notifier must have a method that accepts the value
    // For simple state, we use reflection or a convention-based approach
    _vm.globals['setProvider'] = NativeFunction('setProvider', 2, (args) {
      if (args.length < 2) {
        throw ArgumentError('setProvider requires name and value');
      }
      final name = args[0] as String;
      final value = args[1];
      final provider = _notifierProviders[name];
      if (provider == null) {
        throw ArgumentError('Provider "$name" not found');
      }
      
      // Get the notifier and try to call a 'set' method
      final notifier = _ref.read(provider.notifier);
      if (notifier is FluxSettableNotifier) {
        notifier.set(value);
      } else {
        throw ArgumentError(
          'Provider "$name" notifier does not implement FluxSettableNotifier. '
          'Use a notifier that extends FluxSettableNotifier for setProvider support.'
        );
      }
      return null;
    });
  }

  void _initializeWidgetState(CompiledWidget widget) {
    for (int i = 0; i < widget.stateFields.length; i++) {
      final fieldName = widget.stateFields[i];
      
      if (!_vm.widgetState.containsKey(fieldName)) {
        if (i < widget.stateInitializers.length) {
          final initFunc = widget.stateInitializers[i];
          _vm.runChunk(initFunc.chunk);
          final initValue = _vm.stack.isNotEmpty ? _vm.stack.removeLast() : null;
          _vm.widgetState[fieldName] = initValue;
        } else {
          _vm.widgetState[fieldName] = null;
        }
      }
    }
  }

  CompiledWidget? getWidget(String name) => _widgets[name];

  dynamic executeBuild(CompiledWidget widget, [Map<String, dynamic> args = const {}]) {
    _vm.widgetCallHandler = (callee, argCount, namedArgs, stack) {
      return _handleWidgetCall(callee, argCount, namedArgs, stack);
    };
    
    final buildFunc = widget.buildMethod;
    final  closure = ObjClosure(widget.buildMethod, []);
    
    List<Object?> positionalArgs = [];
    final paramNames = widget.buildMethod.paramNames;
    if (args.isNotEmpty) {
      for (final paramName in paramNames) {
        positionalArgs.add(args[paramName]);
      }
    }
    
    // Execute closure
    final result = _vm.executeClosure(closure, positionalArgs);
    if (result == InterpretResult.ok && _vm.stack.isNotEmpty) {
      return _vm.stack.last;
    }
    return result;
  }

  Widget convertToFlutter(dynamic fluxNode) {
    if (fluxNode is Widget) return fluxNode;
    if (fluxNode is! FluxWidgetNode) {
      return Text('Error: Invalid node type: ${fluxNode.runtimeType}');
    }

    final node = fluxNode;
    
    // Check if this is a custom widget with deferred build execution
    final compiledWidget = node.args['_compiledWidget'];
    if (compiledWidget is CompiledWidget) {
      // Remove internal marker before passing args
      final propsArgs = Map<String, dynamic>.from(node.args);
      propsArgs.remove('_compiledWidget');
      
      // First, convert any FluxWidgetNode args to Flutter Widgets
      final processedProps = _preprocessArgs(propsArgs);
      
      // Execute build with converted props
      final buildResult = executeBuild(compiledWidget, processedProps);
      if (buildResult is FluxWidgetNode) {
        return convertToFlutter(buildResult);
      }
      return Text('Error executing custom widget: ${node.name}');
    }
    
    final builder = FluxBindings.get(node.name);
    
    if (builder == null) {
      return Text('Unknown widget: ${node.name}');
    }

    final List<Widget> children = node.children.map((child) {
      return convertToFlutter(child);
    }).toList();

    // Wrap arguments to handle closures and nested widgets
    final processedArgs = _preprocessArgs(node.args);

    return builder(processedArgs, children);
  }

  Map<String, dynamic> _preprocessArgs(Map<String, dynamic> args) {
    final newArgs = Map<String, dynamic>.from(args);
    for (final entry in args.entries) {
      final value = entry.value;
      
      if (value is ObjClosure) {
        newArgs[entry.key] = (List<Object?>? callbackArgs) {
          final result = _vm.executeClosure(value, callbackArgs ?? []);
          return result;
        };
      } else if (value is FluxWidgetNode) {
        newArgs[entry.key] = convertToFlutter(value);
      } else if (value is List) {
        // Handle list of widgets (e.g. for slivers or flexible layouts)
        bool hasNodes = value.any((e) => e is FluxWidgetNode);
        if (hasNodes) {
           final list = value.map((e) {
             if (e is FluxWidgetNode) return convertToFlutter(e);
             return e;
           }).toList();
           
           if (list.every((e) => e is Widget)) {
             newArgs[entry.key] = List<Widget>.from(list);
           } else {
             newArgs[entry.key] = list;
           }
        }
      }
    }
    return newArgs;
  }

  FluxWidgetNode? _handleWidgetCall(
    Object? callee, 
    int argCount, 
    Map<String, dynamic> namedArgs,
    List<Object?> stack,
  ) {
    // Check both static list AND dynamically registered bindings
    final isBuiltin = callee is String && (_widgetConstructors.contains(callee) || FluxBindings.get(callee) != null);
    final isCustom = callee is CompiledWidget;
    
    if (!isBuiltin && !isCustom) {
      return null; // Not a widget call, let VM handle it
    }

    String widgetName;
    if (isBuiltin) {
      widgetName = callee as String;
    } else {
      // CompiledWidget - store reference for later build execution
      final compiledWidget = callee as CompiledWidget;
      widgetName = compiledWidget.name;
      
      // Build args map from positional and named args
      final args = Map<String, dynamic>.from(namedArgs);
      args['_compiledWidget'] = compiledWidget; // Store reference for convertToFlutter
      
      // Pop positional args from stack
      for (int i = argCount - 1; i >= 0; i--) {
        if (stack.isNotEmpty) {
          args[i.toString()] = stack.removeLast();
        }
      }
      
      // Pop callee
      if (stack.isNotEmpty) stack.removeLast();
      
      final node = FluxWidgetNode(widgetName, args: args, children: []);
      
      // Add to parent collector if exists
      if (_childrenStack.isNotEmpty) {
        _childrenStack.last.add(node);
      }
      
      // Push result to stack
      stack.add(node);
      return node;
    }

    // Build args map from positional and named args
    final args = Map<String, dynamic>.from(namedArgs);
    
    // Pop positional args from stack
    for (int i = argCount - 1; i >= 0; i--) {
      if (stack.isNotEmpty) {
        args[i.toString()] = stack.removeLast();
      }
    }
    
    // Pop callee
    if (stack.isNotEmpty) stack.removeLast();
    
    // Handle _children closure (DSL block syntax)
    final childrenClosure = namedArgs['_children'];
    List<FluxWidgetNode> children = [];
    
    if (childrenClosure is ObjClosure) {
      _childrenStack.add([]);
      _vm.executeClosure(childrenClosure, []);
      children = _childrenStack.removeLast();
    }
    
    // Handle children: [...] named argument (list of widgets)
    final childrenArg = args['children'];
    if (childrenArg is List && children.isEmpty) {
      for (final item in childrenArg) {
        if (item is FluxWidgetNode) {
          children.add(item);
        }
      }
      // Remove from args since it's now in children
      args.remove('children');
    }

    final node = FluxWidgetNode(widgetName, args: args, children: children);
    
    // Add to parent collector if exists
    if (_childrenStack.isNotEmpty) {
      _childrenStack.last.add(node);
    }
    
    // Push result to stack
    stack.add(node);
    return node;
  }
}

/// Mixin for Notifiers that support the `set` method from Flux scripts.
/// 
/// Implement this in your Notifier to enable `setProvider` from Flux:
/// ```dart
/// class CounterNotifier extends Notifier<int> with FluxSettableNotifier<int> {
///   @override
///   int build() => 0;
///   
///   @override
///   void set(int value) => state = value;
/// }
/// ```
mixin FluxSettableNotifier<T> on Notifier<T> {
  /// Set the state to a new value. Called by Flux `setProvider`.
  void set(T value) => state = value;
}

/// A simple Notifier for basic value types that works with Flux.
/// 
/// Example:
/// ```dart
/// final counterProvider = NotifierProvider<FluxValueNotifier<int>, int>(
///   () => FluxValueNotifier(0),
/// );
/// ```
class FluxValueNotifier<T> extends Notifier<T> with FluxSettableNotifier<T> {
  final T _initialValue;
  
  FluxValueNotifier(this._initialValue);
  
  @override
  T build() => _initialValue;
  
  @override
  void set(T value) => state = value;
  
  /// Convenience method to update state
  void update(T Function(T current) updater) {
    state = updater(state);
  }
}
