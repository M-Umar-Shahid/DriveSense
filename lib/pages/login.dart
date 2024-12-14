import 'package:drivesense/pages/dashboard.dart';
import 'package:flutter/material.dart';

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
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                SizedBox(height: 20.0),

                // Welcome Back Text
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10.0),

                // Log in Text
                Text(
                  'Log in',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1976D2),
                  ),
                ),

                SizedBox(height: 8.0),

                // Subtitle
                Text(
                  'Enter the details below to log in to your account',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),

                SizedBox(height: 30.0),

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

                SizedBox(height: 20.0),

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
                    onPressed: () {},
                    child: Text(
                      'Forgot Password',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30.0),

                // Login Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1976D2),
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Center(
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

                SizedBox(height: 20.0),

                // Or Login With
                Center(
                  child: Text(
                    'Or Login With',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                  ),
                ),

                SizedBox(height: 20.0),

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
                    SizedBox(width: 20.0),
                    IconButton(
                      onPressed: () {},
                      icon: SizedBox(
                        width: 40.0,
                        height: 40.0,
                        child: Image.asset('assets/images/twitter-logo.png'),
                      ),
                      iconSize: 40.0,
                    ),
                    SizedBox(width: 20.0),
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

                SizedBox(height: 20.0),

                // Sign Up Prompt
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.grey,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
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
