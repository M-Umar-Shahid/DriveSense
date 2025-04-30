import 'package:flutter/material.dart';

class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onGoogle;
  final VoidCallback onTwitter;
  final VoidCallback onInstagram;

  const SocialLoginButtons({
    required this.onGoogle,
    required this.onTwitter,
    required this.onInstagram,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onGoogle,
          icon: SizedBox(
            width: 40,
            height: 40,
            child: Image.asset('assets/images/google-logo.png'),
          ),
        ),
        SizedBox(width: 20),
        IconButton(
          onPressed: onTwitter,
          icon: SizedBox(
            width: 40,
            height: 40,
            child: Image.asset('assets/images/twitter-logo.png'),
          ),
        ),
        SizedBox(width: 20),
        IconButton(
          onPressed: onInstagram,
          icon: SizedBox(
            width: 40,
            height: 40,
            child: Image.asset('assets/images/instagram-logo.png'),
          ),
        ),
      ],
    );
  }
}
