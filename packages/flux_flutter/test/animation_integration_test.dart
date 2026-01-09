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
  testWidgets('Flux Animation Curves Test', (WidgetTester tester) async {
    const source = '''
      widget CurvedDemo {
        state controller = Animation.createController(1000);
        state curved = Animation.curved(controller, "bounceOut");
        state anim = Animation.tween(0.0, 100.0).animate(curved);
        
        build {
          Column {
            Button("Start", onPressed: fn() { 
              controller.forward(); 
            });
            Container(width: anim, height: 50, color: "red");
          }
        }
      }
    ''';

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FluxWidget(
          source: source,
          widgetName: 'CurvedDemo',
        ),
      ),
    ));

    await tester.pumpAndSettle();

    // Click Start
    await tester.tap(find.text('Start'));
    await tester.pump();

    // Advance 500ms (Halfway)
    await tester.pump(const Duration(milliseconds: 500));

    final containerFinder = find.byType(Container);
    Container container = tester.widget<Container>(containerFinder);

    // With bounceOut, it might be > 50 at halfway or specific value.
    // Normalized bounceOut at t=0.5 is > 0.5?
    // Let's just check it is NOT linear 50.0 (it should be different)
    // Actually bounceOut at 0.5 is approx 0.76 (depending on implementation), definitely > 60
    final width = container.constraints!.maxWidth;
    if (width == 0.0 || width == 50.0) {
      fail(
          'Animation value $width suggests curve not applied (Linear would be 50.0)');
    }
  });
  testWidgets('Flux Implicit Animation Test', (WidgetTester tester) async {
    const source = '''
      widget ImplicitDemo {
        state toggled = false;
        
        build {
          Column {
            Button("Toggle", onPressed: fn() { 
              toggled = !toggled; 
            });
            
            var w = 50.0;
            var c = "blue";
            if (toggled) {
              w = 100.0;
              c = "red";
            }
            
            AnimatedContainer(
              key: "ac",
              duration: 500,
              curve: "easeIn",
              width: w,
              height: 50.0,
              color: c
            );
          }
        }
      }
    ''';

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FluxWidget(
          source: source,
          widgetName: 'ImplicitDemo',
        ),
      ),
    ));

    await tester.pump();

    final acFinder = find.byKey(const ValueKey<dynamic>("ac"));
    expect(acFinder, findsOneWidget);

    // Initial State: Width 50, Color Blue
    // Use getSize to check rendered size
    expect(tester.getSize(acFinder).width, 50.0);

    // Click Toggle
    await tester.tap(find.text('Toggle'));
    await tester.pump(); // Start animation (Frame 0)

    // Frame 0: Size should be 50 (start)
    expect(tester.getSize(acFinder).width, 50.0);

    // Halfway (250ms of 500ms)
    await tester.pump(const Duration(milliseconds: 250));

    final midWidth = tester.getSize(acFinder).width;
    // Should be > 50 and < 100.
    // easeIn at 0.5 is approx 0.25 * 50 = 12.5 + 50 = 62.5
    if (midWidth <= 50.0 || midWidth >= 100.0) {
      fail("AnimatedContainer did not animate, width is $midWidth");
    }

    // Finish
    await tester.pumpAndSettle();
    expect(tester.getSize(acFinder).width, 100.0);
  });
}
