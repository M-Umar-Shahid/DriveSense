import 'package:flutter/material.dart';

class CaptureButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onCapture;
  const CaptureButton({
    required this.isProcessing,
    required this.onCapture,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return isProcessing
        ? const Center(child: CircularProgressIndicator())
        : Center(
      child: ElevatedButton(
        onPressed: onCapture,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text('Capture Face'),
        ),
      ),
    );
  }
}
