import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivesense/screens/dashboard_screen.dart';
import 'package:drivesense/screens/login_signup_screen.dart';
import 'package:drivesense/screens/on_boarding_screen1.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'company_admin_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigateAfterDelay());
  }

  Future<void> _navigateAfterDelay() async {
    await _loadAnimation();
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!hasSeenOnboarding) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen1()));
      return;
    }

    if (currentUser == null) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginSignupPage()));
      return;
    }

    // user is signed in → fetch their role
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final role = doc.data()?['role'] as String? ?? 'driver';

      if (role == 'company_admin') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const CompanyAdminDashboard()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const Dashboard()));
      }
    } catch (_) {
      // on error fallback to driver dashboard
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginSignupPage()));
    }
  }

  Future<void> _loadAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
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
                width: 300, height: 300, repeat: false,
                errorBuilder: (_, __, ___) => const Text(
                    "Failed to load animation!", style: TextStyle(color: Colors.red)),
              );
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
