import 'package:flutter/material.dart';

class AuthOptionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled;
  const AuthOptionButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF1976D2);
    if (filled) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );
    } else {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }
  }
}
