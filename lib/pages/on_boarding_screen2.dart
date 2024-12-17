import 'package:drivesense/animations/FadeInImage.dart';
import 'package:drivesense/components/CustomBackButton.dart';
import 'package:drivesense/components/CustomSkipButton.dart';
import 'package:drivesense/pages/getting_started.dart';
import 'package:drivesense/pages/on_boarding_screen1.dart';
import 'package:flutter/material.dart';
import 'on_boarding_screen3.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Back Button
              Align(
                alignment: Alignment.topLeft,
                child: Padding(padding: const EdgeInsetsDirectional.fromSTEB(0, 10, 0, 0),
                  child: CustomBackButton(onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OnboardingScreen1()),
                    );
                  },)
                ),
              ),

              // Illustration
              const Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: FadeInImageWidget(
                    imagePath: 'assets/images/onboarding2.png',
                  ),
                ),
              ),

              // Title
              const Text(
                'Stay Awake, Stay Safe',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8.0),

              // Subtitle
              Text(
                'Get instant alerts if signs of drowsiness are detected.',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              Spacer(flex: 1),

              // Skip and Next Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip Button
                  CustomSkipButton(onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const GettingStarted()),
                    );
                  },),

                  // Next Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OnboardingScreen3()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(16.0),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }
}