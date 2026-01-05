import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_flutter/flux_flutter.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flux OTA Demo',
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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flux Flutter Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          FluxOtaDemo(),
          FluxCounter(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.system_update),
            label: 'OTA Demo',
          ),
          NavigationDestination(
            icon: Icon(Icons.storage),
            label: 'Storage Demo',
          ),
        ],
      ),
    );
  }
}

class FluxCounter extends StatelessWidget {
  const FluxCounter({super.key});

  @override
  Widget build(BuildContext context) {
    const fluxSource = '''
      widget Counter {
        state sharedVal = "";
        state hiveVal = "";
        state secureVal = "";
        
        build {
          Column {
            Text("Storage Demo");
            Row {
              Text("Shared Prefs: ");
              Text(sharedVal);
            }
            Button("Save SP", onPressed: fn() {
                 await storage.set("demo_key", "SP Saved!");
                 sharedVal = await storage.get("demo_key");
            })
            
            Row {
              Text("Hive: ");
              Text(hiveVal);
            }
            Button("Save Hive", onPressed: fn() {
                 await hive.openBox("demo_box");
                 await hive.put("demo_box", "demo_hive", "Hive Saved!");
                 await hive.closeBox("demo_box");
                 
                 // Re-open to verify
                 await hive.openBox("demo_box");
                 hiveVal = await hive.get("demo_box", "demo_hive");
            })
            
            Row {
              Text("Secure: ");
              Text(secureVal);
            }
            Button("Save Secure", onPressed: fn() {
                 await secure.set("demo_secure", "Secure Saved!");
                 secureVal = await secure.get("demo_secure");
            })
          }
        }
      }
    ''';

    return FluxWidget(
      source: fluxSource,
      widgetName: 'Counter',
    );
  }
}
