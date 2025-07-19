import 'package:flutter/material.dart';

class FilterDialog extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  const FilterDialog({
    required this.selected,
    required this.onSelected,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Filter Alerts'),
      children: ['All', 'Drowsy', 'Yawning', 'Distraction'].map((type) {
        return RadioListTile<String>(
          value: type,
          groupValue: selected,
          title: Text(type),
          onChanged: (value) {
            onSelected(value!);
            Navigator.pop(context);
          },
        );
      }).toList(),
    );
  }
}
