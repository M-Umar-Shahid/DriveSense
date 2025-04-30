import 'package:flutter/material.dart';

class VerifyButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onPressed;
  const VerifyButton({
    required this.isProcessing,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return isProcessing
        ? const Center(child: CircularProgressIndicator())
        : Center(
      child: ElevatedButton(
        onPressed: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text('Verify Face'),
        ),
      ),
    );
  }
}
