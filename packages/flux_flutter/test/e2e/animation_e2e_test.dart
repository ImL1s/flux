import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/flux_flutter.dart';

/// End-to-End Animation Tests
/// These tests simulate real user scenarios with complex interactions
void main() {
  group('E2E: Interactive Dashboard Animation', () {
    testWidgets('sidebar expand/collapse animation', (tester) async {
      const source = '''
        widget Dashboard {
          state sidebarOpen = false;
          
          build {
            Row {
              var sidebarWidth = 60.0;
              if (sidebarOpen) {
                sidebarWidth = 200.0;
              }
              
              AnimatedContainer(
                key: "sidebar",
                duration: 300,
                curve: "easeInOut",
                width: sidebarWidth,
                height: 400.0,
                color: "gray"
              ) {
                Column {
                  Button("☰", onPressed: fn() { sidebarOpen = !sidebarOpen; });
                }
              }
              
              Container(width: 300.0, height: 400.0, color: "white");
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home:
            Scaffold(body: FluxWidget(source: source, widgetName: 'Dashboard')),
      ));
      await tester.pump();

      final sidebar = find.byKey(const ValueKey<dynamic>("sidebar"));

      // Initially collapsed
      expect(tester.getSize(sidebar).width, 60.0);

      // Open sidebar
      await tester.tap(find.text('☰'));
      await tester.pump();

      // Mid-animation check
      await tester.pump(const Duration(milliseconds: 150));
      var midWidth = tester.getSize(sidebar).width;
      expect(midWidth, greaterThan(60.0));
      expect(midWidth, lessThan(200.0));

      // Complete open
      await tester.pumpAndSettle();
      expect(tester.getSize(sidebar).width, 200.0);

      // Close sidebar
      await tester.tap(find.text('☰'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      midWidth = tester.getSize(sidebar).width;
      expect(midWidth, greaterThan(60.0));
      expect(midWidth, lessThan(200.0));

      await tester.pumpAndSettle();
      expect(tester.getSize(sidebar).width, 60.0);
    });
  });

  group('E2E: Card Reveal Animation', () {
    testWidgets('fades in and expands on tap', (tester) async {
      const source = '''
        widget CardReveal {
          state revealed = false;
          
          build {
            Column {
              Button("Reveal", onPressed: fn() { revealed = true; });
              
              var op = 0.0;
              var h = 0.0;
              if (revealed) {
                op = 1.0;
                h = 200.0;
              }
              
              AnimatedOpacity(
                key: "cardOpacity",
                duration: 400,
                curve: "easeOut",
                opacity: op
              ) {
                AnimatedContainer(
                  key: "cardSize",
                  duration: 400,
                  curve: "easeOut",
                  width: 300.0,
                  height: h,
                  color: "blue"
                );
              }
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FluxWidget(source: source, widgetName: 'CardReveal')),
      ));
      await tester.pump();

      final opacityFinder = find.byKey(const ValueKey<dynamic>("cardOpacity"));
      final sizeFinder = find.byKey(const ValueKey<dynamic>("cardSize"));

      // Initially hidden
      var ao = tester.widget<AnimatedOpacity>(opacityFinder);
      expect(ao.opacity, 0.0);
      expect(tester.getSize(sizeFinder).height, 0.0);

      // Reveal
      await tester.tap(find.text('Reveal'));
      await tester.pump();

      // Mid-reveal (200ms of 400ms)
      await tester.pump(const Duration(milliseconds: 200));
      final midHeight = tester.getSize(sizeFinder).height;
      expect(midHeight, greaterThan(0.0));
      expect(midHeight, lessThan(200.0));

      // Complete
      await tester.pumpAndSettle();
      ao = tester.widget<AnimatedOpacity>(opacityFinder);
      expect(ao.opacity, 1.0);
      expect(tester.getSize(sizeFinder).height, 200.0);
    });
  });

  group('E2E: Loading State Transition', () {
    testWidgets('spinner to content crossfade', (tester) async {
      const source = '''
        widget LoadingState {
          state isLoading = true;
          
          build {
            Column {
              Button("Load", onPressed: fn() { isLoading = false; });
              
              var spinnerOp = 1.0;
              var contentOp = 0.0;
              if (!isLoading) {
                spinnerOp = 0.0;
                contentOp = 1.0;
              }
              
              AnimatedOpacity(
                key: "spinner",
                duration: 300,
                opacity: spinnerOp
              ) {
                Text("⏳ Loading...");
              }
              
              AnimatedOpacity(
                key: "content",
                duration: 300,
                opacity: contentOp
              ) {
                Text("✅ Loaded!");
              }
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FluxWidget(source: source, widgetName: 'LoadingState')),
      ));
      await tester.pump();

      final spinner = find.byKey(const ValueKey<dynamic>("spinner"));
      final content = find.byKey(const ValueKey<dynamic>("content"));

      // Initially: spinner visible, content hidden
      var spinnerWidget = tester.widget<AnimatedOpacity>(spinner);
      var contentWidget = tester.widget<AnimatedOpacity>(content);
      expect(spinnerWidget.opacity, 1.0);
      expect(contentWidget.opacity, 0.0);

      // Trigger load complete
      await tester.tap(find.text('Load'));
      await tester.pump();

      // Mid-transition
      await tester.pump(const Duration(milliseconds: 150));
      // Both should be partially visible during crossfade

      // Complete
      await tester.pumpAndSettle();
      spinnerWidget = tester.widget<AnimatedOpacity>(spinner);
      contentWidget = tester.widget<AnimatedOpacity>(content);
      expect(spinnerWidget.opacity, 0.0);
      expect(contentWidget.opacity, 1.0);
    });
  });

  group('E2E: Multi-Step Form Wizard', () {
    testWidgets('step indicator slides between steps', (tester) async {
      const source = '''
        widget FormWizard {
          state step = 0;
          
          build {
            Column {
              Row {
                Button("Prev", onPressed: fn() { 
                  if (step > 0) { step = step - 1; }
                });
                Button("Next", onPressed: fn() { 
                  if (step < 2) { step = step + 1; }
                });
              }
              
              var indicatorX = 0.0;
              if (step == 1) { indicatorX = 100.0; }
              if (step == 2) { indicatorX = 200.0; }
              
              Row {
                AnimatedContainer(
                  key: "indicator",
                  duration: 250,
                  curve: "fastOutSlowIn",
                  margin: [0, indicatorX, 0, 0],
                  width: 80.0,
                  height: 4.0,
                  color: "blue"
                );
              }
              
              var stepText = "Step 1";
              if (step == 1) { stepText = "Step 2"; }
              if (step == 2) { stepText = "Step 3"; }
              
              Text(stepText);
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FluxWidget(source: source, widgetName: 'FormWizard')),
      ));
      await tester.pump();

      // Verify initial step
      expect(find.text('Step 1'), findsOneWidget);

      // Move to step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2'), findsOneWidget);

      // Move to step 3
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3'), findsOneWidget);

      // Go back to step 2
      await tester.tap(find.text('Prev'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2'), findsOneWidget);

      // Go back to step 1
      await tester.tap(find.text('Prev'));
      await tester.pumpAndSettle();
      expect(find.text('Step 1'), findsOneWidget);
    });
  });

  group('E2E: Stress Tests', () {
    testWidgets('rapid toggle does not break animation state', (tester) async {
      const source = '''
        widget RapidToggle {
          state on = false;
          
          build {
            Column {
              Button("Toggle", onPressed: fn() { on = !on; });
              
              var w = 50.0;
              var c = "red";
              if (on) { 
                w = 150.0; 
                c = "green";
              }
              
              AnimatedContainer(
                key: "box",
                duration: 500,
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
            body: FluxWidget(source: source, widgetName: 'RapidToggle')),
      ));
      await tester.pump();

      final finder = find.byKey(const ValueKey<dynamic>("box"));
      final button = find.text('Toggle');

      // Rapid toggles before animation completes
      await tester.tap(button); // on = true
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(button); // on = false
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(button); // on = true
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Let it settle
      await tester.pumpAndSettle();

      // Final state should be on = true, width = 150
      expect(tester.getSize(finder).width, 150.0);
    });

    testWidgets('multiple animated containers render correctly',
        (tester) async {
      const source = '''
        widget MultiBox {
          state active = 0;
          
          build {
            Column {
              Button("Box1", onPressed: fn() { active = 1; });
              Button("Box2", onPressed: fn() { active = 2; });
              Button("Box3", onPressed: fn() { active = 3; });
              
              var w1 = 50.0;
              var w2 = 50.0;
              var w3 = 50.0;
              
              if (active == 1) { w1 = 100.0; }
              if (active == 2) { w2 = 100.0; }
              if (active == 3) { w3 = 100.0; }
              
              Row {
                AnimatedContainer(key: "b1", duration: 200, width: w1, height: 30.0, color: "red");
                AnimatedContainer(key: "b2", duration: 200, width: w2, height: 30.0, color: "green");
                AnimatedContainer(key: "b3", duration: 200, width: w3, height: 30.0, color: "blue");
              }
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home:
            Scaffold(body: FluxWidget(source: source, widgetName: 'MultiBox')),
      ));
      await tester.pump();

      final b1 = find.byKey(const ValueKey<dynamic>("b1"));
      final b2 = find.byKey(const ValueKey<dynamic>("b2"));
      final b3 = find.byKey(const ValueKey<dynamic>("b3"));

      // All start at 50
      expect(tester.getSize(b1).width, 50.0);
      expect(tester.getSize(b2).width, 50.0);
      expect(tester.getSize(b3).width, 50.0);

      // Activate box 2
      await tester.tap(find.text('Box2'));
      await tester.pumpAndSettle();

      expect(tester.getSize(b1).width, 50.0);
      expect(tester.getSize(b2).width, 100.0);
      expect(tester.getSize(b3).width, 50.0);

      // Activate box 1
      await tester.tap(find.text('Box1'));
      await tester.pumpAndSettle();

      expect(tester.getSize(b1).width, 100.0);
      expect(tester.getSize(b2).width, 50.0);
      expect(tester.getSize(b3).width, 50.0);
    });
  });
}
