import 'package:flutter/material.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'code_preview.dart';

class OTAView extends StatelessWidget {
  const OTAView({super.key});

  @override
  Widget build(BuildContext context) {
    const fluxSource = '''
      widget OTADemo {
        state status = "Idle";
        state lastCheck = "Never";

        build {
          Center {
            Column {
               Padding(padding: {"all": 20.0}, child: 
                 Text("Over-The-Air Updates", style: {"fontSize": 24.0})
               );
               
               Text("Status: " + status, style: {"fontSize": 18.0, "color": "blue"});
               Text("Last Check: " + lastCheck);
               
               SizedBox(height: 30.0);
               
               Button("Check for Updates", onPressed: fn() {
                  status = "Checking...";
                  // In a real app, this would call flux_updater
                  // For demo, we simulate a delay
                  await Future.delayed(Duration(seconds: 2));
                  status = "Up to date";
                  lastCheck = DateTime.nowString();
               });
               
               SizedBox(height: 10.0);
               
               Button("Simulate New Version", onPressed: fn() {
                   status = "Downloading Patch (Simulated)...";
                   await Future.delayed(Duration(seconds: 2));
                   status = "Ready to Apply";
               });
               
                SizedBox(height: 10.0);
               
               Button("Apply Patch", onPressed: fn() {
                   if (status == "Ready to Apply") {
                      status = "Applying...";
                      await Future.delayed(Duration(seconds: 1));
                      status = "Restarting...";
                      // flux.reload(); // hypothetical hot reload
                   } else {
                      status = "Nothing to apply";
                   }
               });
            }
          }
        }
      }
    ''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTA Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CodePreviewScreen(
                    title: 'OTA',
                    source: fluxSource,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: FluxWidget(
        source: fluxSource,
        widgetName: 'OTADemo',
      ),
    );
  }
}
