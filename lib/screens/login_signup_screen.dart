import 'package:drivesense/screens/signup_screen.dart';
import 'package:flutter/material.dart';

import '../components/getting_started_screen_components/logo_display.dart';
import '../components/login_signup_screen_components/auth_option_button.dart';
import 'login_screen.dart';

class LoginSignupPage extends StatelessWidget {
  const LoginSignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF1976D2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 100),
              child: Center(
                child: LogoDisplay(assetPath: 'assets/images/logo.png', radius: 60),
              ),
            ),
            const SizedBox(height: 80),
            const Text('Hello!', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'Create your account or Login if you \nhave already your account',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const Spacer(),
            const Text("Let's get started!", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  AuthOptionButton(
                    label: 'Log In',
                    color: Colors.white,
                    textColor: Colors.blue,
                    filled: true,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                  ),
                  const SizedBox(height: 10),
                  AuthOptionButton(
                    label: 'Sign Up',
                    color: Colors.white,
                    textColor: Colors.blue,
                    filled: true,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
