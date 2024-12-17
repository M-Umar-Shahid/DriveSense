import 'package:flutter/material.dart';

class CustomSkipButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomSkipButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 57, // Width as per design
      height: 57, // Height as per design
      decoration: BoxDecoration(
        color: Colors.white, // Background color (#FFFFFF)
        shape: BoxShape.circle, // Makes it a perfect circle
        border: Border.all(
          color: const Color(0xFF3D77D8), // Border color (#3D77D8)
          width: 1, // Border width: 1px
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000), // Shadow color (#000000) with transparency
            offset: Offset(0, 0), // Shadow position (X: 0, Y: 0)
            blurRadius: 10, // Blur: 10px
            spreadRadius: 0, // Spread: 0
          ),
        ],
      ),
      child: Center(
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF3D77D8), // Text color (#3D77D8)
            padding: EdgeInsets.zero, // Removes padding around text
          ),
          child: const Text(
            'Skip',
            style: TextStyle(
              fontSize: 16, // Font size
              fontWeight: FontWeight.w500, // Medium weight
              color: Color(0xFF3D77D8), // Text color
            ),
          ),
        ),
      ),
    );
  }
}
