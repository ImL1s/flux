import 'package:flutter/material.dart';
import 'package:devtools_extensions/devtools_extensions.dart';

class InspectorPane extends StatefulWidget {
  const InspectorPane({super.key});

  @override
  State<InspectorPane> createState() => _InspectorPaneState();
}

class _InspectorPaneState extends State<InspectorPane> {
  Map<String, dynamic>? _tree;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final response = await serviceManager
          .callServiceExtensionOnMainIsolate('ext.flux.getWidgetTree');
      if (mounted) {
        setState(() {
          _tree = response.json?['tree'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade100,
          child: Row(
            children: [
              const Icon(Icons.search, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Flux Widget Inspector',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 16),
                tooltip: 'Refresh Tree',
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _tree == null
                  ? const Center(child: Text('No widget tree available'))
                  : ListView(
                      padding: const EdgeInsets.all(8),
                      children: [_buildTreeNode(_tree!)],
                    ),
        ),
      ],
    );
  }

  Widget _buildTreeNode(Map<String, dynamic> node) {
    final name = node['name'] ?? 'Unknown';
    final children = node['children'] as List? ?? [];
    final args = node['args'] as Map? ?? {};

    return ExpansionTile(
      title: Text(name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      subtitle: args.isNotEmpty
          ? Text('Args: ${args.keys.join(", ")}',
              style: const TextStyle(fontSize: 10, color: Colors.grey))
          : null,
      leading: const Icon(Icons.layers, size: 18),
      initiallyExpanded: true,
      dense: true,
      children: children.map((c) {
        if (c is Map<String, dynamic>) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: _buildTreeNode(c),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(left: 32.0, bottom: 4.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(c.toString(),
                style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
        );
      }).toList(),
    );
  }
}
