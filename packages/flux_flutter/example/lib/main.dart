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
      home: Scaffold(
        appBar: AppBar(title: const Text('Flux Flutter Example')),
        body: const FluxCounter(),
      ),
    );
  }
}

class FluxCounter extends StatelessWidget {
  const FluxCounter({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo for State Persistence Features (v3.0)
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
