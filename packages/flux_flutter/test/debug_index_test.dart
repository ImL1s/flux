import 'dart:io';
import 'package:flux_flutter/flux_flutter.dart';

void main() {
  FluxBindings.initDefaults();
  
  const source = r'''
    widget TestWidget {
      state todos = [];
      
      build {
        Column {
          Button("Add", onPressed: fn() {
            push(todos, "Item 1");
          })
          Column {
            var i = 0;
            while (i < todos.length) {
              var todo = todos[i];
              Text(todo)
              i = i + 1;
            }
          }
        }
      }
    }
  ''';

  final runtime = FluxRuntime(
    source,
  );
  
  try {
    final widget = runtime.renderWidget('TestWidget');
    print('SUCCESS: Built widget: ${widget.runtimeType}');
  } catch (e, stack) {
    print('ERROR: $e');
    print('STACK: $stack');
    exit(1);
  }
}
