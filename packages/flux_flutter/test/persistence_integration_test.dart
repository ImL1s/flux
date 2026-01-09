import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  group('Flux State Persistence Integration', () {
    testWidgets('persistent state survives widget recreation',
        (WidgetTester tester) async {
      final delegate = InMemoryPersistenceDelegate();

      const source = '''
        widget Counter {
          persistent state count = 0;
          
          build {
            Column(
              children: [
                Text(text: toString(count)),
                Button(
                  text: "Increment",
                  onPressed: fn() {
                    count = count + 1;
                  }
                )
              ]
            )
          }
        }
      ''';

      await tester.pumpWidget(
        MaterialApp(
            home: FluxWidget(
          source: source,
          widgetName: 'Counter',
          enablePersistence: true,
          persistenceDelegate: delegate,
        )),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.text('Increment'));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.text('Increment'));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      // Restart
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        MaterialApp(
            home: FluxWidget(
          source: source,
          widgetName: 'Counter',
          enablePersistence: true,
          persistenceDelegate: delegate,
        )),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('non-persistent state does not survive recreation',
        (WidgetTester tester) async {
      final delegate = InMemoryPersistenceDelegate();

      const source = '''
        widget Counter {
          state count = 0;
          
          build {
            Column(
              children: [
                Text(text: toString(count)),
                Button(
                  text: "Increment",
                  onPressed: fn() {
                    count = count + 1;
                  }
                )
              ]
            )
          }
        }
      ''';

      await tester.pumpWidget(
        MaterialApp(
            home: FluxWidget(
          source: source,
          widgetName: 'Counter',
          enablePersistence: true,
          persistenceDelegate: delegate,
        )),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Increment'));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      // Restart
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(
        MaterialApp(
            home: FluxWidget(
          source: source,
          widgetName: 'Counter',
          enablePersistence: true,
          persistenceDelegate: delegate,
        )),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('0'), findsOneWidget);
    });
  });
}
