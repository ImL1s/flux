import 'package:flutter/material.dart';
import 'package:flux_flutter/flux_flutter.dart';

class StorageView extends StatelessWidget {
  const StorageView({super.key});

  @override
  Widget build(BuildContext context) {
    const fluxSource = '''
      widget StorageDemo {
        state sharedVal = "";
        state hiveVal = "";
        state secureVal = "";
        
        build {
          Column {
             Padding(padding: {"all": 10.0}, child: 
               Text("Persistent Storage", style: {"fontSize": 24.0})
            );

            // Shared Preferences
            Container(
              margin: {"all": 10.0},
              padding: {"all": 10.0},
              decoration: {border: {"all": {"color": "grey"}}},
              child: Column {
                Text("Shared Preferences", style: {"fontWeight": "bold"});
                Row {
                  Text("Value: ");
                  Text(sharedVal);
                }
                Button("Save 'FluxSP'", onPressed: fn() {
                     await storage.set("demo_key", "FluxSP");
                     sharedVal = await storage.get("demo_key");
                })
                 Button("Clear", onPressed: fn() {
                     await storage.remove("demo_key");
                     sharedVal = await storage.get("demo_key");
                })
              }
            );
            
            // Hive
             Container(
              margin: {"all": 10.0},
               padding: {"all": 10.0},
              decoration: {border: {"all": {"color": "grey"}}},
              child: Column {
                Text("Hive (Box storage)", style: {"fontWeight": "bold"});
                Row {
                  Text("Value: ");
                  Text(hiveVal);
                }
                Button("Save 'FluxHive'", onPressed: fn() {
                     await hive.openBox("demo_box");
                     await hive.put("demo_box", "demo_hive", "FluxHive");
                     hiveVal = await hive.get("demo_box", "demo_hive");
                })
              }
            );
            
            // Secure Storage
             Container(
              margin: {"all": 10.0},
               padding: {"all": 10.0},
              decoration: {border: {"all": {"color": "grey"}}},
              child: Column {
                Text("Secure Storage", style: {"fontWeight": "bold"});
                Row {
                  Text("Value: ");
                  Text(secureVal);
                }
                Button("Save 'Secret123'", onPressed: fn() {
                     await secure.set("demo_secure", "Secret123");
                     secureVal = await secure.get("demo_secure");
                })
              }
            );
          }
        }
      }
    ''';

    return Scaffold(
      appBar: AppBar(title: const Text('Storage Demo')),
      body: SingleChildScrollView(
        child: FluxWidget(
          source: fluxSource,
          widgetName: 'StorageDemo',
        ),
      ),
    );
  }
}
