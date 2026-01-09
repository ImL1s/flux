import 'package:flutter/material.dart';

class CallStackPane extends StatelessWidget {
  final List<Map<String, dynamic>> stack;
  final int selectedFrameIndex;
  final Function(int) onFrameSelected;

  const CallStackPane({
    super.key,
    required this.stack,
    required this.selectedFrameIndex,
    required this.onFrameSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (stack.isEmpty) {
      return const Center(
        child: Text('No call stack available',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade100,
          width: double.infinity,
          child: const Text('Call Frames',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: stack.length,
            itemBuilder: (context, index) {
              final frame = stack[index];
              final isSelected = index == selectedFrameIndex;
              final script = frame['script'] ?? '?';
              final line = frame['line'] ?? '?';
              final func = frame['function'] ?? '?';

              return ListTile(
                title: Text('$func()'),
                subtitle: Text('$script:$line'),
                dense: true,
                selected: isSelected,
                leading: isSelected
                    ? const Icon(Icons.arrow_right_alt, color: Colors.blue)
                    : const SizedBox(width: 24),
                onTap: () => onFrameSelected(index),
              );
            },
          ),
        ),
      ],
    );
  }
}
