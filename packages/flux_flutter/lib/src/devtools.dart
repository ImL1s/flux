// Flux DevTools - 開發工具支持
// 提供調試、狀態檢視和性能分析功能。

import 'package:flutter/material.dart';
import 'package:flux_vm/flux_vm.dart';

/// Flux 調試器配置
class FluxDebugConfig {
  /// 是否啟用調試模式
  static bool debugMode = true;
  
  /// 是否顯示 Widget 邊界
  static bool showWidgetBounds = false;
  
  /// 是否記錄編譯時間
  static bool logCompileTime = true;
  
  /// 是否記錄執行時間
  static bool logExecutionTime = true;
}

/// Flux VM 狀態檢視器
class FluxStateInspector extends StatelessWidget {
  final VM vm;
  
  const FluxStateInspector({super.key, required this.vm});
  
  @override
  Widget build(BuildContext context) {
    final state = vm.widgetState;
    final globals = vm.globals;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Flux State Inspector',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            const Text('Widget State:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (state.isEmpty)
              const Text('  (empty)', style: TextStyle(fontStyle: FontStyle.italic))
            else
              ...state.entries.map((e) => Text('  ${e.key}: ${e.value}')),
            const SizedBox(height: 8),
            const Text('Globals:', style: TextStyle(fontWeight: FontWeight.bold)),
            if (globals.isEmpty)
              const Text('  (empty)', style: TextStyle(fontStyle: FontStyle.italic))
            else
              ...globals.entries.take(10).map((e) => Text('  ${e.key}: ${e.value}')),
            if (globals.length > 10)
              Text('  ... and ${globals.length - 10} more'),
          ],
        ),
      ),
    );
  }
}

/// Flux 性能監視器
class FluxPerformanceMonitor {
  static final Stopwatch _compileWatch = Stopwatch();
  static final Stopwatch _executeWatch = Stopwatch();
  
  static Duration? lastCompileTime;
  static Duration? lastExecuteTime;
  
  /// 開始編譯計時
  static void startCompile() {
    _compileWatch.reset();
    _compileWatch.start();
  }
  
  /// 結束編譯計時
  static void endCompile() {
    _compileWatch.stop();
    lastCompileTime = _compileWatch.elapsed;
    if (FluxDebugConfig.logCompileTime) {
      debugPrint('[Flux Perf] Compile time: ${lastCompileTime!.inMicroseconds}μs');
    }
  }
  
  /// 開始執行計時
  static void startExecute() {
    _executeWatch.reset();
    _executeWatch.start();
  }
  
  /// 結束執行計時
  static void endExecute() {
    _executeWatch.stop();
    lastExecuteTime = _executeWatch.elapsed;
    if (FluxDebugConfig.logExecutionTime) {
      debugPrint('[Flux Perf] Execute time: ${lastExecuteTime!.inMicroseconds}μs');
    }
  }
  
  /// 獲取性能報告
  static String getReport() {
    return '''
Flux Performance Report
========================
Compile Time: ${lastCompileTime?.inMicroseconds ?? 'N/A'}μs
Execute Time: ${lastExecuteTime?.inMicroseconds ?? 'N/A'}μs
''';
  }
}

/// Flux 錯誤邊界 Widget
class FluxErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error)? errorBuilder;
  
  const FluxErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });
  
  @override
  State<FluxErrorBoundary> createState() => _FluxErrorBoundaryState();
}

class _FluxErrorBoundaryState extends State<FluxErrorBoundary> {
  Object? _error;
  
  @override
  void initState() {
    super.initState();
    // Error boundary using error zone
    FlutterError.onError = (details) {
      setState(() {
        _error = details.exception;
      });
    };
  }
  
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ?? _defaultErrorWidget();
    }
    return widget.child;
  }
  
  Widget _defaultErrorWidget() {
    return Material(
      color: Colors.red.shade100,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Flux Error',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('$_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _error = null),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flux 日誌記錄器
class FluxLogger {
  static final List<FluxLogEntry> _logs = [];
  static const int maxLogs = 100;
  
  static void log(String message, {FluxLogLevel level = FluxLogLevel.info}) {
    _logs.add(FluxLogEntry(
      message: message,
      level: level,
      timestamp: DateTime.now(),
    ));
    
    // Trim old logs
    if (_logs.length > maxLogs) {
      _logs.removeAt(0);
    }
    
    // Print to console in debug mode
    if (FluxDebugConfig.debugMode) {
      debugPrint('[Flux ${level.name.toUpperCase()}] $message');
    }
  }
  
  static List<FluxLogEntry> get logs => List.unmodifiable(_logs);
  
  static void clear() => _logs.clear();
}

/// 日誌條目
class FluxLogEntry {
  final String message;
  final FluxLogLevel level;
  final DateTime timestamp;
  
  const FluxLogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
  });
}

/// 日誌等級
enum FluxLogLevel { debug, info, warning, error }
