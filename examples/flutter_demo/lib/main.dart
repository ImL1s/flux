import 'package:flutter/material.dart';
import 'package:flux_flutter/flux_flutter.dart';

void main() {
  runApp(const FluxDemoApp());
}

class FluxDemoApp extends StatelessWidget {
  const FluxDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flux Language Demo',
      navigatorKey: fluxNavigatorKey, // Important for Dialog Module
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    FluxWidgetGallery(),
    FluxHttpDemo(),
    FluxStorageDemo(),
    FluxAboutPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flux Language Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.widgets),
            label: 'Widgets',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud),
            label: 'HTTP',
          ),
          NavigationDestination(
            icon: Icon(Icons.storage),
            label: 'Storage',
          ),
          NavigationDestination(
            icon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}

// --- Page 1: Widget Gallery ---

class FluxWidgetGallery extends StatelessWidget {
  const FluxWidgetGallery({super.key});

  static const counterSource = '''
widget Counter {
  state count = 0
  
  build {
    Column(
      children: [
        Text(text: "計數器: " + count, style: {"fontSize": 24.0, "fontWeight": "bold"}),
        SizedBox(height: 16.0),
        Row(
          mainAxisAlignment: "center",
          children: [
            Button(text: "➖", onPressed: fn() { count = count - 1; }),
            SizedBox(width: 20.0),
            Text(text: count, style: {"fontSize": 32.0, "fontWeight": "bold"}),
            SizedBox(width: 20.0),
            Button(text: "➕", onPressed: fn() { count = count + 1; })
          ]
        )
      ]
    )
  }
}
''';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Interactive Flux Widgets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: FluxWidget(
                source: counterSource,
                widgetName: 'Counter',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Source Code:', style: TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: const Text(counterSource, style: TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}

// --- Page 2: HTTP Demo ---

class FluxHttpDemo extends StatelessWidget {
  const FluxHttpDemo({super.key});

  static const httpSource = '''
widget HttpFetcher {
  state data = "點擊按鈕取得資料"
  state loading = false
  
  async fn fetchData() {
    loading = true;
    await delay(1000);
    data = "✅ 成功取得 API 資料！";
    loading = false;
  }

  build {
    Container(
      padding: 20.0,
      color: "indigo",
      child: Column(
        children: [
          Text(text: "🌐 HTTP 模擬展示", style: {"fontSize": 20.0, "color": "white", "fontWeight": "bold"}),
          SizedBox(height: 16.0),
          Button(text: "取得資料", onPressed: fn() { fetchData(); }),
          SizedBox(height: 16.0),
          Container(
            padding: 12.0,
            color: "white",
            child: Text(text: data, style: {"fontSize": 16.0})
          )
        ]
      )
    )
  }
}
''';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
           const Text('HTTP Module Demo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
           const SizedBox(height: 20),
           const Expanded(
             child: FluxWidget(source: httpSource, widgetName: 'HttpFetcher'),
           ),
        ],
      ),
    );
  }
}

// --- Page 3: Storage Demo ---

class FluxStorageDemo extends StatelessWidget {
  const FluxStorageDemo({super.key});
  
  static const storageSource = '''
widget StorageEditor {
  state storedValue = "點擊儲存來建立資料"
  state saveCount = 0
  
  fn load() {
    if (saveCount == 0) {
      storedValue = "尚未儲存任何資料";
    } else {
      storedValue = "已儲存 " + saveCount + " 次";
    }
  }
  
  fn save() {
    saveCount = saveCount + 1;
    storedValue = "✅ 第 " + saveCount + " 次儲存成功！";
  }
  
  build {
    Container(
      padding: 20.0,
      color: "teal",
      child: Column(
        children: [
          Text(text: "💾 儲存模擬展示", style: {"fontSize": 20.0, "color": "white", "fontWeight": "bold"}),
          SizedBox(height: 16.0),
          Container(
            padding: 12.0,
            color: "white",
            child: Text(text: storedValue, style: {"fontSize": 16.0})
          ),
          SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: "center",
            children: [
              Button(text: "讀取", onPressed: fn() { load(); }),
              SizedBox(width: 12.0),
              Button(text: "儲存", onPressed: fn() { save(); })
            ]
          )
        ]
      )
    )
  }
}
''';

  @override
  Widget build(BuildContext context) {
     return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
           const Text('Storage Module Demo', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
           const SizedBox(height: 20),
           const Expanded(
             child: FluxWidget(source: storageSource, widgetName: 'StorageEditor'),
           ),
        ],
      ),
    );
  }
}

// --- Page 4: About ---

class FluxAboutPage extends StatelessWidget {
  const FluxAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt, size: 80, color: Colors.amber),
          const SizedBox(height: 16),
          const Text('Flux Language v0.1', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          const Text('Flutter 動態腳本引擎', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('✨ 功能特點', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('🎨 動態 UI 更新'),
                  Text('💼 業務邏輯執行'),
                  Text('🌐 HTTP 網路請求'),
                  Text('📊 響應式狀態管理'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
