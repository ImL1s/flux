import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flux_flutter/flux_flutter.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

// ============================================================================
// Providers
// ============================================================================

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8082',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));
  dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  return dio;
});

// Navigation Notifier
final currentPageProvider = NotifierProvider<CurrentPageNotifier, int>(CurrentPageNotifier.new);

class CurrentPageNotifier extends Notifier<int> {
  @override
  int build() => 0;
  
  void set(int index) => state = index;
}

// Storage Simulation Notifier
final storageProvider = NotifierProvider<StorageNotifier, Map<String, String>>(StorageNotifier.new);

class StorageNotifier extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => {};
  
  void save(String key, String value) {
    state = {...state, key: value};
  }
  
  void clear() => state = {};
}

// ============================================================================
// Main App
// ============================================================================

void main() {
  runApp(const ProviderScope(child: ShowcaseApp()));
}

class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flux Showcase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends ConsumerWidget {
  const MainScaffold({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);
    
    return Scaffold(
      body: IndexedStack(
        index: currentPage,
        children: const [
          ProductPageHost(),
          TodoPageHost(),
          SettingsPageHost(),
          DashboardPageHost(),
          PowerPageHost(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentPage,
        onDestinationSelected: (index) {
          ref.read(currentPageProvider.notifier).set(index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shopping_bag), label: '商品'),
          NavigationDestination(icon: Icon(Icons.checklist), label: '待辦'),
          NavigationDestination(icon: Icon(Icons.settings), label: '設定'),
          NavigationDestination(icon: Icon(Icons.dashboard), label: '儀表板'),
          NavigationDestination(icon: Icon(Icons.science), label: '實驗室'),
        ],
      ),
    );
  }
}

// ============================================================================
// Base Page Host (共用邏輯)
// ============================================================================

abstract class FluxPageHost extends ConsumerStatefulWidget {
  const FluxPageHost({super.key});
  
  String get scriptName;
  String get widgetName;
  String get pageTitle;
  IconData get pageIcon;
}

abstract class FluxPageHostState<T extends FluxPageHost> extends ConsumerState<T> {
  FluxRuntime? _runtime;
  String _status = '載入中...';
  bool _loading = true;
  int _reloadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadScript();
  }

  Future<void> _loadScript() async {
    setState(() {
      _loading = true;
      _status = '正在載入 ${widget.scriptName}...';
    });

    try {
      final scriptPath = await _findScriptPath(widget.scriptName);
      if (scriptPath == null) {
        throw Exception('找不到腳本: ${widget.scriptName}');
      }

      final script = await File(scriptPath).readAsString();
      final runtime = FluxRuntime(script, moduleName: widget.widgetName);
      
      // Register native functions
      _registerNativeFunctions(runtime);
      
      setState(() {
        _runtime = runtime;
        _status = '✅ 已載入';
        _loading = false;
        _reloadCount++;
      });
    } catch (e) {
      setState(() {
        _status = '❌ 錯誤: $e';
        _loading = false;
      });
    }
  }

  void _registerNativeFunctions(FluxRuntime runtime) {
    // showToast
    runtime.vm.globals['showToast'] = NativeFunction('showToast', 1, (args) {
      final message = args.isNotEmpty ? args[0].toString() : 'Toast';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
      return null;
    });

    // saveToStorage
    runtime.vm.globals['saveToStorage'] = NativeFunction('saveToStorage', 2, (args) {
      if (args.length >= 2) {
        final key = args[0].toString();
        final value = args[1].toString();
        ref.read(storageProvider.notifier).save(key, value);
        debugPrint('💾 Saved: $key = $value');
      }
      return null;
    });

    // loadFromStorage
    runtime.vm.globals['loadFromStorage'] = NativeFunction('loadFromStorage', 1, (args) {
      if (args.isNotEmpty) {
        final key = args[0].toString();
        final value = ref.read(storageProvider)[key];
        debugPrint('📖 Loaded: $key = $value');
        return value;
      }
      return null;
    });

    // fetchData (async simulation)
    runtime.vm.globals['fetchData'] = AsyncNativeFunction('fetchData', 0, (args) async {
      try {
        final dio = ref.read(dioProvider);
        final response = await dio.get('/api/dashboard');
        return response.data;
      } catch (e) {
        debugPrint('API Error: $e');
        return {'error': e.toString()};
      }
    });
  }

  Future<String?> _findScriptPath(String scriptName) async {
    final searchPaths = [
      'D:/OtherProject/mine/flux/examples/showcase_app/scripts/$scriptName',
      '../scripts/$scriptName',
      'scripts/$scriptName',
    ];

    for (final path in searchPaths) {
      final file = File(path);
      if (await file.exists()) {
        return file.absolute.path;
      }
    }

    // Walk up directory tree
    var current = Directory.current;
    for (int i = 0; i < 5; i++) {
      final testPath = p.join(current.path, 'scripts', scriptName);
      if (await File(testPath).exists()) {
        return testPath;
      }
      current = current.parent;
      if (current.path == current.parent.path) break;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(widget.pageIcon),
            const SizedBox(width: 8),
            Text(widget.pageTitle),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重新載入腳本',
            onPressed: _loading ? null : _loadScript,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _loading ? Colors.orange[100] : Colors.green[100],
            child: Text(_status, style: const TextStyle(fontSize: 12)),
          ),
          // Flux widget area
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _runtime != null
                    ? FluxWidget(
                        key: ValueKey(_reloadCount),
                        widgetName: widget.widgetName,
                        runtime: _runtime,
                      )
                    : Center(child: Text('無法載入 ${widget.scriptName}')),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Page Hosts
// ============================================================================

class ProductPageHost extends FluxPageHost {
  const ProductPageHost({super.key});
  
  @override
  String get scriptName => 'product_page.flux';
  @override
  String get widgetName => 'ProductPage';
  @override
  String get pageTitle => '電商產品';
  @override
  IconData get pageIcon => Icons.shopping_bag;
  
  @override
  ConsumerState<ProductPageHost> createState() => _ProductPageHostState();
}

class _ProductPageHostState extends FluxPageHostState<ProductPageHost> {}

class TodoPageHost extends FluxPageHost {
  const TodoPageHost({super.key});
  
  @override
  String get scriptName => 'todo_page.flux';
  @override
  String get widgetName => 'TodoPage';
  @override
  String get pageTitle => '待辦事項';
  @override
  IconData get pageIcon => Icons.checklist;
  
  @override
  ConsumerState<TodoPageHost> createState() => _TodoPageHostState();
}

class _TodoPageHostState extends FluxPageHostState<TodoPageHost> {}

class SettingsPageHost extends FluxPageHost {
  const SettingsPageHost({super.key});
  
  @override
  String get scriptName => 'settings_page.flux';
  @override
  String get widgetName => 'SettingsPage';
  @override
  String get pageTitle => '應用設定';
  @override
  IconData get pageIcon => Icons.settings;
  
  @override
  ConsumerState<SettingsPageHost> createState() => _SettingsPageHostState();
}

class _SettingsPageHostState extends FluxPageHostState<SettingsPageHost> {}

class DashboardPageHost extends FluxPageHost {
  const DashboardPageHost({super.key});
  
  @override
  String get scriptName => 'dashboard_page.flux';
  @override
  String get widgetName => 'DashboardPage';
  @override
  String get pageTitle => '數據儀表板';
  @override
  IconData get pageIcon => Icons.dashboard;
  
  @override
  ConsumerState<DashboardPageHost> createState() => _DashboardPageHostState();
}

class _DashboardPageHostState extends FluxPageHostState<DashboardPageHost> {}

class PowerPageHost extends FluxPageHost {
  const PowerPageHost({super.key});
  
  @override
  String get scriptName => 'power_page.flux';
  @override
  String get widgetName => 'PowerPage';
  @override
  String get pageTitle => 'Flux 實驗室';
  @override
  IconData get pageIcon => Icons.science;
  
  @override
  ConsumerState<PowerPageHost> createState() => _PowerPageHostState();
}

class _PowerPageHostState extends FluxPageHostState<PowerPageHost> {}
