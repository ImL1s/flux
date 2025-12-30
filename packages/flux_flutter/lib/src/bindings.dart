import 'package:flutter/material.dart';
import 'dart:async';

/// Registry for Flux -> Flutter widget bindings
class FluxBindings {
  static final Map<String, FluxWidgetBuilder> _builders = {};
  static final Map<String, FluxFunction> _functions = {};
  
  /// Register a widget builder
  static void register(String name, FluxWidgetBuilder builder) {
    _builders[name] = builder;
  }
  
  /// Register a Dart function for Flux to call
  static void registerFunction(String name, FluxFunction function) {
    _functions[name] = function;
  }
  
  /// Get a widget builder by name
  static FluxWidgetBuilder? get(String name) => _builders[name];
  
  /// Get a function by name
  static FluxFunction? getFunction(String name) => _functions[name];
  
  /// Get all registered functions
  static Map<String, FluxFunction> get functions => _functions;
  
  /// Initialize default bindings
  static void initDefaults() {
    _initWidgets();
    _initFunctions();
  }
  
  static void _initWidgets() {
    // Text widget
    register('Text', (args, children) {
      final value = args['text'] ?? args['0'] ?? '';
      final text = value is String ? value : value.toString();
      return Text(text);
    });
    
    // Column widget
    register('Column', (args, children) {
      final mainAxisAlignment = _parseMainAxisAlignment(args['mainAxisAlignment'] as String?);
      final crossAxisAlignment = _parseCrossAxisAlignment(args['crossAxisAlignment'] as String?);
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: args['children'] as List<Widget>? ?? children,
      );
    });
    
    // Row widget
    register('Row', (args, children) {
      final mainAxisAlignment = _parseMainAxisAlignment(args['mainAxisAlignment'] as String?);
      final crossAxisAlignment = _parseCrossAxisAlignment(args['crossAxisAlignment'] as String?);
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: args['children'] as List<Widget>? ?? children,
      );
    });
    
    // Container widget
    register('Container', (args, children) {
      final padding = args['padding'] as double?;
      final color = _parseColor(args['color']);
      final width = (args['width'] ?? args['0'])?.toDouble();
      final height = (args['height'] ?? args['1'])?.toDouble();
      
      return Container(
        padding: padding != null ? EdgeInsets.all(padding) : null,
        color: color,
        width: width,
        height: height,
        child: args['child'] as Widget? ?? (children.isNotEmpty ? children.first : null),
      );
    });
    
    // Button widget (using ElevatedButton)
    register('Button', (args, children) {
      final label = args['text'] as String? ?? args['0'] as String? ?? 'Button';
      final onPressed = args['onPressed'];
      
      return ElevatedButton(
        onPressed: onPressed != null 
            ? () => _invokeCallback(onPressed, []) 
            : null,
        child: Text(label),
      );
    });
    
    // Layout widgets
    register('Center', (args, children) {
      return Center(
        child: children.isNotEmpty ? children.first : null,
      );
    });
    
    register('Expanded', (args, children) {
      final flex = args['flex'] as int? ?? 1;
      return Expanded(
        flex: flex,
        child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
      );
    });
    
    register('Flexible', (args, children) {
      final flex = args['flex'] as int? ?? 1;
      return Flexible(
        flex: flex,
        child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
      );
    });
    
    register('SizedBox', (args, children) {
      final width = (args['width'] ?? args['0'])?.toDouble();
      final height = (args['height'] ?? args['1'])?.toDouble();
      return SizedBox(
        width: width,
        height: height,
        child: args['child'] as Widget? ?? (children.isNotEmpty ? children.first : null),
      );
    });

    register('Padding', (args, children) {
      final padding = args['padding'] as double? ?? 8.0;
      return Padding(
        padding: EdgeInsets.all(padding),
        child: args['child'] as Widget? ?? (children.isNotEmpty ? children.first : null),
      );
    });

    register('Center', (args, children) {
      return Center(
        child: args['child'] as Widget? ?? (children.isNotEmpty ? children.first : null),
      );
    });
    
    // TextField widget with onChanged callback
    register('TextField', (args, children) {
      final hint = args['hint'] as String? ?? args['0'] as String? ?? '';
      final label = args['label'] as String?;
      final onChanged = args['onChanged'];
      final onSubmitted = args['onSubmitted'];
      
      return TextField(
        decoration: InputDecoration(
          hintText: hint,
          labelText: label,
        ),
        onChanged: onChanged != null 
            ? (value) => _invokeCallback(onChanged, [value])
            : null,
        onSubmitted: onSubmitted != null
            ? (value) => _invokeCallback(onSubmitted, [value])
            : null,
      );
    });
    
    // Image widget (network and asset)
    register('Image', (args, children) {
      final src = args['src'] as String? ?? args['0'] as String? ?? '';
      final width = args['width'] as double?;
      final height = args['height'] as double?;
      final fit = _parseBoxFit(args['fit'] as String?);
      
      if (src.startsWith('http://') || src.startsWith('https://')) {
        return Image.network(
          src,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        );
      } else {
        return Image.asset(
          src,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        );
      }
    });
    
    // Icon widget
    register('Icon', (args, children) {
      final name = args['name'] as String? ?? args['0'] as String? ?? 'star';
      final size = args['size'] as double? ?? 24.0;
      final colorValue = args['color'];
      final color = _parseColor(colorValue);
      
      return Icon(
        _parseIconData(name),
        size: size,
        color: color,
      );
    });
    
    // Card widget
    register('Card', (args, children) {
      final elevation = args['elevation'] as double? ?? 1.0;
      final colorValue = args['color'];
      
      return Card(
        elevation: elevation,
        color: _parseColor(colorValue),
        child: children.isNotEmpty ? children.first : null,
      );
    });
    
    // ListView widget
    register('ListView', (args, children) {
      final scrollDirection = args['horizontal'] == true 
          ? Axis.horizontal 
          : Axis.vertical;
      final padding = args['padding'] as double?;
      
      return ListView(
        scrollDirection: scrollDirection,
        padding: padding != null ? EdgeInsets.all(padding) : null,
        children: args['children'] as List<Widget>? ?? children,
      );
    });
    
    // GestureDetector for tap events
    register('GestureDetector', (args, children) {
      final onTap = args['onTap'];
      final onDoubleTap = args['onDoubleTap'];
      final onLongPress = args['onLongPress'];
      
      return GestureDetector(
        onTap: onTap != null ? () => _invokeCallback(onTap, []) : null,
        onDoubleTap: onDoubleTap != null ? () => _invokeCallback(onDoubleTap, []) : null,
        onLongPress: onLongPress != null ? () => _invokeCallback(onLongPress, []) : null,
        child: children.isNotEmpty ? children.first : null,
      );
    });
    
    // Enhanced Container with color support
    register('ColoredBox', (args, children) {
      final colorValue = args['color'] ?? args['0'];
      final color = _parseColor(colorValue) ?? Colors.transparent;
      
      return ColoredBox(
        color: color,
        child: children.isNotEmpty ? children.first : null,
      );
    });
    
    // Expanded widget
    register('Expanded', (args, children) {
      final flex = args['flex'] as int? ?? 1;
      return Expanded(
        flex: flex,
        child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
      );
    });
    
    // Spacer widget
    register('Spacer', (args, children) {
      final flex = args['flex'] as int? ?? 1;
      return Spacer(flex: flex);
    });
    
    // Divider widget
    register('Divider', (args, children) {
      final height = args['height'] as double?;
      final color = _parseColor(args['color']);
      return Divider(height: height, color: color);
    });
  
    // Scaffold
    register('Scaffold', (args, children) {
      final appBar = args['appBar'] as PreferredSizeWidget?;
      final body = args['body'] as Widget? ?? (children.isNotEmpty ? children.first : null);
      final floatingActionButton = args['floatingActionButton'] as Widget?;
      
      return Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
      );
    });
    
    // AppBar
    register('AppBar', (args, children) {
      final title = args['title'] as Widget?;
      final actions = args['actions'] as List<Widget>? ?? 
          (args['actions'] as List?)?.whereType<Widget>().toList();
      
      return AppBar(
        title: title,
        actions: actions,
      );
    });
    
    // FloatingActionButton
    register('FloatingActionButton', (args, children) {
      final onPressed = args['onPressed'];
      final child = args['child'] as Widget? ?? (children.isNotEmpty ? children.first : null);
      
      return FloatingActionButton(
        onPressed: onPressed != null ? () => _invokeCallback(onPressed, []) : null,
        child: child,
      );
    });
  }
  
  // Helper to invoke Flux callbacks
  static void _invokeCallback(dynamic callback, List<Object?> args) {
    if (callback is Function) {
      callback(args);
    }
  }
  
  // Parse color from various formats
  static Color? _parseColor(dynamic value) {
    if (value == null) return null;
    if (value is Color) return value;
    if (value is int) return Color(value);
    if (value is String) {
      // Handle named colors
      switch (value.toLowerCase()) {
        case 'red': return Colors.red;
        case 'blue': return Colors.blue;
        case 'green': return Colors.green;
        case 'yellow': return Colors.yellow;
        case 'orange': return Colors.orange;
        case 'purple': return Colors.purple;
        case 'pink': return Colors.pink;
        case 'black': return Colors.black;
        case 'white': return Colors.white;
        case 'grey': case 'gray': return Colors.grey;
        case 'transparent': return Colors.transparent;
      }
      // Handle hex colors
      if (value.startsWith('#')) {
        final hex = value.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      }
    }
    return null;
  }
  
  // Parse BoxFit
  static BoxFit _parseBoxFit(String? value) {
    switch (value) {
      case 'contain': return BoxFit.contain;
      case 'cover': return BoxFit.cover;
      case 'fill': return BoxFit.fill;
      case 'fitWidth': return BoxFit.fitWidth;
      case 'fitHeight': return BoxFit.fitHeight;
      case 'none': return BoxFit.none;
      case 'scaleDown': return BoxFit.scaleDown;
      default: return BoxFit.contain;
    }
  }
  
  // Parse icon name to IconData
  static IconData _parseIconData(String name) {
    // Common icons mapping
    final icons = <String, IconData>{
      'star': Icons.star,
      'home': Icons.home,
      'settings': Icons.settings,
      'search': Icons.search,
      'add': Icons.add,
      'remove': Icons.remove,
      'delete': Icons.delete,
      'edit': Icons.edit,
      'check': Icons.check,
      'close': Icons.close,
      'menu': Icons.menu,
      'arrow_back': Icons.arrow_back,
      'arrow_forward': Icons.arrow_forward,
      'favorite': Icons.favorite,
      'person': Icons.person,
      'email': Icons.email,
      'phone': Icons.phone,
      'camera': Icons.camera,
      'image': Icons.image,
      'play': Icons.play_arrow,
      'pause': Icons.pause,
      'stop': Icons.stop,
      'refresh': Icons.refresh,
      'info': Icons.info,
      'warning': Icons.warning,
      'error': Icons.error,
    };
    return icons[name] ?? Icons.help_outline;
  }

  static MainAxisAlignment _parseMainAxisAlignment(String? value) {
    switch (value) {
      case 'start': return MainAxisAlignment.start;
      case 'end': return MainAxisAlignment.end;
      case 'center': return MainAxisAlignment.center;
      case 'spaceBetween': return MainAxisAlignment.spaceBetween;
      case 'spaceAround': return MainAxisAlignment.spaceAround;
      case 'spaceEvenly': return MainAxisAlignment.spaceEvenly;
      default: return MainAxisAlignment.start;
    }
  }

  static CrossAxisAlignment _parseCrossAxisAlignment(String? value) {
    switch (value) {
      case 'start': return CrossAxisAlignment.start;
      case 'end': return CrossAxisAlignment.end;
      case 'center': return CrossAxisAlignment.center;
      case 'stretch': return CrossAxisAlignment.stretch;
      case 'baseline': return CrossAxisAlignment.baseline;
      default: return CrossAxisAlignment.center;
    }
  }
  
  static void _initFunctions() {
    // delay(ms) - Returns a Future that completes after delay
    registerFunction('delay', (args) async {
      final ms = args.isNotEmpty ? (args[0] as num).toInt() : 1000;
      await Future.delayed(Duration(milliseconds: ms));
      return null;
    });
    
    // now() - Returns current timestamp
    registerFunction('now', (args) {
      return DateTime.now().millisecondsSinceEpoch;
    });
    
    // toString(value) - Convert value to string
    registerFunction('toString', (args) {
      return args.isNotEmpty ? args[0].toString() : '';
    });
    
    // parseInt(str) - Parse string to int
    registerFunction('parseInt', (args) {
      if (args.isEmpty) return 0;
      return int.tryParse(args[0].toString()) ?? 0;
    });
    
    // parseDouble(str) - Parse string to double
    registerFunction('parseDouble', (args) {
      if (args.isEmpty) return 0.0;
      return double.tryParse(args[0].toString()) ?? 0.0;
    });
    
    // length(str or list) - Get length
    registerFunction('length', (args) {
      if (args.isEmpty) return 0;
      final value = args[0];
      if (value is String) return value.length;
      if (value is List) return value.length;
      return 0;
    });
    
    // log(message) - Debug logging
    registerFunction('log', (args) {
      final message = args.isNotEmpty ? args[0].toString() : '';
      debugPrint('[Flux Log]: $message');
      return null;
    });
    
    // push(list, item) - Add item to list
    registerFunction('push', (args) {
      if (args.length < 2) return null;
      final list = args[0];
      final item = args[1];
      if (list is List) {
        list.add(item);
      }
      return null;
    });
    
    // removeAt(list, index) - Remove item at index
    registerFunction('removeAt', (args) {
      if (args.length < 2) return null;
      final list = args[0];
      final index = args[1];
      if (list is List && index is int) {
        if (index >= 0 && index < list.length) {
          list.removeAt(index);
        }
      }
      return null;
    });
  }
}

/// Builder function type for Flux widgets
typedef FluxWidgetBuilder = Widget Function(
  Map<String, dynamic> args,
  List<Widget> children,
);

/// Function type for Dart functions callable from Flux
typedef FluxFunction = FutureOr<Object?> Function(List<Object?> args);

/// Wrapper for Dart Futures that can be used in Flux
class FluxFuture {
  final Future<Object?> _future;
  final Completer<Object?> _completer;
  
  FluxFuture._(this._future, this._completer);
  
  /// Create from an existing Dart Future
  factory FluxFuture.fromDart(Future<Object?> future) {
    final completer = Completer<Object?>();
    future.then(completer.complete).catchError(completer.completeError);
    return FluxFuture._(future, completer);
  }
  
  /// Create a pending future that can be completed later
  factory FluxFuture.pending() {
    final completer = Completer<Object?>();
    return FluxFuture._(completer.future, completer);
  }
  
  bool get isCompleted => _completer.isCompleted;
  Future<Object?> get dartFuture => _future;
  
  void complete(Object? value) {
    if (!_completer.isCompleted) {
      _completer.complete(value);
    }
  }
  
  void completeError(Object error) {
    if (!_completer.isCompleted) {
      _completer.completeError(error);
    }
  }
  
  @override
  String toString() => '<FluxFuture>';
}

