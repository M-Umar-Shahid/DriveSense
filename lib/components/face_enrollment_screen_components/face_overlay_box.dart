import 'package:flutter/material.dart';

class FaceOverlayBox extends StatelessWidget {
  const FaceOverlayBox({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white70, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
