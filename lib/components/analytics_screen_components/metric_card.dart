import 'package:flutter/material.dart';

// metric_card.dart
class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
    Key? key,
  }) : super(key: key);

  final IconData icon;
  final String label, value;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 130,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: gradient.last.withOpacity(0.4), blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -10,
              right: -10,
              child: Icon(icon, size: 100, color: Colors.white.withOpacity(0.12)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
