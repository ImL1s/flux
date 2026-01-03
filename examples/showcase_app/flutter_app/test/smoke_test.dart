import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcase_app/main.dart';

void main() {
  group('Smoke Tests', () {
    testWidgets('App should bootstrap and show first page without crash', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: ShowcaseApp(),
        ),
      );

      // Verify app title
      expect(find.text('Flux Showcase'), findsNothing); // It's the MaterialApp title, not usually in tree
      
      // Verify first page (電商產品)
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('電商產品'), findsWidgets);
      
      // Verify NavigationBar exists
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('Quickly tapping all tabs should not crash', (tester) async {
       await tester.pumpWidget(
        const ProviderScope(
          child: ShowcaseApp(),
        ),
      );
      
      final tabs = ['待辦', '設定', '儀表板', '商品'];
      for (final tab in tabs) {
        await tester.tap(find.text(tab));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        // Verify we are not on an error screen (basic check)
        expect(find.textContaining('❌ 錯誤'), findsNothing);
      }
    });
  });
}
