import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'package:flux_compiler/flux_compiler.dart'; // Needed for compilation

Chunk compile(String source) {
  final lexer = Lexer(source);
  final tokens = lexer.tokenize();
  final parser = Parser(tokens);
  final unit = parser.parse();
  
  if (parser.errors.isNotEmpty) {
    throw Exception('Compilation failed with ${parser.errors.length} errors: ${parser.errors}');
  }
  
  final compiler = Compiler(unit: unit);
  return compiler.endCompiler().chunk;
}

void main() {
  group('Flux Hot Reload Comprehensive Tests', () {
    
    testWidgets('Preserves matching state when adding new state fields', (WidgetTester tester) async {
      final v1 = '''
        widget TestWidget {
          state count = 10;
          build {
            Column {
               Text("V1")
               Text("Count: " + toString(count))
            }
          }
        }
      ''';
      
      final runtime = FluxRuntime(v1);
      final widget = FluxWidget(
        widgetName: 'TestWidget',
        runtime: runtime,
      );
      
      await tester.pumpWidget(MaterialApp(home: widget));
      expect(find.text('V1'), findsOneWidget);
      expect(find.text('Count: 10'), findsOneWidget);
      
      final v2 = '''
        widget TestWidget {
          state count = 999;
          state name = "Flux";
          build {
            Column {
               Text("V2")
               Text("Count: " + toString(count))
               Text("Name: " + name)
            }
          }
        }
      ''';
      
      runtime.hotReload(compile(v2));
      await tester.pump();
      
      expect(find.text('V2'), findsOneWidget);
      expect(find.text('Count: 10'), findsOneWidget); // Preserved
      expect(find.text('Name: Flux'), findsOneWidget); // New field default
    });

    testWidgets('Handles removing state fields gracefully', (WidgetTester tester) async {
      final v1 = '''
        widget TestWidget {
          state a = "kept";
          state b = "removed";
          build {
            Column {
               Text(a)
               Text(b)
            }
          }
        }
      ''';
      
      final runtime = FluxRuntime(v1);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'TestWidget', runtime: runtime)));
      expect(find.text('kept'), findsOneWidget);
      expect(find.text('removed'), findsOneWidget);
      
      final v2 = '''
        widget TestWidget {
          state a = "new default"; 
          build {
            Column {
               Text(a)
            }
          }
        }
      ''';
      
      runtime.hotReload(compile(v2));
      await tester.pump();
      
      expect(find.text('kept'), findsOneWidget);
      expect(find.text('removed'), findsNothing);
    });

    testWidgets('Updates closure logic while preserving captured state', (WidgetTester tester) async {
      final v1 = '''
        widget TestWidget {
          state count = 0;
          build {
            Column {
               Text(toString(count))
               Button("Action", onPressed: fn() {
                 count = count + 1;
               })
            }
          }
        }
      ''';
      
      final runtime = FluxRuntime(v1);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'TestWidget', runtime: runtime)));
      
      await tester.tap(find.text('Action'));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      
      final v2 = '''
        widget TestWidget {
          state count = 0;
          build {
            Column {
               Text(toString(count))
               Button("Action", onPressed: fn() {
                 count = count + 10;
               })
            }
          }
        }
      ''';
      
      runtime.hotReload(compile(v2));
      // Hot reload triggers onStateChange, but we still need to pump
      await tester.pump();
      
      expect(find.text('1'), findsOneWidget);
      
      await tester.tap(find.text('Action'));
      await tester.pump();
      // Should result in 11 (1 + 10)
      expect(find.text('11'), findsOneWidget);
    });

    testWidgets('Handles syntax errors by throwing (handled by wrapper in app)', (WidgetTester tester) async {
       // Since we compile manually here, parser will throw on syntax error.
       // This verifies that bad code won't reach hotReload if we check before.
       
       final v1 = '''
        widget TestWidget {
          build { Text("OK") }
        }
      ''';
      
      final runtime = FluxRuntime(v1);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'TestWidget', runtime: runtime)));
      expect(find.text('OK'), findsOneWidget);
      
      final v2 = '''
        widget TestWidget {
          build { Text("Broken" // missing brace
        }
      ''';
      
      // Verification: The Test setup itself throws, ensuring invalid code
      // never reaches runtime.hotReload.
      expect(() => compile(v2), throwsA(isA<Exception>()));
      
      // Ensure UI didn't break
      expect(find.text('OK'), findsOneWidget);
    });
  });
}
