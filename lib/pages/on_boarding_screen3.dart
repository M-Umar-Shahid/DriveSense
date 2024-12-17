import 'package:drivesense/animations/FadeInImage.dart';
import 'package:drivesense/components/CustomBackButton.dart';

import 'getting_started.dart';
import 'package:flutter/material.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

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
                child: CustomBackButton(onPressed: (){})
              ),

              // Illustration
              const Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: FadeInImageWidget(
                    imagePath: 'assets/images/onboarding3.png',
                  ),
                ),
              ),

              // Title
              const Text(
                'Keep Your Eyes on the Road',
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
                'We detect and notify you of distractions to ensure your focus',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 1),

              // Skip and Next Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip Button
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 16.0,
                      ),
                    ),
                  ),

                  // Next Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GettingStarted()),
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