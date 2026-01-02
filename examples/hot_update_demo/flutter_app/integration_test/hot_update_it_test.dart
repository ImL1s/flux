import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'package:flux_flutter/src/bindings.dart';
import 'package:hot_update_demo/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    FluxBindings.initDefaults();
  });

  testWidgets('Headed Hot Update Test', (WidgetTester tester) async {
    // 1. Create temporary Flux script
    final tempDir = Directory.systemTemp.createTempSync('flux_it_test');
    final scriptFile = File('${tempDir.path}/test_banner.flux');
    
    // Initial Script
    scriptFile.writeAsStringSync('''
      widget HomeBanner {
        build {
          return Container(
            color: "red",
            child: Text(text: "Version A", style: {"color": "white", "fontSize": 24})
          );
        }
      }
    ''');
    
    print('IT: Created script at ${scriptFile.path}');

    // 2. Launch App with injected path
    await tester.pumpWidget(MyApp(initialScriptPath: scriptFile.path));
    await tester.pumpAndSettle();
    
    // 3. Verify Version A
    expect(find.text('Version A'), findsOneWidget);
    print('IT: Version A verified');
    
    // 4. Update Script
    scriptFile.writeAsStringSync('''
      widget HomeBanner {
        build {
          return Container(
            color: "green",
            child: Text(text: "Version B", style: {"color": "white", "fontSize": 24})
          );
        }
      }
    ''');
    print('IT: Script updated to Version B');
    
    // 5. Click Refresh
    final refreshBtn = find.byIcon(Icons.refresh);
    await tester.tap(refreshBtn);
    await tester.pumpAndSettle(const Duration(milliseconds: 100)); // wait for tap
    
    // Wait for file read (async)
    // We loop pump to allow IO to complete
    for (int i=0; i<10; i++) {
        await tester.pump(const Duration(milliseconds: 200));
        if (find.text('Version B').evaluate().isNotEmpty) break;
    }

    // 6. Verify Version B
    expect(find.text('Version B'), findsOneWidget);
    print('IT: Version B verified - Hot Update Successful!');
    
    // Cleanup
    tempDir.deleteSync(recursive: true);
  });
}
