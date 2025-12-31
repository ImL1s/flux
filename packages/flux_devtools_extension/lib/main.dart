import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'src/flux_debugger_screen.dart';

void main() {
  runApp(const FluxDevToolsExtensionApp());
}

class FluxDevToolsExtensionApp extends StatelessWidget {
  const FluxDevToolsExtensionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(
      child: FluxDebuggerScreen(),
    );
  }
}
