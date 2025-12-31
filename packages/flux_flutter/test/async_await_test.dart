/// Comprehensive Async/Await Test Suite for Flux Language
///
/// This test suite validates the async/await implementation in Flux VM,
/// covering various scenarios including:
/// - Basic await operations
/// - Nested await expressions
/// - try/catch with async errors
/// - Sequential and parallel awaits
/// - State updates during async operations

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/flux_flutter.dart';

void main() {
  setUp(() {
    FluxBindings.initDefaults();
  });

  group('Basic Async/Await', () {
    testWidgets('simple await resolves and updates state', (WidgetTester tester) async {
      // Register a simple async function that returns after a delay
      FluxBindings.registerAsyncFunction('delay_return', (args) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return args.isNotEmpty ? args[0] : 'done';
      });

      final source = '''
        widget AsyncTest {
          state result = "pending";

          build {
            Column {
              Text(result)
              Button("Start", onPressed: async fn() {
                result = await delay_return("completed");
              })
            }
          }
        }
      ''';

      final runtime = FluxRuntime(source);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'AsyncTest', runtime: runtime)));

      expect(find.text('pending'), findsOneWidget);

      await tester.tap(find.text('Start'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('completed'), findsOneWidget);
    });

    testWidgets('await with immediate resolution', (WidgetTester tester) async {
      FluxBindings.registerAsyncFunction('immediate_return', (args) async {
        return 'instant';
      });

      final source = '''
        widget ImmediateAsyncTest {
          state value = "waiting";

          build {
            Column {
              Text(value)
              Button("Go", onPressed: async fn() {
                value = await immediate_return();
              })
            }
          }
        }
      ''';

      final runtime = FluxRuntime(source);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'ImmediateAsyncTest', runtime: runtime)));

      expect(find.text('waiting'), findsOneWidget);

      await tester.tap(find.text('Go'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('instant'), findsOneWidget);
    });
  });

  group('Sequential Awaits', () {
    testWidgets('multiple sequential awaits execute in order', (WidgetTester tester) async {
      FluxBindings.registerAsyncFunction('append_async', (args) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return args[0].toString() + args[1].toString();
      });

      final source = '''
        widget SequentialTest {
          state log = "";

          build {
            Column {
              Text(log)
              Button("Run", onPressed: async fn() {
                log = await append_async(log, "A");
                log = await append_async(log, "B");
                log = await append_async(log, "C");
              })
            }
          }
        }
      ''';

      final runtime = FluxRuntime(source);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'SequentialTest', runtime: runtime)));

      expect(find.text(''), findsOneWidget);

      await tester.tap(find.text('Run'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('ABC'), findsOneWidget);
    });
  });

  group('Try/Catch with Async', () {
    testWidgets('try/catch catches async errors', (WidgetTester tester) async {
      FluxBindings.registerAsyncFunction('throw_error', (args) async {
        await Future.delayed(const Duration(milliseconds: 5));
        throw Exception('Async failure');
      });

      final source = '''
        widget TryCatchAsyncTest {
          state status = "idle";
          state errorMsg = "";

          build {
            Column {
              Text(status)
              Text(errorMsg)
              Button("Trigger", onPressed: async fn() {
                status = "running";
                try {
                  var result = await throw_error();
                  status = "success";
                } catch (e) {
                  status = "failed";
                  errorMsg = toString(e);
                }
              })
            }
          }
        }
      ''';

      final runtime = FluxRuntime(source);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'TryCatchAsyncTest', runtime: runtime)));

      expect(find.text('idle'), findsOneWidget);

      await tester.tap(find.text('Trigger'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('failed'), findsOneWidget);
      expect(find.textContaining('Async failure'), findsOneWidget);
    });

    testWidgets('try/catch with successful async recovers', (WidgetTester tester) async {
      FluxBindings.registerAsyncFunction('may_fail', (args) async {
        await Future.delayed(const Duration(milliseconds: 5));
        if (args.isNotEmpty && args[0] == true) {
          throw Exception('Forced error');
        }
        return 'ok';
      });

      final source = '''
        widget RecoveryTest {
          state result = "pending";

          build {
            Column {
              Text(result)
              Button("Safe", onPressed: async fn() {
                try {
                  result = await may_fail(false);
                } catch (e) {
                  result = "error";
                }
              })
            }
          }
        }
      ''';

      final runtime = FluxRuntime(source);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'RecoveryTest', runtime: runtime)));

      await tester.tap(find.text('Safe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('ok'), findsOneWidget);
    });
  });

  group('Nested Await', () {
    testWidgets('await inside conditional branch', (WidgetTester tester) async {
      FluxBindings.registerAsyncFunction('fetch_data', (args) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return {'success': true, 'value': 42};
      });

      final source = '''
        widget ConditionalAwaitTest {
          state output = 0;

          build {
            Column {
              Text(toString(output))
              Button("Fetch", onPressed: async fn() {
                var data = await fetch_data();
                if (data["success"] == true) {
                  output = data["value"];
                } else {
                  output = -1;
                }
              })
            }
          }
        }
      ''';

      final runtime = FluxRuntime(source);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'ConditionalAwaitTest', runtime: runtime)));

      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.text('Fetch'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('multiple state updates in single async function', (WidgetTester tester) async {
      FluxBindings.registerAsyncFunction('step_delay', (args) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return args[0];
      });

      final source = '''
        widget MultiStateTest {
          state step = 0;
          state message = "";

          build {
            Column {
              Text(toString(step))
              Text(message)
              Button("Process", onPressed: async fn() {
                step = 1;
                message = await step_delay("loading");
                step = 2;
                message = await step_delay("processing");
                step = 3;
                message = await step_delay("done");
              })
            }
          }
        }
      ''';

      final runtime = FluxRuntime(source);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'MultiStateTest', runtime: runtime)));

      expect(find.text('0'), findsOneWidget);
      expect(find.text(''), findsOneWidget);

      await tester.tap(find.text('Process'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('done'), findsOneWidget);
    });
  });

  group('Edge Cases', () {
    testWidgets('await with null result', (WidgetTester tester) async {
      FluxBindings.registerAsyncFunction('return_null', (args) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return null;
      });

      final source = '''
        widget NullAwaitTest {
          state value = "initial";

          build {
            Column {
              Text(value)
              Button("Nullify", onPressed: async fn() {
                var result = await return_null();
                if (result == null) {
                  value = "got_null";
                } else {
                  value = "got_value";
                }
              })
            }
          }
        }
      ''';

      final runtime = FluxRuntime(source);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'NullAwaitTest', runtime: runtime)));

      await tester.tap(find.text('Nullify'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('got_null'), findsOneWidget);
    });

    testWidgets('await returning complex nested data', (WidgetTester tester) async {
      FluxBindings.registerAsyncFunction('get_nested', (args) async {
        await Future.delayed(const Duration(milliseconds: 5));
        return {
          'user': {
            'name': 'Alice',
            'scores': [100, 95, 88]
          }
        };
      });

      final source = '''
        widget NestedDataTest {
          state userName = "";

          build {
            Column {
              Text(userName)
              Button("Load", onPressed: async fn() {
                var data = await get_nested();
                userName = data["user"]["name"];
              })
            }
          }
        }
      ''';

      final runtime = FluxRuntime(source);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'NestedDataTest', runtime: runtime)));

      await tester.tap(find.text('Load'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
    });
  });

  group('Advanced Async Scenarios', () {
    testWidgets('async timeout simulation', (WidgetTester tester) async {
      FluxBindings.registerAsyncFunction('delayed_msg', (args) async {
        final duration = args[0] as int;
        await Future.delayed(Duration(milliseconds: duration));
        return 'done';
      });

      final source = '''
        widget TimeoutTest {
          state status = "start";

          build {
            Column {
              Text(status)
              Button("Run", onPressed: async fn() {
                // Determine if we should wait long or short
                // Note: Flux doesn't have Future.timeout built-in yet, 
                // so we simulate checking "too long" via a racing pattern manually if needed.
                // Here we just verify long delays work correctly.
                status = "waiting";
                var res = await delayed_msg(50); 
                status = res;
              })
            }
          }
        }
      ''';

      final runtime = FluxRuntime(source);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'TimeoutTest', runtime: runtime)));

      await tester.tap(find.text('Run'));
      await tester.pump(); // Update to "waiting"
      expect(find.text('waiting'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 20)); // Not done yet
      expect(find.text('waiting'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100)); // Should be done
      await tester.pumpAndSettle();

      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('race condition on shared state', (WidgetTester tester) async {
      // SKIP: This test exposes a fundamental limitation in the current VM architecture.
      // Concurrent coroutines share the same _stack and _frames, causing state corruption.
      // Proper coroutine isolation requires significant architectural changes.
      // See async_await_plan.md for future improvements.
      
      // Simulate two async operations modifying the same state
      FluxBindings.registerAsyncFunction('async_incr', (args) async {
        await Future.delayed(Duration(milliseconds: args[0] as int));
        return 1;
      });

      final source = '''
        widget RaceTest {
          state counter = 0;

          build {
            Column {
              Text(toString(counter))
              // Button A takes 50ms to add 1
              Button("A", onPressed: async fn() {
                var v = await async_incr(50);
                counter = counter + v;
              })
              // Button B takes 10ms to add 1
              Button("B", onPressed: async fn() {
                var v = await async_incr(10);
                counter = counter + v;
              })
            }
          }
        }
      ''';

      final runtime = FluxRuntime(source);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'RaceTest', runtime: runtime)));

      // Trigger both correctly
      // Trigger both correctly
      await tester.tap(find.text('A'));
      await tester.tap(find.text('B'));
      await tester.pump();

      // Wait for both to complete. The key verification is that we reach '2' 
      // without crashing or losing updates (race condition check).
      await tester.pump(const Duration(milliseconds: 100)); 
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('error re-throwing', (WidgetTester tester) async {
      FluxBindings.registerAsyncFunction('fail_async', (args) async {
        throw Exception('Original Error');
      });

      final source = '''
        widget RethrowTest {
          state error = "none";

          build {
            Column {
              Text(error)
              Button("Throw", onPressed: async fn() {
                try {
                  try {
                    await fail_async();
                  } catch (e) {
                    // Rethrow implicitly or handle
                    // Since Flux doesn't have 'throw e' yet, we simulate nested handling
                    error = "caught_inner";
                    // In a real rethrow scenario, we would need 'throw' support
                  }
                } catch (e2) {
                  error = "caught_outer";
                }
              })
            }
          }
        }
      ''';

      final runtime = FluxRuntime(source);
      await tester.pumpWidget(MaterialApp(home: FluxWidget(widgetName: 'RethrowTest', runtime: runtime)));

      await tester.tap(find.text('Throw'));
      await tester.pumpAndSettle();
      
      // Currently verifying inner catch works as we don't have rethrow syntax yet
      expect(find.text('caught_inner'), findsOneWidget);
    });
  });
}
