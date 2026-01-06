import 'package:flutter/material.dart';
import 'dart:async';

import 'utils/flux_cast.dart';
import 'http_bindings.dart';
import 'modules/camera_preview.dart';
import 'ui/flux_ui.dart';

/// Registry for Flux -> Flutter widget bindings
class FluxBindings {
  static final Map<String, FluxWidgetBuilder> _builders = {};
  static final Map<String, FluxFunction> _functions = {};

  /// Global navigator key for Flux navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

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
  static void registerAsyncFunction(
      String name, Future<Object?> Function(List<Object?>) function) {
    _functions[name] = function;
  }

  /// Get a widget builder by name
  static FluxWidgetBuilder? get(String name) => _builders[name];

  /// Get a function by name
  static FluxFunction? getFunction(String name) => _functions[name];

  /// Get all registered functions
  static Map<String, FluxFunction> get functions => _functions;

  /// Get all registered widget names
  static Set<String> get registeredWidgets => _builders.keys.toSet();

  /// Initialize default bindings
  static void initDefaults() {
    _initWidgets();
    _initFunctions();
    _initDateTimePickers();
    _initFormWidgets();
    _initCameraWidgets();
    _initFluxUiWidgets();
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
      final mainAxisAlignment = _parseMainAxisAlignment(
          FluxCast.toStringNullable(args['mainAxisAlignment']));
      final crossAxisAlignment = _parseCrossAxisAlignment(
          FluxCast.toStringNullable(args['crossAxisAlignment']));
      final widgetChildren = FluxCast.toWidgetList(args['children']);
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: widgetChildren.isNotEmpty
            ? widgetChildren
            : children.cast<Widget>(),
      );
    });

    // Row widget
    register('Row', (args, children) {
      final mainAxisAlignment = _parseMainAxisAlignment(
          FluxCast.toStringNullable(args['mainAxisAlignment']));
      final crossAxisAlignment = _parseCrossAxisAlignment(
          FluxCast.toStringNullable(args['crossAxisAlignment']));
      final widgetChildren = FluxCast.toWidgetList(args['children']);
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: widgetChildren.isNotEmpty
            ? widgetChildren
            : children.cast<Widget>(),
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

      // IMPORTANT: Flutter Container cannot have both color and decoration
      // If decoration is provided, color must be part of decoration, not Container
      return Container(
        padding: padding,
        margin: margin,
        color: decoration == null
            ? color
            : null, // Only use color if no decoration
        decoration: decoration,
        width: width,
        height: height,
        child: child ?? (children.isNotEmpty ? children.first : null),
      );
    });

    // Button widget (ElevatedButton)
    register('Button', (args, children) {
      final label = FluxCast.toStringNullable(args['text'] ?? args['0']);
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
      final flex = FluxCast.toInt(args['flex']) ?? 1;
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
      final padding =
          _parseEdgeInsets(args['padding']) ?? const EdgeInsets.all(8.0);
      final child = args['child'] as Widget?;

      return Padding(
        padding: padding,
        child: child ?? (children.isNotEmpty ? children.first : null),
      );
    });

    register('Card', (args, children) {
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);
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
        child: args['child'] as Widget? ??
            (children.isNotEmpty ? children.first : null),
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
      final decoration = _parseInputDecoration(args['decoration']) ??
          InputDecoration(
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
// ignore: deprecated_member_use
        activeColor: activeColor,
      );
    });

    // Image widget (network and asset)
    register('Image', (args, children) {
      final src = FluxCast.toStr(args['src'] ?? args['0']);
      final width = FluxCast.toDouble(args['width']);
      final height = FluxCast.toDouble(args['height']);
      final fit = _parseBoxFit(FluxCast.toStringNullable(args['fit']));
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
      final name = FluxCast.toStr(args['name'] ?? args['0'] ?? 'star');
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
      final elevation = FluxCast.toDouble(args['elevation']) ?? 1.0;
      final colorValue = args['color'];

      return Card(
        elevation: elevation,
        color: FluxCast.toColor(colorValue),
        child: children.isNotEmpty ? children.first : null,
      );
    });

    // ListView widget
    register('ListView', (args, children) {
      final scrollDirection =
          args['horizontal'] == true ? Axis.horizontal : Axis.vertical;
      final padding = FluxCast.toDouble(args['padding']);

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
        onDoubleTap:
            onDoubleTap != null ? () => _invokeCallback(onDoubleTap, []) : null,
        onLongPress:
            onLongPress != null ? () => _invokeCallback(onLongPress, []) : null,
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
      final flex = FluxCast.toInt(args['flex']) ?? 1;
      return Expanded(
        flex: flex,
        child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
      );
    });

    // Spacer widget
    register('Spacer', (args, children) {
      final flex = FluxCast.toInt(args['flex']) ?? 1;
      return Spacer(flex: flex);
    });

    // Divider widget
    register('Divider', (args, children) {
      final height = FluxCast.toDouble(args['height']);
      final color = FluxCast.toColor(args['color']);
      return Divider(height: height, color: color);
    });

    // Stack widget
    register('Stack', (args, children) {
      final alignment =
          _parseAlignment(args['alignment']) ?? AlignmentDirectional.topStart;
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
      final direction =
          args['direction'] == 'vertical' ? Axis.vertical : Axis.horizontal;
      final spacing = FluxCast.toDoubleOrZero(args['spacing']);
      final runSpacing = FluxCast.toDoubleOrZero(args['runSpacing']);
      final alignment =
          _parseWrapAlignment(args['alignment']) ?? WrapAlignment.start;

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
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);

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
      final itemBuilder =
          args['itemBuilder']; // Expected to be Function(int) -> Widget

      if (itemCount != null && itemBuilder is Function) {
        return ListView.builder(
          scrollDirection: direction,
          padding: padding,
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final result = itemBuilder(
                [index]); // Invoke Flux function (wrapped or direct)
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
      final body = args['body'] as Widget? ??
          (children.isNotEmpty ? children.first : null);
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
        actions: actions ?? children.cast<Widget>(),
      );
    });

    // FloatingActionButton
    register('FloatingActionButton', (args, children) {
      final onPressed = args['onPressed'];
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);
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
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);

      return GestureDetector(
        onTap: onTap is Function ? () => onTap([]) : null,
        child: child,
      );
    });

    // InkWell
    register('InkWell', (args, children) {
      final onTap = args['onTap'];
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);

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

    // ========== Scaffold & AppBar (Phase 24: Extended Widget Library) ==========

    // Scaffold widget - The basic Material Design visual layout structure
    register('Scaffold', (args, children) {
      final appBar = args['appBar'] as Widget?;
      final body = args['body'] as Widget? ??
          (children.isNotEmpty ? children.first : null);
      final floatingActionButton = args['floatingActionButton'] as Widget?;
      final drawer = args['drawer'] as Widget?;
      final bottomNavigationBar = args['bottomNavigationBar'] as Widget?;
      final backgroundColor = FluxCast.toColor(args['backgroundColor']);

      return Scaffold(
        appBar: appBar is PreferredSizeWidget ? appBar : null,
        body: body,
        floatingActionButton: floatingActionButton,
        drawer: drawer,
        bottomNavigationBar: bottomNavigationBar,
        backgroundColor: backgroundColor,
      );
    });

    // AppBar widget - Material Design app bar
    register('AppBar', (args, children) {
      final titleRaw = args['title'];
      final actionsRaw = args['actions'];
      final leadingRaw = args['leading'] as Widget?;
      final backgroundColor = FluxCast.toColor(args['backgroundColor']);
      final centerTitle = FluxCast.toBool(args['centerTitle']);
      final elevation = FluxCast.toDoubleNullable(args['elevation']);

      final bottomRaw = args['bottom'] as Widget?;

      Widget? title;
      if (titleRaw is Widget) {
        title = titleRaw;
      } else if (titleRaw != null) {
        title = Text(titleRaw.toString());
      }

      List<Widget> actions = [];
      if (actionsRaw is List) {
        actions = actionsRaw.whereType<Widget>().toList();
      }

      return AppBar(
        title: title,
        leading: leadingRaw,
        actions: actions.isNotEmpty ? actions : null,
        bottom: bottomRaw is PreferredSizeWidget ? bottomRaw : null,
        backgroundColor: backgroundColor,
        centerTitle: centerTitle,
        elevation: elevation,
      );
    });

    // Drawer widget - Material Design drawer
    register('Drawer', (args, children) {
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);
      final backgroundColor = FluxCast.toColor(args['backgroundColor']);
      final elevation = FluxCast.toDoubleNullable(args['elevation']);
      final width = FluxCast.toDoubleNullable(args['width']);

      return Drawer(
        backgroundColor: backgroundColor,
        elevation: elevation,
        width: width,
        child: child,
      );
    });

    // DrawerHeader widget
    register('DrawerHeader', (args, children) {
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);
      final decoration = _parseBoxDecoration(args['decoration']);
      final padding = _parseEdgeInsets(args['padding']) ??
          const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0);
      final margin = _parseEdgeInsets(args['margin']) ??
          const EdgeInsets.only(bottom: 8.0);

      return DrawerHeader(
        decoration: decoration,
        padding: padding,
        margin: margin,
        child: child,
      );
    });

    // FloatingActionButton widget
    register('FloatingActionButton', (args, children) {
      final onPressed = args['onPressed'];
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);
      final backgroundColor = FluxCast.toColor(args['backgroundColor']);
      final tooltip = FluxCast.toStringNullable(args['tooltip']);
      final mini = FluxCast.toBool(args['mini']);

      return FloatingActionButton(
        onPressed:
            onPressed is Function ? () => _invokeCallback(onPressed, []) : null,
        backgroundColor: backgroundColor,
        tooltip: tooltip,
        mini: mini,
        child: child,
      );
    });

    // BottomNavigationBar widget
    register('BottomNavigationBar', (args, children) {
      final itemsRaw = args['items'] as List?;
      final currentIndex = FluxCast.toInt(args['currentIndex']) ?? 0;
      final onTap = args['onTap'];
      final backgroundColor = FluxCast.toColor(args['backgroundColor']);
      final selectedItemColor = FluxCast.toColor(args['selectedItemColor']);
      final unselectedItemColor = FluxCast.toColor(args['unselectedItemColor']);
      final typeStr = FluxCast.toStringNullable(args['type']);

      List<BottomNavigationBarItem> items = [];
      if (itemsRaw != null) {
        for (final item in itemsRaw) {
          if (item is Map) {
            final icon = item['icon'] as Widget?;
            final label = FluxCast.toStr(item['label']);
            final activeIcon = item['activeIcon'] as Widget?;
            if (icon != null) {
              items.add(BottomNavigationBarItem(
                icon: icon,
                label: label,
                activeIcon: activeIcon,
              ));
            }
          }
        }
      }

      return BottomNavigationBar(
        items: items,
        currentIndex: currentIndex,
        onTap: onTap is Function
            ? (index) => _invokeCallback(onTap, [index])
            : null,
        backgroundColor: backgroundColor,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,
        type: typeStr == 'shifting'
            ? BottomNavigationBarType.shifting
            : BottomNavigationBarType.fixed,
      );
    });

    // BottomNavigationBarItem helper (returns a Map for use in items list)
    registerFunction('BottomNavItem', (args) {
      final icon = args.isNotEmpty ? args[0] : null;
      final label = args.length > 1 ? FluxCast.toStr(args[1]) : '';
      final activeIcon = args.length > 2 ? args[2] : null;
      return {
        'icon': icon,
        'label': label,
        'activeIcon': activeIcon,
      };
    });

    // ListTile widget - Common list item
    register('ListTile', (args, children) {
      final titleRaw = args['title'];
      final subtitleRaw = args['subtitle'];
      final leading = args['leading'] as Widget?;
      final trailing = args['trailing'] as Widget?;
      final onTap = args['onTap'];
      final dense = FluxCast.toBool(args['dense']);
      final enabled = args['enabled'] != false;

      Widget? title;
      if (titleRaw is Widget) {
        title = titleRaw;
      } else if (titleRaw != null) {
        title = Text(titleRaw.toString());
      }

      Widget? subtitle;
      if (subtitleRaw is Widget) {
        subtitle = subtitleRaw;
      } else if (subtitleRaw != null) {
        subtitle = Text(subtitleRaw.toString());
      }

      return ListTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        onTap: onTap is Function ? () => _invokeCallback(onTap, []) : null,
        dense: dense,
        enabled: enabled,
      );
    });

    // Divider widget
    register('Divider', (args, children) {
      final height = FluxCast.toDoubleNullable(args['height']);
      final thickness = FluxCast.toDoubleNullable(args['thickness']);
      final indent = FluxCast.toDoubleNullable(args['indent']);
      final endIndent = FluxCast.toDoubleNullable(args['endIndent']);
      final color = FluxCast.toColor(args['color']);

      return Divider(
        height: height,
        thickness: thickness,
        indent: indent,
        endIndent: endIndent,
        color: color,
      );
    });

    // ========== Animation Widgets ==========

    // AnimatedContainer widget
    register('AnimatedContainer', (args, children) {
      final duration = FluxCast.toInt(args['duration']) ?? 300;
      final padding = _parseEdgeInsets(args['padding']);
      final margin = _parseEdgeInsets(args['margin']);
      final color = FluxCast.toColor(args['color']);
      final decoration = _parseBoxDecoration(args['decoration']);
      final width = FluxCast.toDoubleNullable(args['width']);
      final height = FluxCast.toDoubleNullable(args['height']);
      final alignment = _parseAlignment(args['alignment']);
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);

      return AnimatedContainer(
        duration: Duration(milliseconds: duration),
        padding: padding,
        margin: margin,
        color: decoration == null ? color : null,
        decoration: decoration,
        width: width,
        height: height,
        alignment: alignment,
        child: child,
      );
    });

    // AnimatedOpacity widget
    register('AnimatedOpacity', (args, children) {
      final opacity = FluxCast.toDouble(args['opacity']) ?? 1.0;
      final duration = FluxCast.toInt(args['duration']) ?? 300;
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);

      return AnimatedOpacity(
        opacity: opacity.clamp(0.0, 1.0),
        duration: Duration(milliseconds: duration),
        child: child ?? const SizedBox.shrink(),
      );
    });

    // AnimatedSwitcher widget
    register('AnimatedSwitcher', (args, children) {
      final duration = FluxCast.toInt(args['duration']) ?? 300;
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);

      return AnimatedSwitcher(
        duration: Duration(milliseconds: duration),
        child: child,
      );
    });

    // ========== Input Widgets ==========

    // Slider widget
    register('Slider', (args, children) {
      final value = FluxCast.toDouble(args['value']) ?? 0.0;
      final min = FluxCast.toDouble(args['min']) ?? 0.0;
      final max = FluxCast.toDouble(args['max']) ?? 1.0;
      final divisions = FluxCast.toIntNullable(args['divisions']);
      final label = FluxCast.toStringNullable(args['label']);
      final onChanged = args['onChanged'];
      final activeColor = FluxCast.toColor(args['activeColor']);
      final inactiveColor = FluxCast.toColor(args['inactiveColor']);

      return Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        label: label,
        onChanged: onChanged is Function
            ? (v) => _invokeCallback(onChanged, [v])
            : null,
// ignore: deprecated_member_use
        activeColor: activeColor,
        inactiveColor: inactiveColor,
      );
    });

    // DropdownButton widget (simplified - uses String values)
    register('DropdownButton', (args, children) {
      final value = FluxCast.toStringNullable(args['value']);
      final itemsRaw = args['items'] as List?;
      final onChanged = args['onChanged'];
      final hint = args['hint'];
      final isExpanded = FluxCast.toBool(args['isExpanded']);

      List<DropdownMenuItem<String>> items = [];
      if (itemsRaw != null) {
        for (final item in itemsRaw) {
          final itemStr = item.toString();
          items.add(DropdownMenuItem(
            value: itemStr,
            child: Text(itemStr),
          ));
        }
      }

      Widget? hintWidget;
      if (hint is Widget) {
        hintWidget = hint;
      } else if (hint != null) {
        hintWidget = Text(hint.toString());
      }

      return DropdownButton<String>(
        value: items.any((i) => i.value == value) ? value : null,
        items: items,
        onChanged: onChanged is Function
            ? (v) => _invokeCallback(onChanged, [v])
            : null,
        hint: hintWidget,
        isExpanded: isExpanded,
      );
    });

    // Radio widget
    register('Radio', (args, children) {
      final value = args['value'];
      final groupValue = args['groupValue'];
      final onChanged = args['onChanged'];
      final activeColor = FluxCast.toColor(args['activeColor']);

      return Radio<dynamic>(
        value: value,
        // ignore: deprecated_member_use
        groupValue: groupValue,
        // ignore: deprecated_member_use
        onChanged: onChanged is Function
            ? (v) => _invokeCallback(onChanged, [v])
            : null,
        // ignore: deprecated_member_use
        activeColor: activeColor,
      );
    });

    // RadioListTile widget
    register('RadioListTile', (args, children) {
      final value = args['value'];
      // groupValue and onChanged are handled by parent RadioGroup or custom logic in Flux
      // For now, we bind 'value' and 'groupValue' directly if provided
      final groupValue = args['groupValue'];
      final onChanged = args['onChanged'];
      final titleRaw = args['title'];
      final subtitleRaw = args['subtitle'];
      final activeColor = FluxCast.toColor(args['activeColor']);
      final dense = FluxCast.toBool(args['dense']);

      Widget? title;
      if (titleRaw is Widget) {
        title = titleRaw;
      } else if (titleRaw != null) {
        title = Text(titleRaw.toString());
      }

      Widget? subtitle;
      if (subtitleRaw is Widget) {
        subtitle = subtitleRaw;
      } else if (subtitleRaw != null) {
        subtitle = Text(subtitleRaw.toString());
      }

      return RadioListTile<dynamic>(
        value: value,
        // ignore: deprecated_member_use
        groupValue: groupValue,
        // ignore: deprecated_member_use
        onChanged: onChanged is Function
            ? (v) => _invokeCallback(onChanged, [v])
            : null,
        title: title,
        subtitle: subtitle,
// ignore: deprecated_member_use
        activeColor: activeColor,
        dense: dense,
      );
    });

    // CheckboxListTile widget
    register('CheckboxListTile', (args, children) {
      final value = FluxCast.toBool(args['value']);
      final onChanged = args['onChanged'];
      final titleRaw = args['title'];
      final subtitleRaw = args['subtitle'];
      final activeColor = FluxCast.toColor(args['activeColor']);
      final dense = FluxCast.toBool(args['dense']);

      Widget? title;
      if (titleRaw is Widget) {
        title = titleRaw;
      } else if (titleRaw != null) {
        title = Text(titleRaw.toString());
      }

      Widget? subtitle;
      if (subtitleRaw is Widget) {
        subtitle = subtitleRaw;
      } else if (subtitleRaw != null) {
        subtitle = Text(subtitleRaw.toString());
      }

      return CheckboxListTile(
        value: value,
        onChanged: onChanged is Function
            ? (v) => _invokeCallback(onChanged, [v])
            : null,
        title: title,
        subtitle: subtitle,
// ignore: deprecated_member_use
        activeColor: activeColor,
        dense: dense,
      );
    });

    // SwitchListTile widget
    register('SwitchListTile', (args, children) {
      final value = FluxCast.toBool(args['value']);
      final onChanged = args['onChanged'];
      final titleRaw = args['title'];
      final subtitleRaw = args['subtitle'];
      final activeColor = FluxCast.toColor(args['activeColor']);
      final dense = FluxCast.toBool(args['dense']);

      Widget? title;
      if (titleRaw is Widget) {
        title = titleRaw;
      } else if (titleRaw != null) {
        title = Text(titleRaw.toString());
      }

      Widget? subtitle;
      if (subtitleRaw is Widget) {
        subtitle = subtitleRaw;
      } else if (subtitleRaw != null) {
        subtitle = Text(subtitleRaw.toString());
      }

      return SwitchListTile(
        value: value,
        onChanged: onChanged is Function
            ? (v) => _invokeCallback(onChanged, [v])
            : null,
        title: title,
        subtitle: subtitle,
        // ignore: deprecated_member_use
        activeColor: activeColor,
        dense: dense,
      );
    });

    // Card widget
    register('Card', (args, children) {
      final color = FluxCast.toColor(args['color']);
      final elevation = FluxCast.toDoubleNullable(args['elevation']);
      final margin = _parseEdgeInsets(args['margin']);
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);

      return Card(
        color: color,
        elevation: elevation,
        margin: margin,
        child: child,
      );
    });

    // CircularProgressIndicator widget
    register('CircularProgressIndicator', (args, children) {
      final value = FluxCast.toDoubleNullable(args['value']);
      final color = FluxCast.toColor(args['color']);
      final backgroundColor = FluxCast.toColor(args['backgroundColor']);
      final strokeWidth = FluxCast.toDouble(args['strokeWidth']) ?? 4.0;

      return CircularProgressIndicator(
        value: value,
        color: color,
        backgroundColor: backgroundColor,
        strokeWidth: strokeWidth,
      );
    });

    // LinearProgressIndicator widget
    register('LinearProgressIndicator', (args, children) {
      final value = FluxCast.toDoubleNullable(args['value']);
      final color = FluxCast.toColor(args['color']);
      final backgroundColor = FluxCast.toColor(args['backgroundColor']);
      final minHeight = FluxCast.toDoubleNullable(args['minHeight']);

      return LinearProgressIndicator(
        value: value,
        color: color,
        backgroundColor: backgroundColor,
        minHeight: minHeight,
      );
    });

    // Chip widget
    register('Chip', (args, children) {
      final labelRaw = args['label'];
      final avatar = args['avatar'] as Widget?;
      final deleteIcon = args['deleteIcon'] as Widget?;
      final onDeleted = args['onDeleted'];
      final backgroundColor = FluxCast.toColor(args['backgroundColor']);
      final padding = _parseEdgeInsets(args['padding']);

      Widget label;
      if (labelRaw is Widget) {
        label = labelRaw;
      } else {
        label = Text(labelRaw?.toString() ?? '');
      }

      return Chip(
        label: label,
        avatar: avatar,
        deleteIcon: deleteIcon,
        onDeleted:
            onDeleted is Function ? () => _invokeCallback(onDeleted, []) : null,
        backgroundColor: backgroundColor,
        padding: padding,
      );
    });

    // ========== Tab Widgets ==========

    // DefaultTabController - Wrapper for TabBar/TabBarView
    register('DefaultTabController', (args, children) {
      final length = FluxCast.toInt(args['length']) ?? 2;
      final initialIndex = FluxCast.toInt(args['initialIndex']) ?? 0;
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);

      return DefaultTabController(
        length: length,
        initialIndex: initialIndex,
        child: child ?? const SizedBox.shrink(),
      );
    });

    // TabBar widget
    register('TabBar', (args, children) {
      final tabsRaw = args['tabs'] as List?;
      final isScrollable = FluxCast.toBool(args['isScrollable']);
      final indicatorColor = FluxCast.toColor(args['indicatorColor']);
      final labelColor = FluxCast.toColor(args['labelColor']);
      final unselectedLabelColor =
          FluxCast.toColor(args['unselectedLabelColor']);
      final onTap = args['onTap'];

      List<Widget> tabs = [];
      if (tabsRaw != null) {
        for (final tab in tabsRaw) {
          if (tab is Widget) {
            tabs.add(tab);
          } else if (tab is String) {
            tabs.add(Tab(text: tab));
          } else if (tab is Map) {
            final text = FluxCast.toStringNullable(tab['text']);
            final icon = tab['icon'] as Widget?;
            tabs.add(Tab(text: text, icon: icon));
          }
        }
      } else {
        // Use children as tabs
        tabs = children.whereType<Widget>().toList();
      }

      return TabBar(
        tabs: tabs,
        isScrollable: isScrollable,
        indicatorColor: indicatorColor,
        labelColor: labelColor,
        unselectedLabelColor: unselectedLabelColor,
        onTap: onTap is Function
            ? (index) => _invokeCallback(onTap, [index])
            : null,
      );
    });

    // Tab widget helper
    register('Tab', (args, children) {
      final text = FluxCast.toStringNullable(args['text'] ?? args['0']);
      final icon = args['icon'] as Widget?;
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);

      return Tab(
        text: text,
        icon: icon,
        child: child,
      );
    });

    // TabBarView widget
    register('TabBarView', (args, children) {
      final childrenRaw = args['children'] as List?;

      List<Widget> tabChildren = [];
      if (childrenRaw != null) {
        tabChildren = childrenRaw.whereType<Widget>().toList();
      } else {
        tabChildren = children.whereType<Widget>().toList();
      }

      return TabBarView(
        children: tabChildren,
      );
    });

    // ========== Hero Animation ==========

    // Hero widget for shared element transitions
    register('Hero', (args, children) {
      final tag = args['tag']?.toString() ??
          'hero_${DateTime.now().millisecondsSinceEpoch}';
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);

      return Hero(
        tag: tag,
        child: child ?? const SizedBox.shrink(),
      );
    });

    // ========== Implicit Animations ==========

    register('AnimatedOpacity', (args, children) {
      final key = args['key'] != null ? ValueKey(args['key']) : null;
      final opacity = FluxCast.toDouble(args['opacity']) ?? 1.0;
      final duration = FluxCast.toInt(args['duration']) ?? 250;
      final curve = _parseCurve(args['curve']) ?? Curves.linear;
      final child = args['child'] as Widget? ?? (children.isNotEmpty ? children.first : null);

      return AnimatedOpacity(
        key: key,
        opacity: opacity,
        duration: Duration(milliseconds: duration),
        curve: curve,
        child: child,
      );
    });

    register('AnimatedContainer', (args, children) {
      final key = args['key'] != null ? ValueKey(args['key']) : null;
      final duration = FluxCast.toInt(args['duration']) ?? 250;
      final curve = _parseCurve(args['curve']) ?? Curves.linear;
      
      final width = FluxCast.toDouble(args['width']);
      final height = FluxCast.toDouble(args['height']);
      final color = FluxCast.toColor(args['color']);
      final padding = FluxCast.toEdgeInsets(args['padding']);
      final margin = FluxCast.toEdgeInsets(args['margin']);
      final alignment = FluxCast.toAlignment(args['alignment']);
      final child = args['child'] as Widget? ?? (children.isNotEmpty ? children.first : null);

      return AnimatedContainer(
        key: key,
        duration: Duration(milliseconds: duration),
        curve: curve,
        width: width,
        height: height,
        color: color,
        padding: padding,
        margin: margin,
        alignment: alignment,
        child: child,
      );
    });

    // ========== Date/Time Pickers (as functions) ==========
    // Note: These are registered as functions since they return Futures
  }

  // ========== Date/Time Picker Functions ==========

  static void _initDateTimePickers() {
    // showDatePicker function
    registerFunction('showDatePicker', (args) async {
      final context = _currentContext;
      if (context == null) return null;

      final initialDate =
          _parseDate(args.isNotEmpty ? args[0] : null) ?? DateTime.now();
      final firstDate =
          _parseDate(args.length > 1 ? args[1] : null) ?? DateTime(2000);
      final lastDate =
          _parseDate(args.length > 2 ? args[2] : null) ?? DateTime(2100);

      final result = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );

      return result?.toIso8601String();
    });

    // showTimePicker function
    registerFunction('showTimePicker', (args) async {
      final context = _currentContext;
      if (context == null) return null;

      final hour = args.isNotEmpty ? FluxCast.toInt(args[0]) ?? 12 : 12;
      final minute = args.length > 1 ? FluxCast.toInt(args[1]) ?? 0 : 0;

      final result = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: hour, minute: minute),
      );

      if (result != null) {
        return {'hour': result.hour, 'minute': result.minute};
      }
      return null;
    });
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Current build context for dialogs/pickers
  static BuildContext? _currentContext;

  /// Set the current build context (called by FluxWidget before building)
  static void setContext(BuildContext context) {
    _currentContext = context;
  }

  // ========== Form Widgets ==========

  static void _initFormWidgets() {
    // Form widget
    register('Form', (args, children) {
      final child = args['child'] as Widget? ??
          (children.isNotEmpty ? children.first : null);
      final autovalidateMode = args['autovalidateMode']?.toString();

      AutovalidateMode mode = AutovalidateMode.disabled;
      if (autovalidateMode == 'always') {
        mode = AutovalidateMode.always;
      } else if (autovalidateMode == 'onUserInteraction') {
        mode = AutovalidateMode.onUserInteraction;
      }

      return Form(
        autovalidateMode: mode,
        child: child ?? const SizedBox.shrink(),
      );
    });

    // TextFormField widget
    register('TextFormField', (args, children) {
      final hint = FluxCast.toStringNullable(args['hint']);
      final label = FluxCast.toStringNullable(args['label']);
      final initialValue = FluxCast.toStringNullable(args['initialValue']);
      final obscureText = FluxCast.toBool(args['obscureText']);
      final keyboardType =
          _parseKeyboardType(FluxCast.toStringNullable(args['keyboardType']));
      final onChanged = args['onChanged'];
      final onSaved = args['onSaved'];
      final validator = args['validator'];
      final maxLines = FluxCast.toInt(args['maxLines']) ?? 1;
      final enabled = args['enabled'] != false;

      return TextFormField(
        initialValue: initialValue,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled,
        decoration: InputDecoration(
          hintText: hint,
          labelText: label,
        ),
        onChanged: onChanged is Function
            ? (v) => _invokeCallback(onChanged, [v])
            : null,
        onSaved:
            onSaved is Function ? (v) => _invokeCallback(onSaved, [v]) : null,
        validator: validator is Function
            ? (v) {
                final result = validator([v]);
                if (result is String) return result;
                return null;
              }
            : null,
      );
    });

    // DropdownButtonFormField widget
    register('DropdownButtonFormField', (args, children) {
      final value = FluxCast.toStringNullable(args['value']);
      final itemsRaw = args['items'] as List?;
      final onChanged = args['onChanged'];
      final onSaved = args['onSaved'];
      final hint = args['hint'];
      final label = FluxCast.toStringNullable(args['label']);
      final validator = args['validator'];

      List<DropdownMenuItem<String>> items = [];
      if (itemsRaw != null) {
        for (final item in itemsRaw) {
          final itemStr = item.toString();
          items.add(DropdownMenuItem(
            value: itemStr,
            child: Text(itemStr),
          ));
        }
      }

      Widget? hintWidget;
      if (hint is Widget) {
        hintWidget = hint;
      } else if (hint != null) {
        hintWidget = Text(hint.toString());
      }

      return DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: items.any((i) => i.value == value) ? value : null,
        items: items,
        onChanged: onChanged is Function
            ? (v) => _invokeCallback(onChanged, [v])
            : null,
        onSaved:
            onSaved is Function ? (v) => _invokeCallback(onSaved, [v]) : null,
        hint: hintWidget,
        decoration: InputDecoration(
          labelText: label,
        ),
        validator: validator is Function
            ? (v) {
                final result = validator([v]);
                if (result is String) return result;
                return null;
              }
            : null,
      );
    });
  }

  static TextInputType? _parseKeyboardType(String? type) {
    if (type == null) return null;
    switch (type.toLowerCase()) {
      case 'email':
        return TextInputType.emailAddress;
      case 'number':
        return TextInputType.number;
      case 'phone':
        return TextInputType.phone;
      case 'url':
        return TextInputType.url;
      case 'multiline':
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
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
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'none':
        return BoxFit.none;
      case 'scaleDown':
        return BoxFit.scaleDown;
      default:
        return BoxFit.contain;
    }
  }

  // Parse Curve
  static Curve? _parseCurve(dynamic value) {
    if (value == null) return null;
    final name = value.toString();
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
        case 100:
          return FontWeight.w100;
        case 200:
          return FontWeight.w200;
        case 300:
          return FontWeight.w300;
        case 400:
          return FontWeight.w400;
        case 500:
          return FontWeight.w500;
        case 600:
          return FontWeight.w600;
        case 700:
          return FontWeight.w700;
        case 800:
          return FontWeight.w800;
        case 900:
          return FontWeight.w900;
      }
    }
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'bold':
          return FontWeight.bold;
        case 'normal':
          return FontWeight.normal;
        case 'w100':
          return FontWeight.w100;
        case 'w200':
          return FontWeight.w200;
        case 'w300':
          return FontWeight.w300;
        case 'w400':
          return FontWeight.w400;
        case 'w500':
          return FontWeight.w500;
        case 'w600':
          return FontWeight.w600;
        case 'w700':
          return FontWeight.w700;
        case 'w800':
          return FontWeight.w800;
        case 'w900':
          return FontWeight.w900;
      }
    }
    return null;
  }

  static FontStyle? _parseFontStyle(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'italic':
          return FontStyle.italic;
        case 'normal':
          return FontStyle.normal;
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
      if (value.containsKey('all')) {
        return EdgeInsets.all(FluxCast.toDoubleOrZero(value['all']));
      }
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
      case 'start':
        return MainAxisAlignment.start;
      case 'end':
        return MainAxisAlignment.end;
      case 'center':
        return MainAxisAlignment.center;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  static TextInputType? _parseTextInputType(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'text':
          return TextInputType.text;
        case 'number':
          return TextInputType.number;
        case 'email':
          return TextInputType.emailAddress;
        case 'phone':
          return TextInputType.phone;
        case 'multiline':
          return TextInputType.multiline;
        case 'url':
          return TextInputType.url;
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
        case 'none':
          return InputBorder.none;
        case 'outline':
          return const OutlineInputBorder();
        case 'underline':
          return const UnderlineInputBorder();
      }
    }
    if (value is Map) {
      // Custom border support could go here (radius, borderSide)
      // For now, simple types
      final type = value['type'];
      if (type == 'outline') {
        return OutlineInputBorder(
          borderRadius: _parseBorderRadius(value['borderRadius']) ??
              const BorderRadius.all(Radius.circular(4.0)),
          borderSide:
              _parseBorderSide(value['borderSide']) ?? const BorderSide(),
        );
      }
      if (type == 'underline') {
        return UnderlineInputBorder(
          borderSide:
              _parseBorderSide(value['borderSide']) ?? const BorderSide(),
        );
      }
    }
    return null;
  }

  static BorderSide? _parseBorderSide(dynamic value) {
    if (value is! Map) return null;
    return BorderSide(
      color: FluxCast.toColor(value['color']) ?? const Color(0xFF000000),
      width: FluxCast.toDoubleOrZero(value['width']) > 0
          ? FluxCast.toDoubleOrZero(value['width'])
          : 1.0,
      style: BorderStyle.solid,
    );
  }

  static AlignmentGeometry? _parseAlignment(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'topleft':
          return Alignment.topLeft;
        case 'topcenter':
          return Alignment.topCenter;
        case 'topright':
          return Alignment.topRight;
        case 'centerleft':
          return Alignment.centerLeft;
        case 'center':
          return Alignment.center;
        case 'centerright':
          return Alignment.centerRight;
        case 'bottomleft':
          return Alignment.bottomLeft;
        case 'bottomcenter':
          return Alignment.bottomCenter;
        case 'bottomright':
          return Alignment.bottomRight;
      }
    }
    return null;
  }

  static WrapAlignment? _parseWrapAlignment(dynamic value) {
    if (value is String) {
      switch (value.toLowerCase()) {
        case 'start':
          return WrapAlignment.start;
        case 'end':
          return WrapAlignment.end;
        case 'center':
          return WrapAlignment.center;
        case 'spacebetween':
          return WrapAlignment.spaceBetween;
        case 'spacearound':
          return WrapAlignment.spaceAround;
        case 'spaceevenly':
          return WrapAlignment.spaceEvenly;
      }
    }
    return null;
  }

  static CrossAxisAlignment _parseCrossAxisAlignment(String? value) {
    switch (value) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'end':
        return CrossAxisAlignment.end;
      case 'center':
        return CrossAxisAlignment.center;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'baseline':
        return CrossAxisAlignment.baseline;
      default:
        return CrossAxisAlignment.center;
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
      return navigatorKey.currentState
          ?.pushNamed(routeName, arguments: routeArgs);
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

      return navigatorKey.currentState
          ?.pushNamed(routeName, arguments: routeArgs);
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

    // BoxDecoration helper - returns a Map that _parseBoxDecoration can interpret
    registerFunction('BoxDecoration', (args) {
      // This is a metadata map, not a Flutter object
      // The actual parsing happens in the Container binding via _parseBoxDecoration
      final namedArgs = args.isNotEmpty && args[0] is Map ? args[0] as Map : {};
      return {
        'color': namedArgs['color'],
        'borderRadius': namedArgs['borderRadius'],
        'border': namedArgs['border'],
        'boxShadow': namedArgs['boxShadow'],
      };
    });

    // BorderRadius.circular helper - returns a number for _parseBorderRadius
    registerFunction('BorderRadius.circular', (args) {
      if (args.isNotEmpty && args[0] is num) {
        return args[0]!;
      }
      return 0.0;
    });

    // Offset helper for BoxShadow
    registerFunction('Offset', (args) {
      final dx = args.isNotEmpty ? FluxCast.toDoubleOrZero(args[0]) : 0.0;
      final dy = args.length > 1 ? FluxCast.toDoubleOrZero(args[1]) : 0.0;
      return {'dx': dx, 'dy': dy};
    });

    // BoxShadow helper
    registerFunction('BoxShadow', (args) {
      final namedArgs = args.isNotEmpty && args[0] is Map ? args[0] as Map : {};
      return {
        'color': namedArgs['color'],
        'blurRadius': namedArgs['blurRadius'],
        'offset': namedArgs['offset'],
      };
    });

    // TextStyle helper
    registerFunction('TextStyle', (args) {
      final namedArgs = args.isNotEmpty && args[0] is Map ? args[0] as Map : {};
      // Pass through the map for _parseTextStyle to handle
      return namedArgs;
    });
  }

  // ========== Camera Widgets ==========

  static void _initCameraWidgets() {
    register('CameraPreview', (args, children) {
      return const FluxCameraPreview();
    });
  }

  static void _initFluxUiWidgets() {
    // FluxButton
    register('FluxButton', (args, children) {
      final label = args['label'] as String? ?? args['text'] as String?;
      final iconName = args['icon'] as String?;
      final onTap = args['onTap'];
      final variantStr = args['variant'] as String?;
      final sizeStr = args['size'] as String?;
      final isLoading = FluxCast.toBool(args['isLoading']);
      final isDisabled = FluxCast.toBool(args['isDisabled']);
      final isFullWidth = FluxCast.toBool(args['isFullWidth']);

      final variant = FluxButtonVariant.values.firstWhere(
        (e) => e.name == variantStr,
        orElse: () => FluxButtonVariant.primary,
      );

      final size = FluxButtonSize.values.firstWhere(
        (e) => e.name == sizeStr,
        orElse: () => FluxButtonSize.md,
      );

      return FluxButton(
        label: label,
        icon: iconName != null ? _parseIconData(iconName) : null,
        onTap: onTap is Function ? () => _invokeCallback(onTap, []) : null,
        variant: variant,
        size: size,
        isLoading: isLoading,
        isDisabled: isDisabled,
        isFullWidth: isFullWidth,
      );
    });

    // FluxInput
    register('FluxInput', (args, children) {
      final initialValue =
          args['initialValue'] as String? ?? args['value'] as String?;
      final onChanged = args['onChanged'];
      final onSubmitted = args['onSubmitted'];
      final label = args['label'] as String?;
      final hint = args['hint'] as String?;
      final errorText = args['errorText'] as String?;
      final prefixIconName = args['prefixIcon'] as String?;
      final suffixIconName = args['suffixIcon'] as String?;
      final typeStr = args['type'] as String?;
      final enabled = args['enabled'] != false;
      final autofocus = FluxCast.toBool(args['autofocus']);
      final showClearButton = FluxCast.toBool(args['showClearButton']);

      final type = FluxInputType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => FluxInputType.text,
      );

      return FluxInput(
        initialValue: initialValue,
        onChanged: onChanged != null
            ? (val) => _invokeCallback(onChanged, [val])
            : null,
        onSubmitted: onSubmitted != null
            ? (val) => _invokeCallback(onSubmitted, [val])
            : null,
        label: label,
        hint: hint,
        errorText: errorText,
        prefixIcon:
            prefixIconName != null ? _parseIconData(prefixIconName) : null,
        suffixIcon:
            suffixIconName != null ? _parseIconData(suffixIconName) : null,
        type: type,
        enabled: enabled,
        autofocus: autofocus,
        showClearButton: showClearButton,
      );
    });

    // FluxCard
    register('FluxCard', (args, children) {
      final variantStr = args['variant'] as String?;
      final padding = _parseEdgeInsets(args['padding']);
      final onTap = args['onTap'];
      final backgroundColor = FluxCast.toColor(args['backgroundColor']);

      final variant = FluxCardVariant.values.firstWhere(
        (e) => e.name == variantStr,
        orElse: () => FluxCardVariant.elevated,
      );

      return FluxCard(
        variant: variant,
        padding: padding,
        onTap: onTap is Function ? () => _invokeCallback(onTap, []) : null,
        backgroundColor: backgroundColor,
        child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
      );
    });

    // FluxBadge
    register('FluxBadge', (args, children) {
      final variantStr = args['variant'] as String?;
      final label = args['label'] as String?;
      final count = FluxCast.toInt(args['count']);
      final color = FluxCast.toColor(args['color']);
      final textColor = FluxCast.toColor(args['textColor']);
      final alignment = _parseAlignment(args['alignment']) as Alignment? ??
          Alignment.topRight;
      // Offset parsing simplified for standard cases, assuming simple x,y overrides if needed
      // Not exposing full offset map for now to keep it simple, defaulting to standard

      final variant = FluxBadgeVariant.values.firstWhere(
        (e) => e.name == variantStr,
        orElse: () => FluxBadgeVariant.dot,
      );

      return FluxBadge(
        variant: variant,
        label: label,
        count: count,
        color: color,
        textColor: textColor,
        alignment: alignment,
        child: children.isNotEmpty ? children.first : null,
      );
    });

    // FluxRow
    register('FluxRow', (args, children) {
      final mainAxisAlignment = _parseMainAxisAlignment(
          FluxCast.toStringNullable(args['mainAxisAlignment']));
      final crossAxisAlignment = _parseCrossAxisAlignment(
          FluxCast.toStringNullable(args['crossAxisAlignment']));
      final spacing = FluxCast.toDoubleNullable(args['spacing']);

      return FluxRow(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        spacing: spacing,
        children: children,
      );
    });

    // FluxColumn
    register('FluxColumn', (args, children) {
      final mainAxisAlignment = _parseMainAxisAlignment(
          FluxCast.toStringNullable(args['mainAxisAlignment']));
      final crossAxisAlignment = _parseCrossAxisAlignment(
          FluxCast.toStringNullable(args['crossAxisAlignment']));
      final spacing = FluxCast.toDoubleNullable(args['spacing']);

      return FluxColumn(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        spacing: spacing,
        children: children,
      );
    });

    // FluxStack
    register('FluxStack', (args, children) {
      final alignment =
          _parseAlignment(args['alignment']) ?? AlignmentDirectional.topStart;
      return FluxStack(
        alignment: alignment,
        children: children,
      );
    });

    // FluxGrid
    register('FluxGrid', (args, children) {
      final spacing =
          FluxCast.toDoubleNullable(args['spacing']) ?? FluxSpacing.md;
      final runSpacing =
          FluxCast.toDoubleNullable(args['runSpacing']) ?? FluxSpacing.md;
      final crossAxisCount = FluxCast.toInt(args['crossAxisCount']);
      final maxCrossAxisExtent =
          FluxCast.toDoubleNullable(args['maxCrossAxisExtent']);

      return FluxGrid(
        spacing: spacing,
        runSpacing: runSpacing,
        crossAxisCount: crossAxisCount,
        maxCrossAxisExtent: maxCrossAxisExtent,
        children: children,
      );
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

/// Represents a Future that can be passed to/from Flux scripts
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
