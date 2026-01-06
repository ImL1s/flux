import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'demos/language_view.dart';
import 'demos/ui_view.dart';
import 'demos/storage_view.dart';
import 'demos/device_view.dart';
import 'demos/ota_view.dart';

void main() {
  runApp(const ProviderScope(child: FluxShowcaseApp()));
}

class FluxShowcaseApp extends StatelessWidget {
  const FluxShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flux Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6200EE),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  final List<DemoItem> demos = const [
    DemoItem(
      title: 'Language',
      subtitle: 'Syntax & Performance benchmarks',
      icon: Icons.code,
      color: Colors.blue,
      destination: LanguageView(),
    ),
    DemoItem(
      title: 'UI Components',
      subtitle: 'Widgets, Layouts & Themes',
      icon: Icons.widgets,
      color: Colors.orange,
      destination: UIView(),
    ),
    DemoItem(
      title: 'Storage',
      subtitle: 'SharedPrefs, Hive, SecureStorage',
      icon: Icons.storage,
      color: Colors.green,
      destination: StorageView(),
    ),
    DemoItem(
      title: 'Device',
      subtitle: 'Camera & BLE Integration',
      icon: Icons.phonelink_setup,
      color: Colors.purple,
      destination: DeviceView(),
    ),
    DemoItem(
      title: 'OTA Updates',
      subtitle: 'Hot Reload & Patching',
      icon: Icons.system_update,
      color: Colors.red,
      destination: OTAView(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flux Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showAboutDialog(
              context: context,
              applicationName: 'Flux Gallery',
              applicationVersion: '1.0.0',
              children: [
                const Text('A showcase of the Flux scripting language capabilities on Flutter.'),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: demos.length,
          itemBuilder: (context, index) {
            final demo = demos[index];
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 20),
              child: Card(
                elevation: 8,
                shadowColor: demo.color.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => demo.destination),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [demo.color, demo.color.withValues(alpha: 0.7)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: demo.color.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(demo.icon, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                demo.title,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                demo.subtitle,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.blueGrey.shade600,
                                      height: 1.3,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: demo.color.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DemoItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget destination;

  const DemoItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.destination,
  });
}
