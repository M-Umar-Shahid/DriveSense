import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:drivesense/pages/on_boarding_screen1.dart';

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
      Timer(const Duration(seconds: 4), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingScreen1()),
          );
        }
      });
    });
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
                repeat: false, // Play animation once
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

  // Mock future for animation load delay
  Future<void> _loadAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
