import 'package:flutter/material.dart';

class ConsolePane extends StatefulWidget {
  final bool enabled;
  final Future<String> Function(String) onEvaluate;

  const ConsolePane({
    super.key,
    required this.enabled,
    required this.onEvaluate,
  });

  @override
  State<ConsolePane> createState() => _ConsolePaneState();
}

class _ConsolePaneState extends State<ConsolePane> {
  final List<ConsoleEntry> _entries = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  void _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _entries.add(ConsoleEntry(text: text, type: EntryType.input));
      _controller.clear();
    });

    // Evaluate
    try {
      final result = await widget.onEvaluate(text);
      if (mounted) {
        setState(() {
          _entries.add(ConsoleEntry(text: result, type: EntryType.output));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _entries.add(ConsoleEntry(text: 'Error: $e', type: EntryType.error));
        });
        _scrollToBottom();
      }
    }

    // Keep focus
    _focusNode.requestFocus();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade100,
          width: double.infinity,
          child: Row(
            children: [
              const Text('Console',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.block, size: 16),
                onPressed: () => setState(() => _entries.clear()),
                tooltip: 'Clear Console',
              ),
            ],
          ),
        ),
        // Output Area
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _entries.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              return _ConsoleRow(entry: _entries[index]);
            },
          ),
        ),
        const Divider(height: 1),
        // Input Area
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              const Icon(Icons.chevron_right, color: Colors.blue),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  decoration: const InputDecoration(
                    hintText: 'Evaluate expression...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.all(8),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum EntryType { input, output, error }

class ConsoleEntry {
  final String text;
  final EntryType type;

  ConsoleEntry({required this.text, required this.type});
}

class _ConsoleRow extends StatelessWidget {
  final ConsoleEntry entry;

  const _ConsoleRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData? icon;

    switch (entry.type) {
      case EntryType.input:
        color = Colors.grey;
        icon = Icons.chevron_right;
        break;
      case EntryType.output:
        color = Colors.black;
        break;
      case EntryType.error:
        color = Colors.red;
        icon = Icons.error_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Icon(icon, size: 14, color: color)
          else
            const SizedBox(width: 14),
          const SizedBox(width: 4),
          Expanded(
            child: SelectableText(
              entry.text,
              style: TextStyle(
                color: color,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
