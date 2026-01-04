import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/ui/flux_ui.dart';

void main() {
  group('FluxUI Core Components', () {
    testWidgets('FluxButton renders correctly', (tester) async {
      await tester.pumpWidget(
        FluxThemeProvider(
          theme: FluxTheme.light(),
          child: MaterialApp(
            home: Scaffold(
              body: FluxButton(
                label: 'Test Button',
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget); // Default is primary -> ElevatedButton
    });

    testWidgets('FluxButton loading state', (tester) async {
      await tester.pumpWidget(
        FluxThemeProvider(
          theme: FluxTheme.light(),
          child: MaterialApp(
            home: Scaffold(
              body: FluxButton(
                label: 'Loading',
                isLoading: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('FluxInput renders correctly', (tester) async {
      await tester.pumpWidget(
        FluxThemeProvider(
          theme: FluxTheme.light(),
          child: MaterialApp(
            home: Scaffold(
              body: FluxInput(
                label: 'Test Input',
                initialValue: 'Initial',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Input'), findsOneWidget);
      expect(find.text('Initial'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('FluxCard renders correctly', (tester) async {
      await tester.pumpWidget(
        FluxThemeProvider(
          theme: FluxTheme.light(),
          child: MaterialApp(
            home: Scaffold(
              body: FluxCard(
                child: Text('Card Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('FluxBadge renders correctly', (tester) async {
      await tester.pumpWidget(
        FluxThemeProvider(
          theme: FluxTheme.light(),
          child: MaterialApp(
            home: Scaffold(
              body: FluxBadge(
                variant: FluxBadgeVariant.count,
                count: 5,
                child: Icon(Icons.notifications),
              ),
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
    });
  });

  group('FluxUI Layout Components', () {
    testWidgets('FluxRow renders with spacing', (tester) async {
      await tester.pumpWidget(
        FluxThemeProvider(
          theme: FluxTheme.light(),
          child: MaterialApp(
            home: Scaffold(
              body: FluxRow(
                spacing: 10,
                children: [
                   Text('1'),
                   Text('2'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      // Checking for exact spacing is harder in widget test without physical layout check,
      // but verifying it doesn't crash and renders children is good baseline.
      expect(find.byType(SizedBox), findsWidgets); // Spacers are Sizedboxes
    });

    testWidgets('FluxGrid renders correctly', (tester) async {
      await tester.pumpWidget(
        FluxThemeProvider(
          theme: FluxTheme.light(),
          child: MaterialApp(
            home: Scaffold(
              body: FluxGrid(
                crossAxisCount: 2,
                children: [Text('1'), Text('2')],
              ),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });
  });
}
