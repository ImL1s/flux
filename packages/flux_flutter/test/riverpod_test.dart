import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_flutter/flux_flutter.dart';

/// Riverpod integration tests for Flux
void main() {
  group('FluxRiverpodWidget', () {
    testWidgets('renders widget with Riverpod provider', (tester) async {
      // Define a simple notifier
      final counterProvider = NotifierProvider<_TestCounterNotifier, int>(
        _TestCounterNotifier.new,
      );

      const fluxSource = '''
        widget Counter {
          build {
            Column {
              Text("Count is set")
            }
          }
        }
      ''';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FluxRiverpodWidget(
                source: fluxSource,
                widgetName: 'Counter',
                notifierProviders: {
                  'counter': counterProvider,
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      // Should display text
      expect(find.text('Count is set'), findsOneWidget);
    });

    testWidgets('reads provider value', (tester) async {
      final nameProvider = NotifierProvider<_TestNameNotifier, String>(
        _TestNameNotifier.new,
      );

      const fluxSource = '''
        widget Hello {
          build {
            Text("Hello, " + getProvider("name") + "!")
          }
        }
      ''';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FluxRiverpodWidget(
                source: fluxSource,
                widgetName: 'Hello',
                notifierProviders: {
                  'name': nameProvider,
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Hello, Guest!'), findsOneWidget);
    });

    testWidgets('shows error for missing widget', (tester) async {
      const fluxSource = '''
        widget Counter {
          build {
            Text("Hello")
          }
        }
      ''';

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: FluxRiverpodWidget(
                source: fluxSource,
                widgetName: 'NonExistent', // Wrong name
                notifierProviders: const {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('not found'), findsOneWidget);
    });
  });
}

// Test Notifiers
class _TestCounterNotifier extends Notifier<int> with FluxSettableNotifier<int> {
  @override
  int build() => 0;
}

class _TestNameNotifier extends Notifier<String> with FluxSettableNotifier<String> {
  @override
  String build() => 'Guest';
}
