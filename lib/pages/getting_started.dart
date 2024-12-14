import 'package:drivesense/pages/login_signup.dart';
import 'package:flutter/material.dart';

class GettingStarted extends StatelessWidget {
  const GettingStarted({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFF1976D2), // Blue background color
        child: Stack(
          children: [
            // Centered Logo
            Align(
              alignment: Alignment.center,
              child: CircleAvatar(
                radius: 60.0,
                backgroundColor: Colors.white,
                child: Image.asset(
                  'assets/images/logo.png', // Replace with your logo image path
                  fit: BoxFit.contain,
                  width: 50.0,
                  height: 50.0,
                ),
              ),
            ),

            // Get Started Button
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginSignup()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 60.0, vertical: 12.0),
                  ),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
