import 'package:flux_vm/flux_vm.dart';

import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('HTTP Module', () {
    late VM vm;

    setUp(() {
      vm = VM();
      // Manually inject print for visibility
      vm.globals['print'] = NativeFunction('print', 1, (args) {
        final msg = args[0].toString();
        print('VM PRINT: $msg');
        return null;
      });
      // Inject all stdlib functions and modules
      StdLib.init();
      for (final entry in StdLib.functions.entries) {
        if (!vm.globals.containsKey(entry.key)) {
          vm.globals[entry.key] = entry.value;
        }
      }
      for (final entry in StdLib.modules.entries) {
        vm.globals[entry.key] = entry.value;
      }
    });

    test('simple sync test', () {
      const source = '''
        var a = 42;
        return a + 1;
      ''';
      final result = vm.interpret(source);
      print('DEBUG SYNC: result=$result, stack=${vm.stack}');
      expect(result, equals(InterpretResult.ok));
      expect(vm.stack.last, 43);
    });

    test('http.get records response correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == 'https://example.com/api') {
          return http.Response(json.encode({'data': 'success'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      StdLib.setHttpClient(mockClient);

      const source = '''
        fn testFetch() {
          print("DEBUG: Entered testFetch");
          var resp = await http.get("https://example.com/api");
          print("DEBUG: Got response");
          return resp["status"];
        }
        return testFetch();
      ''';

      final result = await vm.interpret_async(source);
      print('DEBUG: result=$result, stack=${vm.stack}');
      expect(result, equals(InterpretResult.ok));
      expect(vm.stack.last, 200);
    });

    test('http.post sends body and receives response', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.body == 'hello') {
          return http.Response('received', 201);
        }
        return http.Response('error', 400);
      });

      StdLib.setHttpClient(mockClient);

      const source = '''
        fn testPost() {
          print("DEBUG: Entered testPost");
          var resp = await http.post("https://example.com/post", "hello");
          print("DEBUG: Got response");
          return resp["body"];
        }
        return testPost();
      ''';

      final result = await vm.interpret_async(source);
      print('DEBUG: result=$result, stack=${vm.stack}');
      expect(result, equals(InterpretResult.ok));
      expect(vm.stack.last, 'received');
    });
  });
}
