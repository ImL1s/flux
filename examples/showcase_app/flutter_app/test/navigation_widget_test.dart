import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcase_app/main.dart';

void main() {
  group('Navigation Widget Tests', () {
    testWidgets('Should navigate between pages via NavigationBar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: MainScaffold()),
        ),
      );

      // 1. Initial page should be Product Page (index 0)
      // Wait for loading to complete for at least the first page
      await tester.pump(); 
      await tester.pump(const Duration(seconds: 2)); // Give it time to load scripts
      
      expect(find.text('商品'), findsWidgets); 
      
      // 2. Tap on "待辦" (index 1)
      final todoTap = find.text('待辦');
      await tester.tap(todoTap);
      // Use pump with duration instead of pumpAndSettle because of infinite animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      
      // 3. Verify it moved to Todo page
      expect(find.text('待辦事項'), findsWidgets);
      
      // 4. Tap on "設定" (index 2)
      await tester.tap(find.text('設定'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('應用設定'), findsWidgets);
      
      // 5. Tap on "儀表板" (index 3)
      await tester.tap(find.text('儀表板'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('數據儀表板'), findsWidgets);
    });
  });
}
