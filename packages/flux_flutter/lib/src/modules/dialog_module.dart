import 'package:flutter/material.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:flux_flutter/src/flux_context.dart';

class DialogModule extends FluxModule {
  DialogModule() : super('dialog') {
    register('alert', AsyncNativeFunction('dialog.alert', 1, _alert));
    register('confirm', AsyncNativeFunction('dialog.confirm', 1, _confirm));
    register('toast', NativeFunction('dialog.toast', 1, _toast));
  }

  Future<Object?> _alert(List<Object?> args) async {
    final message = args.isNotEmpty ? args[0].toString() : '';
    final title = args.length > 1 ? args[1].toString() : 'Alert';

    final context = fluxNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('Flux DialogModule: No context available for alert.');
      return null;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
    return null;
  }

  Future<Object?> _confirm(List<Object?> args) async {
    final message = args.isNotEmpty ? args[0].toString() : 'Confirm?';
    final title = args.length > 1 ? args[1].toString() : 'Confirm';

    final context = fluxNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('Flux DialogModule: No context available for confirm.');
      return false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("OK"),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Object? _toast(List<Object?> args) {
    final message = args.isNotEmpty ? args[0].toString() : '';
    final context = fluxNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('Flux DialogModule: No context available for toast.');
      return null;
    }

    // Attempt to find ScaffoldMessenger
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      debugPrint('Flux DialogModule: Failed to show toast: $e');
    }
    return null;
  }
}

