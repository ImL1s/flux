import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'package:flux_flutter/src/bindings.dart';
import 'package:hot_update_demo/main.dart';

void main() {
  setUpAll(() {
    // CRITICAL: Initialize Flux bindings (Container, Text, etc.)
    FluxBindings.initDefaults();
  });

  testWidgets('Integration Test: Hot Update Flow (Headless)', (WidgetTester tester) async {
    print('🚀 Starting Headless Hot Update Test');
    
    // 1. Setup: Create a temporary Flux script file
    final tempDir = Directory.systemTemp.createTempSync('flux_demo_test');
    final scriptFile = File('${tempDir.path}/test_banner.flux');
    
    // Initial Script: Version 1
    final initialScript = '''
      widget HomeBanner {
        build {
          return SizedBox(width: 100, height: 100);
        }
      }
    ''';
    scriptFile.writeAsStringSync(initialScript);
    print('📝 Created temp script at: ${scriptFile.path}');

    // 2. Launch App with injected path
    // We use the same MyApp, but injecting the path to our temp file
    // This allows the app to "think" it's loading the real thing
    await tester.pumpWidget(MyApp(initialScriptPath: scriptFile.path));
    print('📱 App launched');

    // Pump to let the async file read happen
    // We pump 10 times with 100ms to allow async IO to complete
    for(int i=0; i<10; i++) await tester.pump(const Duration(milliseconds: 100));
    
    // 3. Verify Initial State
    expect(find.byType(SizedBox), findsWidgets);
    print('✅ SizedBox found - Initial Load Success');

    // 4. Perform "Hot Update" - Modify the file content on disk
    final updatedScript = '''
      widget HomeBanner {
        build {
          return Center(
            child: Text(text: "Version 2 (Updated)", style: {"color": "green"})
          );
        }
      }
    ''';
    scriptFile.writeAsStringSync(updatedScript);
    print('📝 Updated script file content on disk');
    
    // 5. Trigger Refresh in App
    // Find the refresh button in the AppBar
    final refreshBtn = find.byIcon(Icons.refresh);
    expect(refreshBtn, findsOneWidget);
    await tester.tap(refreshBtn);
    print('👆 Tapped Refresh Button');
    
    // Pump to process tap and subsequent file reload
    await tester.pump(); // Tap event
    for(int i=0; i<10; i++) await tester.pump(const Duration(milliseconds: 100)); // Async IO
    
    // 6. Verify Updated State
    // "Version 1" should be gone
    expect(find.text('Version 1'), findsNothing);
    // "Version 2 (Updated)" should be present
    expect(find.text('Version 2 (Updated)'), findsOneWidget);
    print('✅ "Version 2 (Updated)" UI found - Hot Update Success!');

    // Cleanup
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
    print('🏁 Test Completed Successfully');
  });
}
