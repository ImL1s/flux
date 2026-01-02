import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flux_flutter/flux_flutter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flux 熱更新 Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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
  String? _bannerScript;
  String _status = '載入中...';
  
  @override
  void initState() {
    super.initState();
    _loadBannerScript();
  }
  
  /// 從「後端」載入腳本 (這裡用本地文件模擬)
  Future<void> _loadBannerScript() async {
    setState(() => _status = '正在讀取腳本...');
    
    // 嘗試多個可能的路徑 (因為不同的 IDE/終端 運行目錄可能不同)
    final possiblePaths = [
      '../scripts/home_banner.flux',           // 標準結構
      'scripts/home_banner.flux',              // 如果在 root 運行
      '../../scripts/home_banner.flux',        // 如果在 bin 運行
      'examples/hot_update_demo/scripts/home_banner.flux' // 如果在 workspace root 運行
    ];
    
    File? scriptFile;
    String? loadedPath;
    
    // 1. 尋找正確的文件路徑
    for (final path in possiblePaths) {
      final file = File(path);
      if (await file.exists()) {
        scriptFile = file;
        loadedPath = file.absolute.path;
        break;
      }
    }
    
    if (scriptFile == null) {
      setState(() {
        _status = '❌ 找不到腳本文件！\n'
                  '請確保運行在 Desktop (Windows/Mac) 且路徑正確。\n'
                  '當前目錄: ${Directory.current.path}';
        _bannerScript = null; // 清空，不使用 Demo Mode 欺騙
      });
      return;
    }
    
    // 2. 讀取內容
    try {
      final script = await scriptFile.readAsString();
      setState(() {
        _bannerScript = script;
        _status = '✅ 已載入: .../${loadedPath!.split(Platform.pathSeparator).last}\n'
                  '更新時間: ${DateTime.now().toString().substring(11, 19)}';
      });
    } catch (e) {
      setState(() => _status = '❌ 讀取錯誤: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 Flux 熱更新 Demo'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // 手動觸發「熱更新」
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBannerScript,
            tooltip: '從後端重新載入腳本',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // === 狀態指示器 ===
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey[200],
              child: Text(_status, textAlign: TextAlign.center),
            ),
            
            // === 這個 Banner 是 Flux 動態渲染的 ===
            if (_bannerScript != null)
              FluxWidget(
                widgetName: 'HomeBanner',
                source: _bannerScript!,
              )
            else
              const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              ),
              
            const SizedBox(height: 24),
            
            // === 操作說明 ===
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📖 如何測試熱更新',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      const Text('1️⃣ 打開 scripts/home_banner.flux'),
                      const SizedBox(height: 4),
                      const Text('2️⃣ 把 state theme = "spring" 改成 "mother" 或 "dragon"'),
                      const SizedBox(height: 4),
                      const Text('3️⃣ 保存文件'),
                      const SizedBox(height: 4),
                      const Text('4️⃣ 點擊右上角的刷新按鈕 🔄'),
                      const SizedBox(height: 4),
                      const Text('5️⃣ 觀察 Banner 立刻變成新主題！'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '💡 這就是熱更新的威力：\n'
                          '您只需要修改服務器上的腳本，'
                          'App 無需重新發布就能顯示新內容！',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
