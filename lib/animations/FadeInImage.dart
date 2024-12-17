import 'package:flutter/material.dart';

class FadeInImageWidget extends StatefulWidget {
  final String imagePath; // Accepts the image path as a parameter

  const FadeInImageWidget({
    super.key,
    required this.imagePath,
  });

  @override
  _FadeInImageWidgetState createState() => _FadeInImageWidgetState();
}

class _FadeInImageWidgetState extends State<FadeInImageWidget> {
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Trigger the fade-in effect after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _opacity = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 800), // Duration for fade-in effect
      curve: Curves.easeIn, // Smooth animation curve
      opacity: _opacity,
      child: Image.asset(
        widget.imagePath, // Use the passed image path
        fit: BoxFit.contain,
      ),
    );
  }
}
