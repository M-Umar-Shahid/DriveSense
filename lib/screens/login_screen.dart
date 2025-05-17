import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivesense/screens/face_recognition_screen.dart';
import 'package:drivesense/screens/signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
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
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService        = AuthService();

  bool  _isLoading    = false;
  bool  _showPassword = false;
  String? _error;

  Future<void> _login() async {
    setState(() { _isLoading = true; _error = null; });
    final email = _emailController.text.trim();
    final pwd   = _passwordController.text.trim();

    // simple email check
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() { _isLoading = false; _error = 'Invalid email'; });
      return;
    }

    try {
      await _authService.signIn(email, pwd);
      if (!mounted) return;
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      if (!doc.exists) throw 'Profile not found';
      final data = doc.data()!;
      final role = data['role'] as String? ?? 'driver';
      // --- routing logic unchanged ---
      if (role == 'company_admin') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const CompanyAdminDashboard()));
        return;
      }
      final emb = data['faceEmbedding'] as List<dynamic>?;
      if (emb == null || emb.isEmpty) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => FaceEnrollmentPage(
              email: email, password: pwd,
              displayName: data['displayName'] as String? ?? '',
              onEnrollmentComplete: (newEmb, e, p, n) async {
                await FirebaseFirestore.instance
                    .collection('users').doc(uid)
                    .update({'faceEmbedding': newEmb});
                if (!mounted) return;
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const Dashboard()));
              },
            )));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const FaceRecognitionPage()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      // repeat routing logic
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      if (!doc.exists) throw 'Profile not found';
      final data = doc.data()!;
      final role = data['role'] as String? ?? 'driver';

      if (role == 'company_admin') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const CompanyAdminDashboard()));
      } else {
        final emb = data['faceEmbedding'] as List<dynamic>?;
        final next = (emb != null && emb.isNotEmpty)
            ? const FaceRecognitionPage()
            : FaceEnrollmentPage(
          email: FirebaseAuth.instance.currentUser!.email!,
          password: '',
          displayName: data['displayName'] as String? ?? '',
          onEnrollmentComplete: (newEmb, e, p, n) async {
            await FirebaseFirestore.instance
                .collection('users').doc(uid)
                .update({'faceEmbedding': newEmb});
            if (!mounted) return;
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const Dashboard()));
          },
        );
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => next));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Google sign‐in failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1️⃣ full‐screen gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue, // ← swap these for your brand
              Color(0xFF4776E6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // 2️⃣ App title
              const Text(
                'DriveSense',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              // 3️⃣ white rounded card
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
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
                          // 4️⃣ headers
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Let's get started by filling out the form below.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 5️⃣ email field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              filled: true,
                              fillColor: const Color(0xFFF5F6FA),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 6️⃣ password field
                          TextField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              filled: true,
                              fillColor: const Color(0xFFF5F6FA),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 20),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(
                                        () => _showPassword = !_showPassword),
                              ),
                            ),
                          ),

                          // 7️⃣ error text
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(color: Colors.red)),
                          ],

                          const SizedBox(height: 20),

                          // 8️⃣ Log In button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.blue, // your accent
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding:
                                const EdgeInsets.symmetric(vertical: 18),
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                                  : const Text('Log In',
                                  style: TextStyle(
                                    color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 9️⃣ Forgot password
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const ForgotPasswordPage()),
                            ),
                            child: const Text('Forgot Password ?'),
                          ),

                          const SizedBox(height: 16),

                          // 🔟 Or sign up with
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                                child: const Text('Or sign up with'),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ⓫ Continue with Google
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: Image.asset(
                                'assets/images/google-logo.png',
                                width: 24,
                                height: 24,
                              ),
                              label: const Text('Continue with Google'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: const BorderSide(
                                    color: Color(0xFFE0E0E0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed:
                              _isLoading ? null : _loginWithGoogle,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ⓬ Sign up link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(color: Colors.black54),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const SignUpPage()),
                                ),
                                child: const Text(
                                  'Sign Up here',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}
