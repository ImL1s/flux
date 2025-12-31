import 'package:flutter/material.dart';
import 'dart:async';
import 'utils/flux_cast.dart';
import 'http_bindings.dart';

/// Registry for Flux -> Flutter widget bindings
class FluxBindings {
  static final Map<String, FluxWidgetBuilder> _builders = {};
  static final Map<String, FluxFunction> _functions = {};
  
  /// Global navigator key for Flux navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  /// Register a widget builder
  static void register(String name, FluxWidgetBuilder builder) {
    _builders[name] = builder;
  }
  
  /// Register a Dart function for Flux to call
  static void registerFunction(String name, FluxFunction function) {
    _functions[name] = function;
  }
  
  /// Register an async Dart function for Flux to call
  /// This is a convenience method that wraps async functions properly
  static void registerAsyncFunction(String name, Future<Object?> Function(List<Object?>) function) {
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
      final value = args['text'] ?? args['0'];
      final text = FluxCast.toStr(value);
      final styleMap = args['style'];
      return Text(
        text,
        style: _parseTextStyle(styleMap),
      );
    });
    
    // Column widget
    register('Column', (args, children) {
      final mainAxisAlignment = _parseMainAxisAlignment(FluxCast.toStringNullable(args['mainAxisAlignment']));
      final crossAxisAlignment = _parseCrossAxisAlignment(FluxCast.toStringNullable(args['crossAxisAlignment']));
      final widgetChildren = FluxCast.toWidgetList(args['children']);
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: widgetChildren.isNotEmpty ? widgetChildren : children.cast<Widget>(),
      );
    });
    
    // Row widget
    register('Row', (args, children) {
      final mainAxisAlignment = _parseMainAxisAlignment(FluxCast.toStringNullable(args['mainAxisAlignment']));
      final crossAxisAlignment = _parseCrossAxisAlignment(FluxCast.toStringNullable(args['crossAxisAlignment']));
      final widgetChildren = FluxCast.toWidgetList(args['children']);
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: widgetChildren.isNotEmpty ? widgetChildren : children.cast<Widget>(),
      );
    });
    
    // Container widget
    register('Container', (args, children) {
      final padding = _parseEdgeInsets(args['padding']);
      final margin = _parseEdgeInsets(args['margin']);
      final color = FluxCast.toColor(args['color']);
      final decoration = _parseBoxDecoration(args['decoration']);
      final width = FluxCast.toDouble(args['width'] ?? args['0']);
      final height = FluxCast.toDouble(args['height'] ?? args['1']);
      final child = args['child'] as Widget?;
      
      return Container(
        padding: padding,
        margin: margin,
        color: color,
        decoration: decoration,
        width: width,
        height: height,
        child: child ?? (children.isNotEmpty ? children.first : null),
      );
    });
    
    // Button widget (ElevatedButton)
    register('Button', (args, children) {
      final label = args['text'] as String? ?? args['0'] as String?;
      final childWidget = args['child'] as Widget?;
      final onPressed = args['onPressed'];
      
      return ElevatedButton(
        onPressed: onPressed is Function ? () => onPressed([]) : null,
        child: childWidget ?? Text(label ?? 'Button'),
      );
    });
    

    
    register('Expanded', (args, children) {
      final flex = FluxCast.toIntOrZero(args['flex']);
      return Expanded(
        flex: flex > 0 ? flex : 1,
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
      final width = FluxCast.toDouble(args['width'] ?? args['0']);
      final height = FluxCast.toDouble(args['height'] ?? args['1']);
      final child = args['child'] as Widget?;

      return SizedBox(
        width: width,
        height: height,
        child: child ?? (children.isNotEmpty ? children.first : null),
      );
    });

    register('Padding', (args, children) {
      final padding = _parseEdgeInsets(args['padding']) ?? const EdgeInsets.all(8.0);
      final child = args['child'] as Widget?;
      
      return Padding(
        padding: padding,
        child: child ?? (children.isNotEmpty ? children.first : null),
      );
    });

    register('Card', (args, children) {
      final child = args['child'] as Widget? ?? (children.isNotEmpty ? children.first : null);
      final color = FluxCast.toColor(args['color']);
      final margin = _parseEdgeInsets(args['margin']);
      
      return Card(
        color: color,
        margin: margin,
        child: child,
      );
    });

    register('ListTile', (args, children) {
       final title = args['title'] as Widget?;
       final subtitle = args['subtitle'] as Widget?;
       final leading = args['leading'] as Widget?;
       final trailing = args['trailing'] as Widget?;
       final onTap = args['onTap'];

       return ListTile(
         title: title,
         subtitle: subtitle,
         leading: leading,
         trailing: trailing,
         onTap: onTap is Function ? () => onTap([]) : null,
       );
    });

    register('Center', (args, children) {
      return Center(
        child: args['child'] as Widget? ?? (children.isNotEmpty ? children.first : null),
      );
    });
    
    // TextField widget with enhanced properties
    register('TextField', (args, children) {
      final hint = args['hint'] as String? ?? args['0'] as String? ?? '';
      final label = args['label'] as String?;
      final onChanged = args['onChanged'];
      final onSubmitted = args['onSubmitted'];
      final obscureText = FluxCast.toBool(args['obscureText']);
      final keyboardType = _parseTextInputType(args['keyboardType']);
      final style = _parseTextStyle(args['style']);
      final decoration = _parseInputDecoration(args['decoration']) ?? InputDecoration(
        hintText: hint,
        labelText: label,
      );
      
      return TextField(
        decoration: decoration,
        onChanged: onChanged != null 
            ? (value) => _invokeCallback(onChanged, [value])
            : null,
        onSubmitted: onSubmitted != null
            ? (value) => _invokeCallback(onSubmitted, [value])
            : null,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: style,
      );
    });

    // Checkbox widget
    register('Checkbox', (args, children) {
      final value = FluxCast.toBool(args['value']);
      final onChanged = args['onChanged'];
      final activeColor = FluxCast.toColor(args['activeColor']);
      
      return Checkbox(
        value: value,
        onChanged: onChanged != null 
            ? (val) => _invokeCallback(onChanged, [val]) 
            : null,
        activeColor: activeColor,
      );
    });

    // Switch widget
    register('Switch', (args, children) {
      final value = FluxCast.toBool(args['value']);
      final onChanged = args['onChanged'];
      final activeColor = FluxCast.toColor(args['activeColor']);
      
      return Switch(
        value: value,
        onChanged: onChanged != null 
            ? (val) => _invokeCallback(onChanged, [val]) 
            : null,
        activeColor: activeColor,
      );
    });

    
    // Image widget (network and asset)
    register('Image', (args, children) {
      final src = args['src'] as String? ?? args['0'] as String? ?? '';
      final width = FluxCast.toDouble(args['width']);
      final height = FluxCast.toDouble(args['height']);
      final fit = _parseBoxFit(args['fit'] as String?);
      final alignment = _parseAlignment(args['alignment']) ?? Alignment.center;
      final color = FluxCast.toColor(args['color']);
      
      if (src.startsWith('http://') || src.startsWith('https://')) {
        return Image.network(
          src,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          color: color,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        );
      } else {
        return Image.asset(
          src,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          color: color,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        );
      }
    });
    
    // Icon widget
    register('Icon', (args, children) {
      final name = args['name'] as String? ?? args['0'] as String? ?? 'star';
      final size = FluxCast.toDouble(args['size']) ?? 24.0;
      final color = FluxCast.toColor(args['color']);
      
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
        color: FluxCast.toColor(colorValue),
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
      final color = FluxCast.toColor(colorValue) ?? Colors.transparent;
      
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
      final color = FluxCast.toColor(args['color']);
      return Divider(height: height, color: color);
    });
    
    // Stack widget
    register('Stack', (args, children) {
      final alignment = _parseAlignment(args['alignment']) ?? AlignmentDirectional.topStart;
      return Stack(
        alignment: alignment,
        children: children,
      );
    });

    // Positioned widget
    register('Positioned', (args, children) {
      final left = FluxCast.toDouble(args['left']);
      final top = FluxCast.toDouble(args['top']);
      final right = FluxCast.toDouble(args['right']);
      final bottom = FluxCast.toDouble(args['bottom']);
      final width = FluxCast.toDouble(args['width']);
      final height = FluxCast.toDouble(args['height']);
      
      return Positioned(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        width: width,
        height: height,
        child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
      );
    });

    // Wrap widget
    register('Wrap', (args, children) {
      final direction = args['direction'] == 'vertical' ? Axis.vertical : Axis.horizontal;
      final spacing = FluxCast.toDoubleOrZero(args['spacing']);
      final runSpacing = FluxCast.toDoubleOrZero(args['runSpacing']);
      final alignment = _parseWrapAlignment(args['alignment']) ?? WrapAlignment.start;
      
      return Wrap(
        direction: direction,
        spacing: spacing,
        runSpacing: runSpacing,
        alignment: alignment,
        children: children,
      );
    });

    // SingleChildScrollView widget
    register('SingleChildScrollView', (args, children) {
      final direction = _parseAxis(args['scrollDirection']);
      final padding = _parseEdgeInsets(args['padding']);
      final child = args['child'] as Widget? ?? (children.isNotEmpty ? children.first : null);
      
      return SingleChildScrollView(
        scrollDirection: direction,
        padding: padding,
        child: child,
      );
    });

    // ListView widget (supporting children and builder)
    register('ListView', (args, children) {
      final direction = _parseAxis(args['scrollDirection']);
      final padding = _parseEdgeInsets(args['padding']);
      // Advanced: ListView.builder support
      final itemCount = args['itemCount'] as int?;
      final itemBuilder = args['itemBuilder']; // Expected to be Function(int) -> Widget

      if (itemCount != null && itemBuilder is Function) {
        return ListView.builder(
          scrollDirection: direction,
          padding: padding,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final result = itemBuilder([index]); // Invoke Flux function (wrapped or direct)
            if (result is Widget) return result;
            return const SizedBox.shrink(); // Fallback
          },
        );
      }

      return ListView(
        scrollDirection: direction,
        padding: padding,
        children: children.cast<Widget>(),
      );
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
      final titleArg = args['title'];
      final title = titleArg is String ? Text(titleArg) : titleArg as Widget?;
      
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
      final tooltip = args['tooltip'] as String?;
      
      return FloatingActionButton(
        onPressed: onPressed is Function ? () => onPressed([]) : null,
        tooltip: tooltip,
        child: child,
      );
    });

    // GestureDetector
    register('GestureDetector', (args, children) {
      final onTap = args['onTap'];
      final child = args['child'] as Widget? ?? (children.isNotEmpty ? children.first : null);
      
      return GestureDetector(
        onTap: onTap is Function ? () => onTap([]) : null,
        child: child,
      );
    });

    // InkWell
    register('InkWell', (args, children) {
      final onTap = args['onTap'];
      final child = args['child'] as Widget? ?? (children.isNotEmpty ? children.first : null);
      
      return InkWell(
        onTap: onTap is Function ? () => onTap([]) : null,
        child: child,
      );
    });

    // AlertDialog widget
    register('AlertDialog', (args, children) {
      final titleRaw = args['title'];
      final contentRaw = args['content'];
      final actionsRaw = args['actions'];
      
      Widget? title;
      if (titleRaw is Widget) {
        title = titleRaw;
      } else if (titleRaw != null) {
        title = Text(titleRaw.toString());
      }

      Widget? content;
      if (contentRaw is Widget) {
        content = contentRaw;
      } else if (contentRaw != null) {
        content = Text(contentRaw.toString());
      }
      
      List<Widget> actionWidgets = [];
      if (actionsRaw is List) {
        actionWidgets = actionsRaw.whereType<Widget>().toList();
      }
      
      return AlertDialog(
        title: title,
        content: content,
        actions: actionWidgets.isNotEmpty ? actionWidgets : null,
      );
    });

    // SimpleDialog widget
    register('SimpleDialog', (args, children) {
      final titleRaw = args['title'];
      
      Widget? title;
      if (titleRaw is Widget) {
        title = titleRaw;
      } else if (titleRaw != null) {
        title = Text(titleRaw.toString());
      }
      
      return SimpleDialog(
        title: title,
        children: children,
      );
    });
  }

  
  // Helper to invoke Flux callbacks
  static void _invokeCallback(dynamic callback, List<Object?> args) {
    if (callback is Function) {
      callback(args);
    }
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
  
  // Parse TextStyle
  static TextStyle? _parseTextStyle(dynamic value) {
    if (value is! Map) return null;
    
    return TextStyle(
      color: FluxCast.toColor(value['color']),
      fontSize: FluxCast.toDouble(value['fontSize']),
      fontWeight: _parseFontWeight(value['fontWeight']),
      fontStyle: _parseFontStyle(value['fontStyle']),
    );
  }

  static FontWeight? _parseFontWeight(dynamic value) {
    if (value is int) {
      switch (value) {
        case 100: return FontWeight.w100;
        case 200: return FontWeight.w200;
        case 300: return FontWeight.w300;
        case 400: return FontWeight.w400;
        case 500: return FontWeight.w500;
        case 600: return FontWeight.w600;
        case 700: return FontWeight.w700;
        case 800: return FontWeight.w800;
        case 900: return FontWeight.w900;
      }
    }
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'bold': return FontWeight.bold;
        case 'normal': return FontWeight.normal;
        case 'w100': return FontWeight.w100;
        case 'w200': return FontWeight.w200;
        case 'w300': return FontWeight.w300;
        case 'w400': return FontWeight.w400;
        case 'w500': return FontWeight.w500;
        case 'w600': return FontWeight.w600;
        case 'w700': return FontWeight.w700;
        case 'w800': return FontWeight.w800;
        case 'w900': return FontWeight.w900;
      }
    }
    return null;
  }

  static FontStyle? _parseFontStyle(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'italic': return FontStyle.italic;
        case 'normal': return FontStyle.normal;
      }
    }
    return null;
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

  // Parse EdgeInsets
  static EdgeInsets? _parseEdgeInsets(dynamic value) {
    if (value == null) return null;
    if (value is num) return EdgeInsets.all(value.toDouble());
    if (value is Map) {
      if (value.containsKey('all')) return EdgeInsets.all(FluxCast.toDoubleOrZero(value['all']));
      return EdgeInsets.only(
        left: FluxCast.toDoubleOrZero(value['left'] ?? value['horizontal']),
        right: FluxCast.toDoubleOrZero(value['right'] ?? value['horizontal']),
        top: FluxCast.toDoubleOrZero(value['top'] ?? value['vertical']),
        bottom: FluxCast.toDoubleOrZero(value['bottom'] ?? value['vertical']),
      );
    }
    return null;
  }

  // Parse BoxDecoration
  static BoxDecoration? _parseBoxDecoration(dynamic value) {
    if (value is! Map) return null;
    return BoxDecoration(
      color: FluxCast.toColor(value['color']),
      border: _parseBorder(value['border']),
      borderRadius: _parseBorderRadius(value['borderRadius']),
    );
  }

  // Parse Border
  static BoxBorder? _parseBorder(dynamic value) {
    if (value is! Map) return null;
    return Border.all(
      color: FluxCast.toColor(value['color']) ?? const Color(0xFF000000),
      width: FluxCast.toDoubleOrZero(value['width']),
    );
  }

  // Parse BorderRadius
  static BorderRadius? _parseBorderRadius(dynamic value) {
    if (value is num) return BorderRadius.circular(value.toDouble());
    // TODO: Support complex partial radius if needed (topLeft, etc.)
    return null;
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

  static TextInputType? _parseTextInputType(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'text': return TextInputType.text;
        case 'number': return TextInputType.number;
        case 'email': return TextInputType.emailAddress;
        case 'phone': return TextInputType.phone;
        case 'multiline': return TextInputType.multiline;
        case 'url': return TextInputType.url;
      }
    }
    return null;
  }

  static Axis _parseAxis(dynamic value) {
     if (value is String) {
       final lower = value.toLowerCase();
       if (lower == 'horizontal') return Axis.horizontal;
     }
     return Axis.vertical;
  }

  static InputDecoration? _parseInputDecoration(dynamic value) {
    if (value is! Map) return null;
    return InputDecoration(
      hintText: FluxCast.toStr(value['hintText'] ?? value['hint']),
      labelText: FluxCast.toStr(value['labelText'] ?? value['label']),
      filled: FluxCast.toBool(value['filled']),
      fillColor: FluxCast.toColor(value['fillColor']),
      border: _parseInputBorder(value['border']),
      enabledBorder: _parseInputBorder(value['enabledBorder']),
      focusedBorder: _parseInputBorder(value['focusedBorder']),
      contentPadding: _parseEdgeInsets(value['contentPadding']),
    );
  }

  static InputBorder? _parseInputBorder(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'none': return InputBorder.none;
        case 'outline': return const OutlineInputBorder();
        case 'underline': return const UnderlineInputBorder();
      }
    }
    if (value is Map) {
      // Custom border support could go here (radius, borderSide)
      // For now, simple types
      final type = value['type'];
      if (type == 'outline') {
         return OutlineInputBorder(
           borderRadius: _parseBorderRadius(value['borderRadius']) ?? const BorderRadius.all(Radius.circular(4.0)),
           borderSide: _parseBorderSide(value['borderSide']) ?? const BorderSide(),
         );
      }
      if (type == 'underline') {
         return UnderlineInputBorder(
           borderSide: _parseBorderSide(value['borderSide']) ?? const BorderSide(),
         );
      }
    }
    return null;
  }

  static BorderSide? _parseBorderSide(dynamic value) {
    if (value is! Map) return null;
    return BorderSide(
      color: FluxCast.toColor(value['color']) ?? const Color(0xFF000000),
      width: FluxCast.toDoubleOrZero(value['width']) > 0 ? FluxCast.toDoubleOrZero(value['width']) : 1.0,
      style: BorderStyle.solid,
    );
  }

  static AlignmentGeometry? _parseAlignment(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'topleft': return Alignment.topLeft;
        case 'topcenter': return Alignment.topCenter;
        case 'topright': return Alignment.topRight;
        case 'centerleft': return Alignment.centerLeft;
        case 'center': return Alignment.center;
        case 'centerright': return Alignment.centerRight;
        case 'bottomleft': return Alignment.bottomLeft;
        case 'bottomcenter': return Alignment.bottomCenter;
        case 'bottomright': return Alignment.bottomRight;
      }
    }
    return null;
  }

  static WrapAlignment? _parseWrapAlignment(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'start': return WrapAlignment.start;
        case 'end': return WrapAlignment.end;
        case 'center': return WrapAlignment.center;
        case 'spacebetween': return WrapAlignment.spaceBetween;
        case 'spacearound': return WrapAlignment.spaceAround;
        case 'spaceevenly': return WrapAlignment.spaceEvenly;
      }
    }
    return null;
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
    
    // List functions
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

    registerFunction('list_add', (args) {
      if (args.isEmpty) return null;
      final list = args[0] as List;
      list.add(args[1]);
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

    // Navigation: pop
    registerFunction('pop', (args) {
      final result = args.isNotEmpty ? args[0] : null;
      navigatorKey.currentState?.pop(result);
      return null;
    });

    // Navigation: pushNamed
    registerFunction('pushNamed', (args) {
      if (args.isEmpty) return null;
      final routeName = args[0].toString();
      final routeArgs = args.length > 1 ? args[1] : null;
      return navigatorKey.currentState?.pushNamed(routeName, arguments: routeArgs);
    });

    // Navigation: push with a simple screen widget
    // Usage: navigator_push("ScreenName", {arg1: value1})
    // Note: This pushes a named route. For dynamic widget pushing, use pushNamed with registered routes.
    registerFunction('navigator_push', (args) async {
      if (args.isEmpty) return null;
      final context = navigatorKey.currentContext;
      if (context == null) return null;
      
      final routeName = args[0].toString();
      final routeArgs = args.length > 1 ? args[1] : null;
      
      return navigatorKey.currentState?.pushNamed(routeName, arguments: routeArgs);
    });

    // Dialog: showAlert(title, content) -> Future<bool?>
    // Returns true if OK pressed, false if Cancel pressed, null if dismissed
    registerFunction('showAlert', (args) async {
      final context = navigatorKey.currentContext;
      if (context == null) return null;

      final title = args.isNotEmpty ? args[0]?.toString() : 'Alert';
      final content = args.length > 1 ? args[1]?.toString() : '';
      
      return showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title ?? 'Alert'),
          content: Text(content ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });

    // Dialog: showConfirmDialog(title, content, confirmText, cancelText) -> Future<bool?>
    registerFunction('showConfirmDialog', (args) async {
      final context = navigatorKey.currentContext;
      if (context == null) return null;

      final title = args.isNotEmpty ? args[0]?.toString() : 'Confirm';
      final content = args.length > 1 ? args[1]?.toString() : '';
      final confirmText = args.length > 2 ? args[2]?.toString() : 'OK';
      final cancelText = args.length > 3 ? args[3]?.toString() : 'Cancel';
      
      return showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title ?? 'Confirm'),
          content: Text(content ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(cancelText ?? 'Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmText ?? 'OK'),
            ),
          ],
        ),
      );
    });

    // Dialog: showInputDialog(title, hint) -> Future<String?>
    registerFunction('showInputDialog', (args) async {
      final context = navigatorKey.currentContext;
      if (context == null) return null;

      final title = args.isNotEmpty ? args[0]?.toString() : 'Input';
      final hint = args.length > 1 ? args[1]?.toString() : '';
      final controller = TextEditingController();
      
      return showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title ?? 'Input'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hint),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });

    // Register HTTP bindings
    for (final entry in HttpBindings.functions.entries) {
      registerFunction(entry.key, entry.value as FluxFunction);
    }
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

