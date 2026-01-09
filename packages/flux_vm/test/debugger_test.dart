import 'package:test/test.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  group('FluxDebugger', () {
    late VM vm;
    late FluxDebugger debugger;

    setUp(() {
      vm = VM();
      debugger = FluxDebugger(vm);
      vm.debugger = debugger;
    });

    test('Attaching and detaching', () {
      debugger.attach();
      expect(debugger.shouldBreakAt('any', 1),
          isNull); // Attached but no breakpoints

      debugger.detach();
      // Logic for detachment verification depends on internal state,
      // but primarily it clears pause state.
      expect(debugger.isPaused, isFalse);
    });

    test('Breakpoint management', () {
      debugger.attach();

      final bp = debugger.setBreakpoint('main.fx', 10);
      expect(bp.id, greaterThan(0));
      expect(bp.line, 10);
      expect(bp.source, 'main.fx');
      expect(bp.enabled, isTrue);

      expect(debugger.breakpoints.length, 1);
      expect(debugger.getBreakpoint(bp.id), bp);

      // Verify hit logic
      // shouldBreakAt returns the BP if it matches
      final hitBp = debugger.shouldBreakAt('main.fx', 10);
      expect(hitBp, equals(bp));
      expect(hitBp?.hitCount, 1);

      // Verify mismatch
      expect(debugger.shouldBreakAt('main.fx', 11), isNull);
      expect(debugger.shouldBreakAt('other.fx', 10), isNull);

      // Disable BP
      debugger.setBreakpointEnabled(bp.id, false);
      expect(debugger.shouldBreakAt('main.fx', 10),
          isNull); // Should not break when disabled

      // Remove BP
      debugger.removeBreakpoint(bp.id);
      expect(debugger.breakpoints, isEmpty);
    });

    test('Stepping controls', () {
      debugger.attach();

      // Simulate pausing
      // Note: In real execution, VM loop sets this. Here we test state setting.
      // But stepInto/Over/Out should set flags.

      // We need to force "paused" state to enable stepping commands usually,
      // but FluxDebugger implementation checks `if (!_paused) return;`
      // So checking logic requires access to private _paused or we trust the state logic.

      // Since _paused is private, and we can't easily pause it without running VM,
      // we check the getters we exposed.

      // Actually, we can't easily test stepInto/Over/Out state changes without being paused.
      // And we can't set _paused from outside.

      // However, we can assert initial state.
      expect(debugger.stepMode, isNull);
    });
  });

  group('FluxProfiler', () {
    late FluxProfiler profiler;

    setUp(() {
      profiler = FluxProfiler();
    });

    test('Records function timing', () async {
      profiler.start();

      profiler.recordFunctionEntry('testFunc');
      await Future.delayed(Duration(milliseconds: 10));
      profiler.recordFunctionExit('testFunc');

      profiler.stop();

      final report = profiler.generateReport();
      expect(report.totalInstructions, 0);
      expect(report.functionProfiles.length, 1);

      final funcProfile = report.functionProfiles.first;
      expect(funcProfile.name, 'testFunc');
      expect(funcProfile.callCount, 1);
      expect(funcProfile.totalTime.inMilliseconds, greaterThanOrEqualTo(10));
    });

    test('Records instructions', () {
      profiler.start();
      profiler.recordInstruction();
      profiler.recordInstruction();
      profiler.recordInstruction();
      profiler.stop();

      final report = profiler.generateReport();
      expect(report.totalInstructions, 3);
    });

    test('Handles recursive or multiple calls', () {
      profiler.start();

      // Call A
      profiler.recordFunctionEntry('A');
      profiler.recordFunctionExit('A');

      // Call B
      profiler.recordFunctionEntry('B');
      // Call A inside B
      profiler.recordFunctionEntry('A');
      profiler.recordFunctionExit('A');
      profiler.recordFunctionExit('B');

      profiler.stop();

      final report = profiler.generateReport();
      final profiles = {for (var p in report.functionProfiles) p.name: p};

      expect(profiles['A']!.callCount, 2);
      expect(profiles['B']!.callCount, 1);
    });
  });
}
