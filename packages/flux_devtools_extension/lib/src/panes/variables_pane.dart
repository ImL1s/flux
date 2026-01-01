import 'package:flutter/material.dart';
import '../widgets/object_inspector.dart';

class VariablesPane extends StatelessWidget {
  final Map<String, dynamic> locals;

  const VariablesPane({
    super.key,
    required this.locals,
  });

  @override
  Widget build(BuildContext context) {
    if (locals.isEmpty) {
      return const Center(
        child: Text('No variables', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      children: [
        Container(
           padding: const EdgeInsets.all(8),
           color: Colors.grey.shade100,
           width: double.infinity,
           child: const Text('Local Variables', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: locals.length,
            itemBuilder: (context, index) {
              final key = locals.keys.elementAt(index);
              final value = locals[key];
              
              return ListTile(
                title: Text(key, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ValueRenderer(value: value),
                  ),
                ),
                dense: true,
              );
            },
          ),
        ),
      ],
    );
  }
}
