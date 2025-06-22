import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import 'emailverifygatepage.dart';
import 'face_enrollment_screen.dart';
import 'face_recognition_screen.dart';
import 'main_app_screen.dart';
import 'company_admin_main_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService  = AuthService();
  final _auth         = FirebaseAuth.instance;

  bool  _isLoading    = false;
  bool  _showPassword = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _isLoading = true; _error = null; });
    final email = _emailCtrl.text.trim();
    final pwd   = _passwordCtrl.text.trim();

    try {
      await _authService.signIn(email, pwd);
      final user = _auth.currentUser!;
      await user.reload();

      if (!user.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EmailVerifyGatePage(
              onVerified: () {
                Navigator.pop(context);
                _continueAfterSignIn(user, email, pwd);
              },
            ),
          ),
        );
        return;
      }

      await _continueAfterSignIn(user, email, pwd);

    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final cred = await _authService.signInWithGoogle();
      final user = cred.user!;
      final uid  = user.uid;

      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snapshot = await docRef.get();
      if (!snapshot.exists) throw 'Profile not found';

      final data = snapshot.data()!;
      final role = data['role'] as String? ?? 'driver';
      final emb  = (data['faceEmbedding'] as List<dynamic>?) ?? [];

      if (role == 'company_admin') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CompanyAdminMainScreen()),
              (_) => false,
        );
      } else {
        final next = emb.isNotEmpty
            ? const FaceRecognitionPage()
            : FaceEnrollmentPage(
          email:       user.email ?? '',
          password:    '',
          displayName: data['displayName'] as String? ?? '',
          onEnrollmentComplete: (newEmb, e, p, n) async {
            await docRef.update({'faceEmbedding': newEmb});
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainAppScreen()),
            );
          },
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => next),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Google sign-in failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Color(0xFF4776E6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text('DriveSense',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold
                  )),
              const SizedBox(height: 30),

              Flexible(
                fit: FlexFit.loose,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Text('Welcome Back',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold
                            )),
                        const SizedBox(height: 8),
                        const Text(
                            "Let's get started by filling out the form below.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: Colors.black54)
                        ),
                        const SizedBox(height: 24),

                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            filled: true,
                            fillColor: const Color(0xFFF5F6FA),
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _passwordCtrl,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            filled: true,
                            fillColor: const Color(0xFFF5F6FA),
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(50),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off
                              ),
                              onPressed: () =>
                                  setState(() => _showPassword = !_showPassword),
                            ),
                          ),
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: Colors.red)),
                        ],
                        const SizedBox(height: 20),

                        // Log In
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Log In',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold
                                )),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage()
                            ),
                          ),
                          child: const Text('Forgot Password ?'),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Google sign-in
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _loginWithGoogle,
                          icon: Image.asset(
                              'assets/images/google-logo.png', width: 24, height: 24
                          ),
                          label: const Text('Continue with Google'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50)
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Sign up link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? ",
                                style: TextStyle(color: Colors.black54)
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignUpPage()
                                ),
                              ),
                              child: const Text('Sign Up here',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold
                                  )
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _continueAfterSignIn(User user, String email, String pwd) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) throw 'Profile not found';
    final data = doc.data()!;
    final role = data['role'] as String? ?? 'driver';
    final emb  = (data['faceEmbedding'] as List<dynamic>?) ?? [];

    if (role == 'company_admin') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CompanyAdminMainScreen()),
            (_) => false,
      );
    } else {
      if (emb.isEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FaceEnrollmentPage(
              email:       email,
              password:    pwd,
              displayName: data['displayName'] as String? ?? '',
              onEnrollmentComplete: (newEmb, e, p, n) async {
                await doc.reference.update({'faceEmbedding': newEmb});
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const MainAppScreen()),
                );
              },
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FaceRecognitionPage()),
        );
      }
    }
  }
}
