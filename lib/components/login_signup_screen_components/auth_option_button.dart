import 'package:flutter/material.dart';

class AuthOptionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final Color color;
  final Color? textColor;

  const AuthOptionButton({
    required this.label,
    required this.onPressed,
    required this.color,
    this.filled = false,
    this.textColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = textColor ??
        (filled ? Colors.white : color);

    if (filled) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: effectiveTextColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: effectiveTextColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }
}
