import 'dart:async';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

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

class FluxDebuggerScreen extends StatefulWidget {
  const FluxDebuggerScreen({super.key});

  @override
  State<FluxDebuggerScreen> createState() => _FluxDebuggerScreenState();
}

class _FluxDebuggerScreenState extends State<FluxDebuggerScreen> {
  String _status = 'Ready to Connect';
  List<Map<String, dynamic>> _scripts = [];
  Map<String, dynamic>? _selectedScript;
  
  bool _isPaused = false;
  String? _pausedScript;
  int? _pausedLine;
  
  // Map of "scriptName:line" -> breakpointId
  final Map<String, int> _breakpointIds = {};
  
  StreamSubscription? _eventSub;

  @override
  void initState() {
    super.initState();
    _connect();
    
    // Listen for debug events
    _eventSub = serviceManager.service?.onExtensionEvent.listen((event) {
      if (event.extensionKind == 'Flux.Debug') {
        _handleDebugEvent(event.extensionData?.data ?? {});
      }
    });
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }

  void _handleDebugEvent(Map<String, dynamic> data) {
    setState(() {
      _isPaused = data['event'] == 'breakpoint';
      _pausedScript = data['script'];
      _pausedLine = data['line'];
    });
    
    if (_isPaused && _pausedScript != null) {
      final script = _scripts.firstWhere((s) => s['name'] == _pausedScript, orElse: () => {});
      if (script.isNotEmpty) {
        setState(() => _selectedScript = script);
      }
    }
  }

  Future<void> _connect() async {
    setState(() => _status = 'Connecting...');
    try {
      final vResponse = await serviceManager.callServiceExtensionOnMainIsolate('ext.flux.getVersion');
      final vJson = vResponse.json ?? {};
      
      final sResponse = await serviceManager.callServiceExtensionOnMainIsolate('ext.flux.getScripts');
      final sJson = sResponse.json ?? {};
      
      final statusResponse = await serviceManager.callServiceExtensionOnMainIsolate('ext.flux.getStatus');
      final statusJson = statusResponse.json ?? {};

      setState(() {
        _status = 'Connected: v${vJson['version']}';
        _scripts = List<Map<String, dynamic>>.from(sJson['scripts'] ?? []);
        if (_scripts.isNotEmpty && _selectedScript == null) {
           _selectedScript = _scripts.first;
        }
        _isPaused = statusJson['isPaused'] ?? false;
        _pausedScript = statusJson['pausedScript'];
        _pausedLine = statusJson['pausedLine'];
      });
    } catch (e) {
      setState(() {
        _status = 'Disconnected';
        _scripts = [];
      });
    }
  }

  Future<void> _resume() async => await serviceManager.callServiceExtensionOnMainIsolate('ext.flux.resume');
  Future<void> _pause() async => await serviceManager.callServiceExtensionOnMainIsolate('ext.flux.pause');
  Future<void> _step(String mode) async => await serviceManager.callServiceExtensionOnMainIsolate('ext.flux.step', args: {'mode': mode});

  Future<void> _toggleBreakpoint(String script, int line) async {
    final key = '$script:$line';
    if (_breakpointIds.containsKey(key)) {
      final id = _breakpointIds[key];
      await serviceManager.callServiceExtensionOnMainIsolate('ext.flux.removeBreakpoint', args: {
        'id': '$id',
      });
      _breakpointIds.remove(key);
    } else {
      final response = await serviceManager.callServiceExtensionOnMainIsolate('ext.flux.addBreakpoint', args: {
        'script': script,
        'line': '$line',
      });
      final id = (response.json ?? {})['id'];
      if (id != null) {
        _breakpointIds[key] = id;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flux Debugger'),
        actions: [
          // Control Buttons
          IconButton(
            icon: const Icon(Icons.play_arrow), 
            onPressed: _isPaused ? _resume : null,
            tooltip: 'Resume',
            color: Colors.green,
          ),
          IconButton(
            icon: const Icon(Icons.pause), 
            onPressed: !_isPaused ? _pause : null,
            tooltip: 'Pause',
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_forward), 
            onPressed: _isPaused ? () => _step('into') : null,
            tooltip: 'Step Into',
          ),
          IconButton(
            icon: const Icon(Icons.login), 
            onPressed: _isPaused ? () => _step('over') : null,
            tooltip: 'Step Over',
          ),
          IconButton(
            icon: const Icon(Icons.logout), 
            onPressed: _isPaused ? () => _step('out') : null,
            tooltip: 'Step Out',
          ),
          const VerticalDivider(),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Center(child: Text(_status))),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _connect),
        ],
      ),
      body: _scripts.isEmpty 
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Scripts List
                SizedBox(
                  width: 200,
                  child: ListView.builder(
                    itemCount: _scripts.length,
                    itemBuilder: (context, index) {
                      final s = _scripts[index];
                      return ListTile(
                        title: Text(s['name'] ?? ''),
                        selected: _selectedScript == s,
                        onTap: () => setState(() => _selectedScript = s),
                      );
                    },
                  ),
                ),
                const VerticalDivider(width: 1),
                // Source View
                Expanded(
                  child: _selectedScript == null
                      ? const Center(child: Text('Select a script'))
                      : _CodeViewer(
                          scriptName: _selectedScript!['name'],
                          source: _selectedScript!['source'],
                          breakpointLines: _breakpointIds.keys.map((k) => k.split(':')).where((parts) => parts[0] == _selectedScript!['name']).map((parts) => int.parse(parts[1])).toSet(),
                          pausedLine: _isPaused && _pausedScript == _selectedScript!['name'] ? _pausedLine : null,
                          onToggleBreakpoint: (line) => _toggleBreakpoint(_selectedScript!['name'], line),
                        ),
                ),
              ],
            ),
    );
  }
}

class _CodeViewer extends StatelessWidget {
  final String scriptName;
  final String source;
  final Set<int> breakpointLines;
  final int? pausedLine;
  final Function(int) onToggleBreakpoint;

  const _CodeViewer({
    required this.scriptName,
    required this.source,
    required this.breakpointLines,
    required this.pausedLine,
    required this.onToggleBreakpoint,
  });

  @override
  Widget build(BuildContext context) {
    final lines = source.split('\n');
    return ListView.builder(
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final lineNum = index + 1;
        final hasBp = breakpointLines.contains(lineNum);
        final isPaused = pausedLine == lineNum;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gutter
            GestureDetector(
              onTap: () => onToggleBreakpoint(lineNum),
              child: Container(
                width: 40,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                color: isPaused ? Colors.blue.withValues(alpha: 0.3) : Colors.transparent,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (hasBp) 
                      const Icon(Icons.circle, size: 12, color: Colors.red),
                    Text('$lineNum', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
            // Code
            Expanded(
              child: Container(
                color: isPaused ? Colors.blue.withValues(alpha: 0.1) : Colors.transparent,
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  lines[index],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
