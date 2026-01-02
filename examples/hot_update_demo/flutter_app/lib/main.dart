import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'package:path/path.dart' as p;

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
  State<HomePage> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePage> {
  String _script = DEFAULT_SCRIPT;
  String _status = 'Initializing...';
  bool _loading = false;
  int _reloadCount = 0;
  String? _resolvedPath;
  
  @override
  void initState() {
    super.initState();
    _loadBannerScript();
  }
  
  Future<void> _loadBannerScript() async {
    setState(() {
      _loading = true;
      _status = 'Loading script...';
    });
    
    File? scriptFile;
    
    // 1. Try common relative paths
    final relativePaths = [
      '../scripts/home_banner.flux',
      'scripts/home_banner.flux',
      './scripts/home_banner.flux',
      '../../scripts/home_banner.flux',
    ];
    
    for (final path in relativePaths) {
      final f = File(path);
      if (await f.exists()) {
        scriptFile = f;
        break;
      }
    }
    
    // 2. Try to find by walking up from current directory (robust for compiled apps)
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
      setState(() {
        _script = DEFAULT_SCRIPT;
        _status = '⚠️ 使用預設腳本 (找不到 scripts/home_banner.flux)';
        _loading = false;
        _reloadCount++;
        _resolvedPath = null;
      });
      return;
    }
    
    try {
      final script = await scriptFile.readAsString();
      setState(() {
        _script = script;
        _resolvedPath = scriptFile!.absolute.path;
        _status = '✅ 已載入: ${p.basename(scriptFile!.path)}\n🕐 ${DateTime.now().toString().substring(11, 19)}';
        _loading = false;
        _reloadCount++;
      });
    } catch (e) {
      setState(() {
        _status = '❌ 讀取錯誤: $e';
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
                        Text('路徑: \$_resolvedPath', 
                             style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Flux Widget Area
              if (!_loading)
                Card(
                  elevation: 4,
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 400),
                    child: FluxWidget(
                      key: ValueKey(_reloadCount),
                      widgetName: 'HomeBanner',
                      source: _script,
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
                          Text('如何測試熱更新', 
                               style: TextStyle(fontWeight: FontWeight.bold, 
                                               color: Colors.amber[900], 
                                               fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('1️⃣ 開啟 scripts/home_banner.flux'),
                      const SizedBox(height: 4),
                      const Text('2️⃣ 修改顏色、文字、功能或狀態初值'),
                      const SizedBox(height: 4),
                      const Text('3️⃣ 儲存檔案'),
                      const SizedBox(height: 4),
                      const Text('4️⃣ 點擊右上角 🔄 即時套用更新'),
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
