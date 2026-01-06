import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/flux_flutter.dart';

void main() {
  testWidgets('Flux Animation System Test', (WidgetTester tester) async {
    const source = '''
      widget AnimDemo {
        state controller = Animation.createController(500);
        state anim = Animation.tween(0.0, 100.0).animate(controller);
        
        build {
          Column {
            Button("Start", onPressed: fn() { 
              controller.forward(); 
            });
            Container(width: anim, height: 50, color: "blue");
          }
        }
      }
    ''';

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FluxWidget(
          source: source, 
          widgetName: 'AnimDemo',
        ),
      ),
    ));

    // Wait for initial render
    await tester.pump(const Duration(milliseconds: 100));

    // Initially width should be 0.0 (resolved from anim which is 0.0)
    // Find ColoredBox inside Container because Container with color uses it
    final containerFinder = find.byType(Container);
    expect(containerFinder, findsOneWidget);
    
    Container container = tester.widget<Container>(containerFinder);
    expect(container.constraints?.maxWidth, 0.0);

    // Click Start
    await tester.tap(find.text('Start'));
    await tester.pump(); // Trigger build and animation start

    // Advance 250ms (Halfway)
    await tester.pump(const Duration(milliseconds: 250));
    
    container = tester.widget<Container>(containerFinder);
    // Value should be around 50.0
    expect(container.constraints?.maxWidth, closeTo(50.0, 1.0));

    // Advance to end (remaining 250ms)
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(); // Final tick
    
    container = tester.widget<Container>(containerFinder);
    expect(container.constraints?.maxWidth, 100.0);
  });
}
