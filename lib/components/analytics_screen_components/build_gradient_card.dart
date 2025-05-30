import 'package:flutter/material.dart';

Widget _buildGradientCard({
  required IconData icon,
  required String label,
  required String value,
  required List<Color> gradient,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: gradient.last),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: gradient.last.withOpacity(0.7))),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: gradient.last.darken(0.2),
              )),
        ],
      ),
    ),
  );
}

extension ColorUtils on Color {
  Color darken([double amount = .1]) {
    final f = 1 - amount;
    return Color.fromARGB(
        alpha, (red * f).round(), (green * f).round(), (blue * f).round());
  }
}

