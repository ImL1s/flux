import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/flux_flutter.dart';

void main() {
  group('FluxOtaDemo Widget Tests', () {
    testWidgets('renders initial UI state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FluxOtaDemo()),
        ),
      );

      // Just wait for initial build, allow for errors during Flux compilation
      await tester.pump(const Duration(milliseconds: 100));

      // Check button existence
      expect(find.text('Check for Update'), findsOneWidget);
      expect(find.text('Rollback'), findsOneWidget);
    });

    testWidgets('shows update status when update button pressed',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FluxOtaDemo()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Tap update button
      await tester.tap(find.text('Check for Update'));
      await tester.pump();

      // Should show checking status
      expect(find.text('Checking for updates...'), findsOneWidget);

      // Clean up timer - need to cover the whole simulation (500+800+300 = 1600ms)
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('completes update workflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FluxOtaDemo()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Start update
      await tester.tap(find.text('Check for Update'));

      // Let the simulated update complete
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Update found! Downloading...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Applying update...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Updated to v1.1.0! ✅'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('rollback works after update', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FluxOtaDemo()),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Perform update first - complete the whole workflow
      await tester.tap(find.text('Check for Update'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pump(const Duration(milliseconds: 400));

      // Verify update completed
      expect(find.text('Updated to v1.1.0! ✅'), findsOneWidget);

      // Now rollback should be available
      await tester.tap(find.text('Rollback'));
      await tester.pump();

      expect(find.text('Rolling back...'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Rolled back to v1.0.0'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
    });
  });
}
