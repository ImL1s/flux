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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FluxDemoPage(),
    );
  }
}

class FluxDemoPage extends StatelessWidget {
  const FluxDemoPage({super.key});

  // Flux source code defining a counter widget
  static const fluxSource = '''
widget MyCounter {
  state count = 0
  
  build {
    Column {
      Text("Count: " + count)
      Text("Hello from Flux!")
    }
  }
}
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flux Language Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Widget rendered from Flux code:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FluxWidget(
                source: fluxSource,
                widgetName: 'MyCounter',
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Flux Source Code:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                fluxSource,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
