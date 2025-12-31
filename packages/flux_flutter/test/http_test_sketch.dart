import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() {
    FluxBindings.initDefaults();
  });

  group('HttpBindings', () {
    testWidgets('http_get returns status and body', (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
         if (request.url.path == '/test') {
           return http.Response('{"message": "success"}', 200, headers: {'content-type': 'application/json'});
         }
         return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        final source = '''
          widget HttpTest {
            state status = 0;
            state message = "loading";

            build {
              Column {
                 Text(toString(status))
                 Text(message)
                 Button("Fetch", onPressed: async fn() {
                    status = 1; // Loading
                    try {
                       var response = await http_get("http://example.com/test");
                       if (response["statusCode"] == 200) {
                          message = response["body"]["message"];
                          status = 2; // Success
                       } else {
                          message = "Error: " + toString(response["statusCode"]);
                          status = 3; // Error
                       }
                    } catch (e) {
                       message = "Exception: " + toString(e);
                       status = 4;
                    }
                 })
              }
            }
          }
        ''';
        
        // Create runtime directly from source
        final runtime = FluxRuntime(source);
        
        // Pump widget
        await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'HttpTest', runtime: runtime)));
        
        expect(find.text('0'), findsOneWidget);
        expect(find.text('loading'), findsOneWidget);
        
        // Tap Fetch
        await tester.tap(find.text('Fetch'));
        await tester.pump(); // Update status to 1? 
        // Note: async functions return a Future. 
        // The VM executes `onPressed` which calls `http_get`.
        // `http_get` returns a generic Future (from Dart).
        // `await` opcode suspends VM.
        // We need to wait for the Future to complete. 
        // flutter_test pumpAndSettle might work if the Future is tracked by Flutter bindings?
        // But here it's a Dart Future from http package.
        
        // We need to wait enough time or pump frames.
        await tester.pump(const Duration(milliseconds: 100)); // Allow async to start
        
        // Since we mock the client, it should be fast.
        await tester.pumpAndSettle();
        
        expect(find.text('success'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      }, () => mockClient);
    });
  });
}
