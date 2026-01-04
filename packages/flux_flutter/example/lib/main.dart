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
    // A simple Flux script that defines a widget with state
    const fluxSource = '''
      widget Counter {
        state count = 0;
        
        build {
          Column {
            Text("Count: \${count}");
            
            Button("Increment") {
               onPressed: fn() {
                 count = count + 1;
               }
            }
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
