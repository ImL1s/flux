import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/flux_flutter.dart';

void main() {
  setUpAll(() {
    FluxBindings.initDefaults();
  });

  group('Flux ToDo Demo', () {
    testWidgets('Complete App Flow', (tester) async {
      // 1. Define Flux Code (Main List and Add Page)
      const fluxCode = '''
      widget TaskList {
        state tasks = "foo";
        
        build {
          Scaffold(
            appBar: AppBar(title: Text("Flux ToDo")),
            body: Column(
              children: [
                Text("Debug Message")
              ]
            )
          )
        }
      }

      widget AddTaskParam {
        state newTask = "";

        build {
          Scaffold(
            appBar: AppBar(title: Text("Add Task")),
            body: Column(
              children: []
            )
          )
        }
      }
      ''';

      // 2. Setup App with Navigator using the FluxBindings key
      await tester.pumpWidget(MaterialApp(
        navigatorKey: FluxBindings.navigatorKey,
        home: const FluxWidget(
          source: fluxCode,
          widgetName: 'TaskList',
        ),
        routes: {
          '/add': (context) => const FluxWidget(
                source: fluxCode,
                widgetName: 'AddTaskParam',
              ),
        },
      ));

      await tester.pump();

      // 3. Verify Initial State
      expect(find.text('Debug Message'), findsOneWidget);

      // End test for now
    });
  });
}
