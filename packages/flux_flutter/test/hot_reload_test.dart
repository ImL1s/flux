import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_flutter/flux_flutter.dart';

void main() {
  testWidgets('FluxRuntime.hotReload updates widget definition', (WidgetTester tester) async {
    // 1. Initial State
    final runtime = FluxRuntime('''
      widget TestWidget {
        state count = 0;
        build {
          Column {
             Text("Version 1")
             Text(toString(count))
             Button("Inc", onPressed: fn() {
               count = count + 1;
             })
          }
        }
      }
    ''');
    
    await tester.pumpWidget(MaterialApp(
      home: FluxWidget(
        runtime: runtime,
        widgetName: 'TestWidget',
      ),
    ));

    expect(find.text('Version 1'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    
    // 2. Change State
    await tester.tap(find.widgetWithText(ElevatedButton, 'Inc'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    
    // 3. Hot Reload (Change UI, Keep State)
    final newSource = '''
      widget TestWidget {
        state count = 0;
        build {
          Column {
             Text("Version 2")
             Text("Count is: " + toString(count))
             Button("Inc", onPressed: fn() {
               count = count + 1;
             })
          }
        }
      }
    ''';
    
    // Compile new source to get chunk
    final tokens = Lexer(newSource).tokenize();
    final parser = Parser(tokens);
    final unit = parser.parse();
    final compiler = Compiler(unit: unit);
    final function = compiler.endCompiler();
    
    // Perform Hot Reload
    runtime.hotReload(function.chunk);
    
    // Trigger Rebuild
    await tester.pumpWidget(MaterialApp(
      home: FluxWidget(
        runtime: runtime,
        widgetName: 'TestWidget',
      ),
    )); 
    // Note: FluxWidget listens to runtime state changes, but for definition changes 
    // we might need to trigger rebuild manually or through `FluxHotReloadWidget` which does setState.
    // In this raw test, re-pumping with same runtime should pick up new definitions because 
    // FluxBindings.get(widgetName) will return the new builder if hotReload updated registries correctly.
    // Wait, FluxWidgetState uses `executeBuild` which uses `widgetName`.
    // The `_handleWidgetCall` uses `compiledWidget`. 
    // We need to ensure `_FluxRiverpodRuntime` (or base runtime) updates `_widgets` map.
    
    await tester.pump();

    // Verify UI updated
    expect(find.text('Version 2'), findsOneWidget);
    
    // Verify State preserved (Count should still be 1)
    expect(find.text('Count is: 1'), findsOneWidget);
  });
}
