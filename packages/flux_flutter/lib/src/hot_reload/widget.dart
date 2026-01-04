import 'package:flutter/material.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'server.dart';

/// A wrapper widget that connects to a Flux Hot Reload server and updates the
/// underlying FluxWidget when code changes.
class FluxHotReloadWidget extends StatefulWidget {
  final String host;
  final String initialSource;
  final String widgetName;
  final FluxRuntime runtime;

  const FluxHotReloadWidget({
    super.key,
    this.host = 'ws://localhost:8080',
    required this.initialSource,
    required this.widgetName,
    required this.runtime,
  });

  @override
  State<FluxHotReloadWidget> createState() => _FluxHotReloadWidgetState();
}

class _FluxHotReloadWidgetState extends State<FluxHotReloadWidget> {
  late HotReloadServer _server;
  String? _parseError;

  @override
  void initState() {
    super.initState();
    _startHotReload();
  }

  void _startHotReload() {
    _server = HotReloadServer(onHotReload: _handleHotReload);
    // Connect to the dev server
    _server.connectTo(widget.host);
  }

  void _handleHotReload(Map<String, dynamic> data) async {
    if (data['type'] == 'reload') {
      final source = data['content'] as String;
      debugPrint('🔥 Flux Hot Reload: Received update (${source.length} bytes)');

      try {
        // 1. Compile new source
        final tokens = Lexer(source).tokenize();
        final parser = Parser(tokens);
        final unit = parser.parse();
        final compiler = Compiler(unit: unit);
        final function = compiler.endCompiler();

        // 2. Update Runtime
        if (mounted) {
          setState(() {
            _parseError = null;
            // Use the hotReload method on runtime
            widget.runtime.hotReload(function.chunk);
          });
        }
      } catch (e) {
        debugPrint('❌ Hot Reload Error: $e');
        if (mounted) {
          setState(() {
            _parseError = e.toString();
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _server.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_parseError != null) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red.shade50,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text('Flux Compilation Error', 
                    style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_parseError!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return FluxWidget(
      runtime: widget.runtime,
      widgetName: widget.widgetName,
    );
  }
}
