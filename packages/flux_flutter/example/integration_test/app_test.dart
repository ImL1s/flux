import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:example/main.dart'; // import app
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Flux Showcase E2E Navigation Test', (WidgetTester tester) async {
    // 1. Launch App
    await tester.pumpWidget(const ProviderScope(child: FluxShowcaseApp()));
    await tester.pumpAndSettle();

    // 2. Verify Dashboard
    expect(find.text('Flux Gallery'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);

    // 3. Navigate to Language Demo
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    // 4. Verify Language View Loaded
    expect(find.text('Flux Language Benchmarks'), findsOneWidget);
    expect(find.textContaining('Ready to run.'), findsOneWidget);

    // 5. Run Benchmark (Flux Logic)
    await tester.tap(find.text('Run Fibonacci (recursive)'));
    await tester.pumpAndSettle();
    
    // Verify Execution Time appeared (meaning Flux logic ran)
    expect(find.textContaining('Fib(25) = 121393'), findsOneWidget);

    // 6. Back to Dashboard
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // 7. Navigate to Storage
    await tester.tap(find.text('Storage'));
    await tester.pumpAndSettle();

    expect(find.text('Persistent Storage'), findsOneWidget);

    // 8. Back to Dashboard
     await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    
    expect(find.text('Flux Gallery'), findsOneWidget);
  });
}
