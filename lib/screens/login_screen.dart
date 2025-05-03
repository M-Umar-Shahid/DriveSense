import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivesense/screens/face_recognition_screen.dart';
import 'package:drivesense/screens/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../components/edit_profile_screen_components/custom_password_file.dart';
import '../components/edit_profile_screen_components/custom_text_field.dart';
import '../components/edit_profile_screen_components/primary_button.dart';
import '../components/login_screen_components/social_login_buttons.dart';
import 'company_admin_dashboard_screen.dart';
import 'dashboard_screen.dart';
import 'face_enrollment_screen.dart';
import 'forgot_password_screen.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;


  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      // 1) Sign in
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;

      // 2) Load user profile
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) throw Exception("User profile not found");

      final data = doc.data()!;
      final role = data['role'] as String? ?? 'driver';

      // 3a) Company-admin → CompanyAdminDashboard
      if (role == 'company_admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompanyAdminDashboard()),
        );
        return;
      }

      // 3b) Driver → face-enroll if no embedding, otherwise go to Dashboard
      final emb = data['faceEmbedding'] as List<dynamic>?;
      final hasEmbedding = emb != null && emb.isNotEmpty;

      if (!hasEmbedding) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FaceEnrollmentPage(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              displayName: data['displayName'] as String? ?? '',
              onEnrollmentComplete: (newEmb, email, pwd, name) async {
                // store embedding
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'faceEmbedding': newEmb});
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Dashboard()),
                );
              },
            ),
          ),
        );
      } else {
        // already enrolled → go straight to main Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FaceRecognitionPage()),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();

      // After Google sign-in, pull the same routing logic as your email login:
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (!doc.exists) throw Exception("User profile not found");

      final data = doc.data()!;
      final role = data['role'] as String? ?? 'driver';

      if (role == 'company_admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompanyAdminDashboard()),
        );
      } else {
        final emb = data['faceEmbedding'] as List<dynamic>?;
        final hasEmbedding = emb != null && emb.isNotEmpty;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => hasEmbedding
                ? const FaceRecognitionPage()
                : FaceEnrollmentPage(
              email: FirebaseAuth.instance.currentUser!.email!,
              password: '', // not needed for Google users
              displayName: data['displayName'] as String? ?? '',
              onEnrollmentComplete: (newEmb, email, pwd, name) async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'faceEmbedding': newEmb});
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Dashboard()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Google sign-in failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome back!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Log in',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the details below to log in to your account',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                CustomTextField(controller: _emailController, label: 'Email'),
                const SizedBox(height: 20),
                CustomPasswordField(
                  controller: _passwordController,
                  label: 'Password',
                  obscureText: true,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordPage()),
                      );
                    },
                    child: const Text(
                      'Forgot Password',
                      style: TextStyle(color: Color(0xFF1976D2)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: PrimaryButton(
                    label: 'Login',
                    isLoading: _isLoading,
                    onPressed: _login,
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Or Login With',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
             Center(
                   child: IconButton(
                     onPressed: _loginWithGoogle,
                     icon: SizedBox(
                       width: 40, height: 40,
                       child: Image.asset('assets/images/google-logo.png'),
                 ),
             ),
         ),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignUpPage()),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(fontSize: 16, color: Color(0xFF1976D2)),
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
