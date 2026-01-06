import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;

const String DEFAULT_SCRIPT = r'''
widget HomeBanner {
  build {
    Container(
      padding: 20.0,
      color: "blue",
      child: Text(text: "Flux Demo", style: {"fontSize": 24.0, "color": "white"})
    )
  }
}
''';

enum LoadingMode { local, server }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flux 功能展示',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Use FluxRuntime instead of raw script string to allow interop
  FluxRuntime? _runtime; 
  String _status = 'Initializing...';
  bool _loading = false;
  int _reloadCount = 0;
  String? _resolvedPath;
  LoadingMode _mode = LoadingMode.local;
  final String _serverUrl = 'http://localhost:8081/home_banner.flux';
  
  @override
  void initState() {
    super.initState();
    _loadBannerScript();
  }
  
  Future<void> _loadBannerScript() async {
    setState(() {
      _loading = true;
      _status = '正在載入腳本...';
    });
    
    if (_mode == LoadingMode.server) {
      await _loadFromServer();
    } else {
      await _loadFromLocal();
    }
  }

  void _initRuntime(String script) {
    // 1. Create Runtime
    final runtime = FluxRuntime(script, moduleName: 'HomeBanner');
    
    // 2. Register Native Function (Language Interop)
    runtime.vm.registerModule(DialogInteropModule(context));

    // 3. Update State
    setState(() {
      _runtime = runtime;
      // _status updated by caller
      _loading = false;
      _reloadCount++;
    });
  }

  Future<void> _loadFromServer() async {
    try {
      final response = await http.get(Uri.parse(_serverUrl)).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        _resolvedPath = _serverUrl;
        _status = '✅ 已從伺服器載入\n🕐 ${DateTime.now().toString().substring(11, 19)}';
        _initRuntime(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _status = '❌ 伺服器載入錯誤: $e\n(請確認伺服器已啟動)';
        _loading = false;
      });
    }
  }

  Future<void> _loadFromLocal() async {
    File? scriptFile;
    
    // Try custom paths first (the ones user has open)
    final relativePaths = [
      'C:/Users/aa223/flux_demo/scripts/home_banner.flux',
      'D:/OtherProject/mine/flux/examples/hot_update_demo/scripts/home_banner.flux',
      '../scripts/home_banner.flux',
      'scripts/home_banner.flux',
    ];
    
    for (final path in relativePaths) {
      final f = File(path);
      if (await f.exists()) {
        scriptFile = f;
        break;
      }
    }
    
    if (scriptFile == null) {
      var current = Directory.current;
      for (int i = 0; i < 5; i++) {
        final testPath = p.join(current.path, 'scripts', 'home_banner.flux');
        final f = File(testPath);
        if (await f.exists()) {
          scriptFile = f;
          break;
        }
        current = current.parent;
        if (current.path == current.parent.path) break;
      }
    }
    
    if (scriptFile == null) {
      _resolvedPath = null;
      _status = '⚠️ 使用預設腳本 (找不到本地檔案)';
      _initRuntime(DEFAULT_SCRIPT);
      return;
    }
    
    try {
      final script = await scriptFile.readAsString();
      _resolvedPath = scriptFile.absolute.path;
      _status = '✅ 已從本地載入: ${p.basename(scriptFile.path)}\n🕐 ${DateTime.now().toString().substring(11, 19)}';
      _initRuntime(script);
    } catch (e) {
      setState(() {
        _status = '❌ 本地載入錯誤: $e';
        _loading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🔥'),
            SizedBox(width: 8),
            Text('Flux 動態 UI 展示'),
          ],
        ),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新載入腳本',
            onPressed: _loading ? null : _loadBannerScript,
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[100],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Mode Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('更新模式:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SegmentedButton<LoadingMode>(
                        segments: const [
                          ButtonSegment(value: LoadingMode.local, label: Text('本地檔案'), icon: Icon(Icons.description)),
                          ButtonSegment(value: LoadingMode.server, label: Text('遠端伺服器'), icon: Icon(Icons.cloud)),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (Set<LoadingMode> newSelection) {
                          setState(() {
                            _mode = newSelection.first;
                            _loadBannerScript();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Status Card
              Card(
                color: Colors.white,
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(_loading ? Icons.sync : Icons.check_circle, 
                               color: _loading ? Colors.orange : Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_status, style: const TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                      if (_resolvedPath != null) ...[
                        const Divider(),
                        Text('來源: $_resolvedPath', 
                             style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Flux Widget Area
              if (!_loading && _runtime != null)
                Card(
                  elevation: 4,
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 400),
                    child: FluxWidget(
                      key: ValueKey(_reloadCount),
                      widgetName: 'HomeBanner',
                      runtime: _runtime, // Using runtime with registered functions
                    ),
                  ),
                ),
              
              if (_loading) 
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
              
              const SizedBox(height: 24),
              
              // Instructions
              Card(
                color: Colors.amber[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tips_and_updates, color: Colors.amber[700]),
                          const SizedBox(width: 8),
                          Text('測試說明', 
                               style: TextStyle(fontWeight: FontWeight.bold, 
                                               color: Colors.amber[900], 
                                               fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_mode == LoadingMode.server) ...[
                        const Text('🌐 遠端伺服器模式：'),
                        const SizedBox(height: 4),
                        const Text('1️⃣ 確定伺服器已啟動並託管腳本'),
                        const SizedBox(height: 4),
                        const Text('2️⃣ 切換上方模式為「遠端伺服器」'),
                        const SizedBox(height: 4),
                        Text('3️⃣ 網址: $_serverUrl', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                      ] else ...[
                        const Text('📁 本地檔案模式：'),
                        const SizedBox(height: 4),
                        const Text('直接修改本地腳本檔案並儲存：'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Text(
                            _resolvedPath ?? '找不到檔案 (請確認 scripts/home_banner.flux 存在)',
                            style: const TextStyle(fontFamily: 'Consolas', fontSize: 11, color: Colors.black87),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text('👉 修改後儲存，點擊右上角 🔄 套用熱更新'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class DialogInteropModule extends FluxModule {
  final BuildContext context;
  DialogInteropModule(this.context) : super('NativeInterop') {
    register('showNativeDialog', NativeFunction('showNativeDialog', -1, (args) {
      final message = args.isNotEmpty ? args[0].toString() : "Hello from Native!";
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Native Interop 🔗'),
          content: Text('這是一個原生 Dart Dialog\n消息來自 Flux: "$message"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('關閉'),
            )
          ],
        ),
      );
      return null;
    }));
  }
}
