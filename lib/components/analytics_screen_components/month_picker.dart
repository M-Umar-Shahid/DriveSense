import 'package:flutter/material.dart';

class MonthPicker extends StatelessWidget {
  final String month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const MonthPicker({
    Key? key,
    required this.month,
    required this.onPrev,
    required this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
        Text(month,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
      ],
    );
  }
}
