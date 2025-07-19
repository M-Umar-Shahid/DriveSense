import 'package:flutter/material.dart';
import '../../services/onboarding_service.dart';
import '../components/getting_started_screen_components/get_started_button.dart';
import '../components/getting_started_screen_components/logo_display.dart';
import 'login_signup_screen.dart';

class GettingStartedPage extends StatelessWidget {
  const GettingStartedPage({super.key});
  @override
  Widget build(BuildContext context) {
    final _svc = OnboardingService();
    return Scaffold(
      body: Container(
        color: const Color(0xFF1976D2),
        child: Stack(
          children: [
            Align(alignment: Alignment.center, child: LogoDisplay(assetPath: 'assets/images/logo.png')),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GetStartedButton(
                  onPressed: () async {
                    await _svc.completeOnboarding();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginSignupPage()),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
