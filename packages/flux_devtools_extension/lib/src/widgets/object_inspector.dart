import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

/// Renders a value that might be a primitive or an object reference.
class ValueRenderer extends StatelessWidget {
  final dynamic value;

  const ValueRenderer({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value is Map && value['type'] == 'ref') {
      return ObjectRefWidget(
          handle: value['handle'], preview: value['preview']);
    } else if (value is Map && value['type'] == 'primitive') {
      return Text('${value['value']}',
          style: TextStyle(
            fontFamily: 'monospace',
            color: value['kind'] == 'String'
                ? Colors.orange.shade800
                : Colors.blue.shade800,
          ));
    }
    // Fallback for old/simple values
    return Text('$value', style: const TextStyle(fontFamily: 'monospace'));
  }
}

/// A clickable widget representing a complex object reference.
class ObjectRefWidget extends StatelessWidget {
  final int handle;
  final String preview;

  const ObjectRefWidget(
      {super.key, required this.handle, required this.preview});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (ctx) =>
            ObjectInspectorDialog(handle: handle, preview: preview),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Text(
          preview,
          style: const TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

/// Dialog that fetches and displays object details.
class ObjectInspectorDialog extends StatefulWidget {
  final int handle;
  final String preview;

  const ObjectInspectorDialog({
    super.key,
    required this.handle,
    required this.preview,
  });

  @override
  State<ObjectInspectorDialog> createState() => _ObjectInspectorDialogState();
}

class _ObjectInspectorDialogState extends State<ObjectInspectorDialog> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final response = await serviceManager.callServiceExtensionOnMainIsolate(
        'ext.flux.getObject',
        args: {'handle': '${widget.handle}'},
      );
      final json = response.json ?? {};
      if (mounted) {
        setState(() {
          _data = json['object'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Inspector: ${widget.preview}'),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _buildContent(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
          child: Text('Error: $_error',
              style: const TextStyle(color: Colors.red)));
    if (_data == null) return const Center(child: Text('No data found'));

    final kind = _data!['kind'];

    if (kind == 'List') {
      final elements = _data!['elements'] as List;
      return ListView.builder(
        itemCount: elements.length,
        itemBuilder: (ctx, i) {
          final el = elements[i];
          return ListTile(
            dense: true,
            title: Text('[${el['index']}]',
                style: const TextStyle(
                    color: Colors.grey, fontFamily: 'monospace')),
            trailing: ValueRenderer(value: el['value']),
          );
        },
      );
    } else if (kind == 'Map') {
      final entries = _data!['entries'] as List;
      return ListView.builder(
        itemCount: entries.length,
        itemBuilder: (ctx, i) {
          final entry = entries[i];
          return ListTile(
            dense: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueRenderer(value: entry['key']),
                const Text(': ', style: TextStyle(color: Colors.grey)),
              ],
            ),
            trailing: ValueRenderer(value: entry['value']),
          );
        },
      );
    } else if (kind == 'Instance') {
      final text = _data!['class'] ?? 'Instance';
      final fields = _data!['fields'] as Map<String, dynamic>;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Class: $text',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: fields.length,
              itemBuilder: (ctx, i) {
                final key = fields.keys.elementAt(i);
                final value = fields[key];
                return ListTile(
                  dense: true,
                  title:
                      Text(key, style: const TextStyle(color: Colors.purple)),
                  trailing: ValueRenderer(value: value),
                );
              },
            ),
          ),
        ],
      );
    }

    return Text('Unknown object kind: $kind\n${_data.toString()}');
  }
}
