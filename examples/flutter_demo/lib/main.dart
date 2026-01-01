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
    Column {
      Text("Counter Value: " + count)
      Row {
        Button("-") { count = count - 1 }
        SizedBox(width: 16)
        Button("+") { count = count + 1 }
      }
    }
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
  state data = "Loading..."
  state loading = true
  
  fn fetchData() {
    loading = true
    try {
      // Simulate fetch since we can't make real calls in this restricted demo env easily
      // In real app: var res = await http.get("...")
      await timer.delay(1000)
      data = "Fetched content from API"
    } catch (e) {
      data = "Error: " + e
    }
    loading = false
  }

  build {
    Column {
      Button("Fetch Data") { fetchData() }
      
      if (loading) {
        Text("Please wait...")
      } else {
        Text("Result: " + data)
      }
    }
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
  state storedValue = "None"
  
  fn load() {
    var val = storage.get("demo_key")
    if (val == nil) {
      storedValue = "No value found"
    } else {
      storedValue = val
    }
  }
  
  fn save() {
    storage.set("demo_key", "Saved at " + DateTime.now())
    load()
  }
  
  build {
    Column {
      Text("Stored Value: " + storedValue)
      Row {
        Button("Load") { load() }
        SizedBox(width: 8)
        Button("Save New Timestamp") { save() }
      }
    }
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
          FutureBuilder(
            future: FluxDeviceModule.getDeviceInfo(), 
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                 final info = snapshot.data as Map;
                 return Text('Running on: \${info['os']} \${info['version']}');
              }
              return const SizedBox.shrink();
            } 
          ),
        ],
      ),
    );
  }
}
