import 'package:flutter/material.dart';

class CustomProfileButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomProfileButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50, // Width as per design
      height: 50, // Height as per design
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Background color (#F5F5F5)
        borderRadius: BorderRadius.circular(25), // Radius: 25px for full circular effect
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000), // Shadow color (#000000) with transparency
            offset: Offset(0, 0), // Shadow position (X: 0, Y: 0)
            blurRadius: 10, // Blur: 10px
            spreadRadius: 0, // Spread: 0
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.person, // Back arrow icon
          color: Colors.blue, // Icon color
          size: 25, // Adjust icon size
        ),
        onPressed: onPressed, // Callback function
        splashColor: Colors.transparent, // Remove ripple effect
        highlightColor: Colors.transparent, // Remove highlight color
      ),
    );
  }
}
