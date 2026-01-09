import 'dart:async';
import 'package:flutter/material.dart';
import 'package:devtools_extensions/devtools_extensions.dart';

class MemoryPane extends StatefulWidget {
  const MemoryPane({super.key});

  @override
  State<MemoryPane> createState() => _MemoryPaneState();
}

class _MemoryPaneState extends State<MemoryPane> {
  Timer? _timer;
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _fetchStats());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchStats() async {
    try {
      final response = await serviceManager
          .callServiceExtensionOnMainIsolate('ext.flux.getMemoryStats');
      if (mounted) {
        setState(() {
          _stats = response.json?['stats'] ?? {};
          _loading = false;
        });
      }
    } catch (e) {
      // Ignore errors if extension not registered yet
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Flux VM Memory',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _buildStatCard('Alive Instances',
              _stats['aliveInstances']?.toString() ?? '0', Icons.widgets),
          _buildStatCard('Alive Closures',
              _stats['aliveClosures']?.toString() ?? '0', Icons.functions),
          _buildStatCard('Alive Upvalues',
              _stats['aliveUpvalues']?.toString() ?? '0', Icons.link),
          _buildStatCard('Total Allocated',
              _stats['totalAllocated']?.toString() ?? '0', Icons.add_chart),
          const SizedBox(height: 24),
          const Text(
            'Note: "Alive" counts rely on GC finalizers and may reflect objects pending collection.',
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label),
        trailing: Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}
