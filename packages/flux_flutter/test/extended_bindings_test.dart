import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/flux_flutter.dart';

void main() {
  testWidgets('FluxRiverpodWidget renders Scaffold with AppBar and FloatingActionButton', (tester) async {
    const source = r'''
      widget App {
        build {
          Scaffold(
            appBar: AppBar(title: Text("My Title")),
            body: Center(child: Text("Body Content")),
            floatingActionButton: FloatingActionButton(
              child: Icon("add"),
              onPressed: fn() { print("FAB Clicked"); }
            )
          )
        }
      }
    ''';

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FluxRiverpodWidget(
            source: source,
            widgetName: 'App',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify properties
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('My Title'), findsOneWidget);
    expect(find.text('Body Content'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('FluxRiverpodWidget handles recursive argument conversion (nested widgets)', (tester) async {
    // This tests _preprocessArgs converting FluxWidgetNodes in arguments
    const source = r'''
      widget CustomContainer {
        build {
          Column(
            children: [
              _SubWidget(header: Text("Header Text")),
              Text("Footer Text")
            ]
          )
        }
      }

      widget _SubWidget {
        props header;
        build {
          // Accessing the 'header' argument which should be converted to a Widget
          Container(child: header)
        }
      }
    ''';

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FluxRiverpodWidget(
            source: source,
            widgetName: 'CustomContainer',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Header Text'), findsOneWidget);
  });

  testWidgets('FluxRiverpodWidget handles Button onPressed callback', (tester) async {
    const source = r'''
      widget CounterApp {
        state count = 0;
        build {
          Column(children: [
            Text(count),
            Button(
              text: "Increment",
              onPressed: fn() { count = count + 1; }
            )
          ])
        }
      }
    ''';

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FluxRiverpodWidget(
            source: source,
            widgetName: 'CounterApp',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initial state
    expect(find.text('0'), findsOneWidget);
    expect(find.text('Increment'), findsOneWidget);

    // Tap button
    await tester.tap(find.text('Increment'));
    await tester.pumpAndSettle();

    // State should be updated
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('FluxRiverpodWidget handles ListView with children', (tester) async {
    const source = r'''
      widget ListApp {
        build {
          ListView(children: [
            Text("Item 1"),
            Text("Item 2"),
            Text("Item 3")
          ])
        }
      }
    ''';

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FluxRiverpodWidget(
            source: source,
            widgetName: 'ListApp',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 3'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });
}
