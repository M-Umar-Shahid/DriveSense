import 'package:drivesense/pages/dashboard.dart';
import 'package:drivesense/pages/login_signup.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:drivesense/pages/on_boarding_screen1.dart';
import 'package:drivesense/pages/login.dart';
import 'package:drivesense/pages/bottom_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateAfterDelay();
    });
  }

  Future<void> _navigateAfterDelay() async {
    await _loadAnimation();
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;

    // 🌟 Main Logic
    if (hasSeenOnboarding) {
      if (currentUser != null) {
        // Already signed in → Go to dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
      } else {
        // Not signed in → Go to login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginSignup()),
        );
      }
    } else {
      // Show onboarding
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen1()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FutureBuilder(
          future: _loadAnimation(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Lottie.asset(
                'assets/animations/splash_animation.json',
                width: 300.0,
                height: 300.0,
                repeat: false,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    "Failed to load animation!",
                    style: TextStyle(color: Colors.red, fontSize: 16.0),
                  );
                },
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }

  Future<void> _loadAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
