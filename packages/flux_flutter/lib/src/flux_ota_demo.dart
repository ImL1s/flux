import 'package:flutter/material.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_flutter/flux_flutter.dart';

/// Widget that demonstrates OTA updates with FluxRuntime.
///
/// This widget simulates the OTA update workflow:
/// 1. Initial render with v1.0.0 code
/// 2. User triggers "Check for Update"
/// 3. Simulated patch download and apply
/// 4. UI updates to v1.1.0 without app restart
class FluxOtaDemo extends StatefulWidget {
  const FluxOtaDemo({super.key});

  @override
  State<FluxOtaDemo> createState() => _FluxOtaDemoState();
}

class _FluxOtaDemoState extends State<FluxOtaDemo> {
  late FluxRuntime _runtime;
  String _currentVersion = '1.0.0';
  bool _isUpdating = false;
  String _statusMessage = 'Running v1.0.0';

  // Version 1.0.0 source
  static const _v1Source = '''
    widget OtaCounter {
      state count = 0;
      build {
        Column {
          Container(
            padding: 16,
            child: Column {
              Text("OTA Demo - v1.0.0")
              Text("Count: " + toString(count))
              Button("Increment +1", onPressed: fn() {
                count = count + 1;
              })
            }
          )
        }
      }
    }
  ''';

  // Version 1.1.0 source (updated)
  static const _v2Source = '''
    widget OtaCounter {
      state count = 0;
      build {
        Column {
          Container(
            padding: 16,
            color: "#E3F2FD",
            child: Column {
              Text("OTA Demo - v1.1.0 ✨")
              Text("Count: " + toString(count))
              Text("New: Double increment mode!")
              Button("Increment +2", onPressed: fn() {
                count = count + 2;
              })
            }
          )
        }
      }
    }
  ''';

  @override
  void initState() {
    super.initState();
    _runtime = FluxRuntime(_v1Source);
  }

  Future<void> _simulateOtaUpdate() async {
    try {
      setState(() {
        _isUpdating = true;
        _statusMessage = 'Checking for updates...';
      });

      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Update found! Downloading...';
      });

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;

      // Compile new version
      final newChunk = _compileSource(_v2Source);

      setState(() {
        _statusMessage = 'Applying update...';
      });

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      // Apply hot reload
      _runtime.hotReload(newChunk);

      if (!mounted) return;
      setState(() {
        _currentVersion = '1.1.0';
        _isUpdating = false;
        _statusMessage = 'Updated to v1.1.0! ✅';
      });
    } catch (e) {
      setState(() {
        _isUpdating = false;
        _statusMessage = 'Update failed: $e';
      });
    }
  }

  Future<void> _rollback() async {
    try {
      setState(() {
        _isUpdating = true;
        _statusMessage = 'Rolling back...';
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final oldChunk = _compileSource(_v1Source);
      _runtime.hotReload(oldChunk);

      if (!mounted) return;
      setState(() {
        _currentVersion = '1.0.0';
        _isUpdating = false;
        _statusMessage = 'Rolled back to v1.0.0';
      });
    } catch (e) {
      setState(() {
        _isUpdating = false;
        _statusMessage = 'Rollback failed: $e';
      });
    }
  }

  Chunk _compileSource(String source) {
    try {
      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final unit = parser.parse();
      if (parser.errors.isNotEmpty) {
        throw Exception("Parser errors: ${parser.errors.join(', ')}");
      }
      final compiler = Compiler(unit: unit);
      return compiler.endCompiler().chunk;
    } catch (e) {
      debugPrint('Compilation error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // OTA Status Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: _currentVersion == '1.1.0' ? Colors.green[100] : Colors.grey[200],
          child: Row(
            children: [
              Icon(
                _currentVersion == '1.1.0' ? Icons.check_circle : Icons.info,
                color: _currentVersion == '1.1.0' ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              if (_isUpdating)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),

        // Flux Widget
        Expanded(
          child: FluxWidget(
            runtime: _runtime,
            widgetName: 'OtaCounter',
          ),
        ),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUpdating || _currentVersion == '1.1.0'
                      ? null
                      : _simulateOtaUpdate,
                  icon: const Icon(Icons.system_update),
                  label: const Text('Check for Update'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isUpdating || _currentVersion == '1.0.0'
                      ? null
                      : _rollback,
                  icon: const Icon(Icons.undo),
                  label: const Text('Rollback'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
