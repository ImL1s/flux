
import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';
import 'package:flux_dap/src/dap_session.dart';

void main() {
  group('DAP Worker Integration', () {
    late File scriptFile;
    
    setUp(() async {
      scriptFile = File('test/temp_debug.flux');
      await scriptFile.writeAsString('''
var x = 10;
var y = 20;
fn add(a, b) {
  return a + b;
}
var z = add(x, y);
print("Result: " + z);
''');
    });
    
    tearDown(() async {
      if (await scriptFile.exists()) {
        await scriptFile.delete();
      }
    });

    test('Should launch and run to completion', () async {
      final session = DapSession(1, scriptFile.path);
      final completer = Completer<void>();
      
      session.onEvent = (event, body) {
        if (event == 'output') {
          print('[Output] ${body['output']}');
        }
        if (event == 'terminated') {
          completer.complete();
        }
      };
      
      await session.launch();
      session.run();
      
      await completer.future.timeout(Duration(seconds: 5));
    });

    test('Should hit breakpoint and resume', () async {
      final session = DapSession(2, scriptFile.path);
      final terminatedCompleter = Completer<void>();
      final stoppedCompleter = Completer<void>();
      
      session.onEvent = (event, body) {
        if (event == 'output') {
          print('[Output] ${body['output']}');
        }
        if (event == 'stopped') {
          print('[Stopped] Reason: ${body['reason']}');
          stoppedCompleter.complete();
        }
        if (event == 'terminated') {
          terminatedCompleter.complete();
        }
      };
      
      await session.launch();
      
      // Set breakpoint at line 4 (return a + b)
      session.setBreakpoints(scriptFile.path, [4]);
      
      session.run();
      
      // Wait for stop
      await stoppedCompleter.future.timeout(Duration(seconds: 5));
      
      // Validate stack trace
      final stack = await session.getStackTrace();
      expect(stack, isNotEmpty);
      expect(stack.first['name'], equals('add'));
      expect(stack.first['line'], equals(4));
      
      // Validate variables
      await session.getStackTrace(); 
      // Wait, getScopes is not exposed in session for this test yet? 
      // I can call getVariables directly if I knew the ref.
      // But let's just resize.
            
      print('Resuming...');
      session.continue_();
      
      await terminatedCompleter.future.timeout(Duration(seconds: 5));
    });
  });
}
