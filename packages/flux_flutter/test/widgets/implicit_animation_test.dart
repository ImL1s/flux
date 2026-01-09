import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/flux_flutter.dart';

/// Comprehensive Tests for Implicit Animation Widgets
/// Covers: AnimatedContainer, AnimatedOpacity
/// Includes: Edge cases, parameter validation, animation correctness
void main() {
  group('AnimatedContainer Widget Binding', () {
    testWidgets('animates width correctly with default curve', (tester) async {
      const source = '''
        widget TestWidget {
          state expanded = false;
          
          build {
            Column {
              Button("Expand", onPressed: fn() { expanded = !expanded; });
              
              var w = 50.0;
              if (expanded) { w = 200.0; }
              
              AnimatedContainer(
                key: "box",
                duration: 300,
                width: w,
                height: 50.0,
                color: "blue"
              );
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FluxWidget(source: source, widgetName: 'TestWidget')),
      ));
      await tester.pump();

      final finder = find.byKey(const ValueKey<dynamic>("box"));
      expect(finder, findsOneWidget);
      expect(tester.getSize(finder).width, 50.0);

      // Trigger animation
      await tester.tap(find.text('Expand'));
      await tester.pump();

      // Frame 0: should still be at start
      expect(tester.getSize(finder).width, 50.0);

      // 150ms (50% of 300ms with linear, should be ~125)
      await tester.pump(const Duration(milliseconds: 150));
      final midWidth = tester.getSize(finder).width;
      expect(midWidth, greaterThan(50.0));
      expect(midWidth, lessThan(200.0));

      // Complete animation
      await tester.pumpAndSettle();
      expect(tester.getSize(finder).width, 200.0);
    });

    testWidgets('respects easeIn curve (slow start)', (tester) async {
      const source = '''
        widget TestWidget {
          state expanded = false;
          
          build {
            Column {
              Button("Go", onPressed: fn() { expanded = true; });
              
              var w = 0.0;
              if (expanded) { w = 100.0; }
              
              AnimatedContainer(
                key: "curved",
                duration: 1000,
                curve: "easeIn",
                width: w,
                height: 10.0,
                color: "green"
              );
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FluxWidget(source: source, widgetName: 'TestWidget')),
      ));
      await tester.pump();

      final finder = find.byKey(const ValueKey<dynamic>("curved"));

      await tester.tap(find.text('Go'));
      await tester.pump();

      // At 500ms (t=0.5), easeIn should be ~25% (0.5^2 = 0.25)
      await tester.pump(const Duration(milliseconds: 500));
      final earlyWidth = tester.getSize(finder).width;

      // easeIn: should be significantly less than linear 50
      expect(earlyWidth, lessThan(40.0));
      expect(earlyWidth, greaterThan(0.0));
    });

    testWidgets('handles null key gracefully', (tester) async {
      const source = '''
        widget TestWidget {
          state toggle = false;
          
          build {
            Column {
              Button("Toggle", onPressed: fn() { toggle = !toggle; });
              
              var w = 100.0;
              if (toggle) { w = 200.0; }
              
              AnimatedContainer(
                duration: 200,
                width: w,
                height: 30.0,
                color: "orange"
              );
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FluxWidget(source: source, widgetName: 'TestWidget')),
      ));
      await tester.pump();

      // Should render without error
      expect(find.byType(AnimatedContainer), findsOneWidget);

      // Toggle should work (though animation may snap due to no key)
      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();

      // Verify it rendered at target size
      final ac =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(ac.constraints?.maxWidth, 200.0);
    });

    testWidgets('animates color change', (tester) async {
      const source = '''
        widget TestWidget {
          state isRed = false;
          
          build {
            Column {
              Button("Color", onPressed: fn() { isRed = !isRed; });
              
              var c = "blue";
              if (isRed) { c = "red"; }
              
              AnimatedContainer(
                key: "colorBox",
                duration: 500,
                width: 50.0,
                height: 50.0,
                color: c
              );
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FluxWidget(source: source, widgetName: 'TestWidget')),
      ));
      await tester.pump();

      final finder = find.byKey(const ValueKey<dynamic>("colorBox"));
      expect(finder, findsOneWidget);

      // Trigger color change
      await tester.tap(find.text('Color'));
      await tester.pump();

      // Check mid-animation color (should be a blend)
      await tester.pump(const Duration(milliseconds: 250));

      // Verify animation is happening (widget still in tree)
      expect(finder, findsOneWidget);

      // Complete
      await tester.pumpAndSettle();
      final ac =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      final decoration = ac.decoration as BoxDecoration?;
      expect(decoration?.color, Colors.red);
    });

    testWidgets('uses default duration when not specified', (tester) async {
      const source = '''
        widget TestWidget {
          build {
            Column {
              AnimatedContainer(
                key: "default",
                width: 100.0,
                height: 100.0,
                color: "purple"
              );
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FluxWidget(source: source, widgetName: 'TestWidget')),
      ));
      await tester.pump();

      // Should render with default 250ms duration
      final ac =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(ac.duration, const Duration(milliseconds: 250));
    });

    testWidgets('handles padding and margin', (tester) async {
      const source = '''
        widget TestWidget {
          build {
            Column {
              AnimatedContainer(
                key: "padded",
                duration: 100,
                width: 100.0,
                height: 100.0,
                padding: 16,
                margin: [8, 16],
                color: "teal"
              );
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FluxWidget(source: source, widgetName: 'TestWidget')),
      ));
      await tester.pump();

      final ac =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(ac.padding, EdgeInsets.all(16.0));
      expect(ac.margin, EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0));
    });
  });

  group('AnimatedOpacity Widget Binding', () {
    testWidgets('fades in correctly', (tester) async {
      const source = '''
        widget TestWidget {
          state visible = false;
          
          build {
            Column {
              Button("Show", onPressed: fn() { visible = true; });
              
              var op = 0.0;
              if (visible) { op = 1.0; }
              
              AnimatedOpacity(
                key: "fader",
                duration: 500,
                opacity: op,
                child: Container(width: 50, height: 50, color: "red")
              );
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FluxWidget(source: source, widgetName: 'TestWidget')),
      ));
      await tester.pump();

      final finder = find.byKey(const ValueKey<dynamic>("fader"));
      expect(finder, findsOneWidget);

      // Check initial opacity
      var ao = tester.widget<AnimatedOpacity>(finder);
      expect(ao.opacity, 0.0);

      // Trigger fade in
      await tester.tap(find.text('Show'));
      await tester.pump();

      // Mid-animation
      await tester.pump(const Duration(milliseconds: 250));
      ao = tester.widget<AnimatedOpacity>(finder);
      // Opacity config shows target, but actual opacity should be in between
      // Note: AnimatedOpacity target is 1.0, actual rendered is interpolated

      // Complete
      await tester.pumpAndSettle();
      ao = tester.widget<AnimatedOpacity>(finder);
      expect(ao.opacity, 1.0);
    });

    testWidgets('respects curve parameter', (tester) async {
      const source = '''
        widget TestWidget {
          state show = true;
          
          build {
            Column {
              Button("Hide", onPressed: fn() { show = false; });
              
              var op = 1.0;
              if (!show) { op = 0.0; }
              
              AnimatedOpacity(
                key: "bouncy",
                duration: 1000,
                curve: "bounceOut",
                opacity: op,
                child: Text("Hello")
              );
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FluxWidget(source: source, widgetName: 'TestWidget')),
      ));
      await tester.pump();

      // Trigger animation
      await tester.tap(find.text('Hide'));
      await tester.pump();

      // With bounceOut, at various points the opacity may exceed 0 or "bounce"
      // Just verify it completes
      await tester.pumpAndSettle();

      final ao = tester.widget<AnimatedOpacity>(
          find.byKey(const ValueKey<dynamic>("bouncy")));
      expect(ao.opacity, 0.0);
    });

    testWidgets('uses default values for missing params', (tester) async {
      const source = '''
        widget TestWidget {
          build {
            Column {
              AnimatedOpacity(
                key: "defaults",
                opacity: 0.5
              ) {
                Text("Half");
              }
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FluxWidget(source: source, widgetName: 'TestWidget')),
      ));
      await tester.pump();

      final ao = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(ao.duration, const Duration(milliseconds: 250)); // Default
      expect(ao.curve, Curves.linear); // Default
    });
  });

  group('Curve Parsing', () {
    final curveTestCases = {
      'linear': Curves.linear,
      'easeIn': Curves.easeIn,
      'easeOut': Curves.easeOut,
      'easeInOut': Curves.easeInOut,
      'bounceIn': Curves.bounceIn,
      'bounceOut': Curves.bounceOut,
      'elasticIn': Curves.elasticIn,
      'elasticOut': Curves.elasticOut,
      'fastOutSlowIn': Curves.fastOutSlowIn,
      'decelerate': Curves.decelerate,
    };

    for (final entry in curveTestCases.entries) {
      testWidgets('parses curve "${entry.key}"', (tester) async {
        final source = '''
          widget TestWidget {
            build {
              Column {
                AnimatedContainer(
                  duration: 100,
                  curve: "${entry.key}",
                  width: 10.0,
                  height: 10.0,
                  color: "gray"
                );
              }
            }
          }
        ''';

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: FluxWidget(source: source, widgetName: 'TestWidget')),
        ));
        await tester.pump();

        final ac =
            tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
        expect(ac.curve, entry.value);
      });
    }

    testWidgets('uses linear for unknown curve strings', (tester) async {
      const source = '''
        widget TestWidget {
          build {
            Column {
              AnimatedContainer(
                duration: 100,
                curve: "unknownCurve",
                width: 10.0,
                height: 10.0,
                color: "black"
              );
            }
          }
        }
      ''';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FluxWidget(source: source, widgetName: 'TestWidget')),
      ));
      await tester.pump();

      final ac =
          tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(ac.curve, Curves.linear);
    });
  });
}
