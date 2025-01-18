import 'package:drivesense/pages/bottom_navigation.dart';
import 'package:drivesense/pages/forgot_password.dart';
import 'package:drivesense/pages/signup.dart';
import 'package:flutter/material.dart';

import 'dashboard.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 20.0),

                // Welcome Back Text
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10.0),

                // Log in Text
                const Text(
                  'Log in',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1976D2),
                  ),
                ),

                const SizedBox(height: 8.0),

                // Subtitle
                const Text(
                  'Enter the details below to log in to your account',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 30.0),

                // Email TextField
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Name or Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    hintText: 'Enter User name or Email',
                  ),
                ),

                const SizedBox(height: 20.0),

                // Password TextField
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    hintText: 'Enter password',
                  ),
                ),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Forgot Password',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30.0),

                // Login Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BottomNavigation()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20.0),

                // Or Login With
                const Center(
                  child: Text(
                    'Or Login With',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                  ),
                ),

                const SizedBox(height: 20.0),

                // Social Media Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: SizedBox(
                        width: 40.0,
                        height: 40.0,
                        child: Image.asset('assets/images/google-logo.png'),
                      ),
                      iconSize: 40.0,
                    ),
                    const SizedBox(width: 20.0),
                    IconButton(
                      onPressed: () {},
                      icon: SizedBox(
                        width: 40.0,
                        height: 40.0,
                        child: Image.asset('assets/images/twitter-logo.png'),
                      ),
                      iconSize: 40.0,
                    ),
                    const SizedBox(width: 20.0),
                    IconButton(
                      onPressed: () {},
                      icon: SizedBox(
                        width: 40.0,
                        height: 40.0,
                        child: Image.asset('assets/images/instagram-logo.png'),
                      ),
                      iconSize: 40.0,
                    ),
                  ],
                ),

                const SizedBox(height: 20.0),

                // Sign Up Prompt
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SignUpPage()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
