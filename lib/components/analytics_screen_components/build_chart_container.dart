import 'package:flutter/material.dart';

// chart_container.dart
class ChartContainer extends StatelessWidget {
  const ChartContainer({required this.child, Key? key}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 1.8,
        child: child,
      ),
    );
  }
}

