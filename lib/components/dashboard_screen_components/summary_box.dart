import 'package:flutter/material.dart';

class SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  const SummaryBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(radius: 22, backgroundColor: iconColor.withOpacity(0.1), child: Icon(icon, color: iconColor)),
        SizedBox(height: 6),
        Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
