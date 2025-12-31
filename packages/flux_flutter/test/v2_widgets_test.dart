import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  testWidgets('Phase 24: TabBar and Scaffold layout', (WidgetTester tester) async {
    final fluxCode = r'''
    widget Main {
      build {
        DefaultTabController(length: 2) {
          Scaffold(
            appBar: AppBar(
              title: Text("Tabs Demo"),
              bottom: TabBar(
                tabs: [
                  Tab(text: "Tab 1"),
                  Tab(text: "Tab 2")
                ]
              )
            ),
            body: TabBarView(
              children: [
                Center(child: Text("Page 1")),
                Center(child: Text("Page 2"))
              ]
            )
          )
        }
      }
    }
    ''';

    await tester.pumpWidget(
      MaterialApp(
        home: FluxWidget(
          source: fluxCode,
          widgetName: 'Main',
        ),
      ),
    );

    // Verify initial render
    // debugDumpApp();
    expect(find.text("Tabs Demo"), findsOneWidget);
    expect(find.text("Tab 1"), findsOneWidget);
    expect(find.text("Tab 2"), findsOneWidget);
    
    // TabBarView usually renders current page. "Page 1" should be visible.
    // We might need to wait for async machinery, but FluxWidget is synchronous usually.
    await tester.pumpAndSettle();
    
    expect(find.text("Page 1"), findsOneWidget);
    
    // Tap second tab
    await tester.tap(find.text("Tab 2"));
    await tester.pumpAndSettle();
    
    expect(find.text("Page 2"), findsOneWidget);
  });

  testWidgets('Phase 24: Form and Input widgets', (WidgetTester tester) async {
    final fluxCode = r'''
    widget Main {
      build {
        Scaffold(
          body: Form(
            child: Column(
              children: [
                 TextFormField(initialValue: "Test Input"),
                 Switch(value: true),
                 Slider(value: 0.5, min: 0.0, max: 1.0)
              ]
            )
          )
        )
      }
    }
    ''';

    await tester.pumpWidget(
      MaterialApp(
        home: FluxWidget(
          source: fluxCode,
          widgetName: 'Main',
        ),
      ),
    );
    
    await tester.pumpAndSettle();

    expect(find.byType(Form), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    // expect(find.text("Test Input"), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('Phase 24: Animation widgets (Hero)', (WidgetTester tester) async {
    final fluxCode = r'''
    widget Main {
      build {
        Hero(
          tag: "hero-tag",
          child: Container(width: 100, height: 100, color: 4278190335)
        )
      }
    }
    ''';

    await tester.pumpWidget(
      MaterialApp(
        home: FluxWidget(
          source: fluxCode,
          widgetName: 'Main',
        ),
      ),
    );
    
    await tester.pumpAndSettle();

    expect(find.byType(Hero), findsOneWidget);
    // Find Container by size - harder with finders, but if Hero builds, good enough.
    // Verify tag
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, "hero-tag");
  });
}
