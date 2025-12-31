import 'package:flutter/material.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'package:flux_vm/flux_vm.dart';
import 'server.dart';

/// A wrapper widget that connects to a Flux Hot Reload server and updates the
/// underlying FluxWidget when code changes.
class FluxHotReloadWidget extends StatefulWidget {
  final String host;
  final String initialSource;
  final String widgetName;
  final FluxRuntime runtime;

  const FluxHotReloadWidget({
    Key? key,
    this.host = 'ws://localhost:8080',
    required this.initialSource,
    required this.widgetName,
    required this.runtime,
  }) : super(key: key);

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
      print('🔥 Flux Hot Reload: Received update (${source.length} bytes)');

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
            // We need a way to swap the chunk in the runtime
            // For now, we assume the runtime has a `hotReload` method
            // or we just re-run the chunk if it's safe.
            // But optimal way is to swap code while keeping state.
            
            // For MVP: We just re-execute the chunk to update declarations
            // This might reset global state if not careful, but `hotReload`
            // method in VM should handle "update declarations but keep data".
            widget.runtime.hotReload(function.chunk);
          });
        }
      } catch (e) {
        print('❌ Hot Reload Error: $e');
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
