import 'package:flutter/material.dart';

class LogoDisplay extends StatelessWidget {
  final String assetPath;
  final double radius;
  const LogoDisplay({
    required this.assetPath,
    this.radius = 60.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: Image.asset(assetPath, fit: BoxFit.contain, width: radius * 0.8, height: radius * 0.8),
    );
  }
}
