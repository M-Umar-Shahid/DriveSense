import 'package:flutter/material.dart';
import 'package:drivesense/screens/login_screen.dart';
import 'package:drivesense/screens/face_enrollment_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/company_service.dart';
import 'dashboard_screen.dart';
import 'face_recognition_screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool  _isCompanyAdmin        = false;
  bool  _openToWork            = false;
  bool  _isLoading             = false;
  bool  _showPassword          = false;
  bool  _showConfirmPassword   = false;
  String? _error;

  final _companyNameController    = TextEditingController();
  final _nameController           = TextEditingController();
  final _emailController          = TextEditingController();
  final _passwordController       = TextEditingController();
  final _confirmPasswordController= TextEditingController();

  final _authService    = AuthService();
  final _companyService = CompanyService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// This will be called once face enrollment completes successfully.
  Future<void> _completeRegistration(
      List<double> embedding,
      String email,
      String password,
      String displayName,
      ) async {
    try {
      // 1) Create the Auth user
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2) Update their display name in FirebaseAuth
      await cred.user?.updateDisplayName(displayName);
      await cred.user?.reload();

      final uid = cred.user!.uid;

      // 3) Build the data you’ll write to Firestore
      final userData = <String, dynamic>{
        'displayName': displayName,
        'email': email,
        'role': _isCompanyAdmin ? 'company_admin' : 'driver',
        'openToWork': _openToWork,
        'company': null,
      };

      // Only include embeddings for drivers
      if (!_isCompanyAdmin) {
        userData['faceEmbedding'] = embedding;
      }

      // 4) Persist the user profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      // 5) If this is a company-admin, also create their company record
      if (_isCompanyAdmin) {
        await _companyService.createCompany(
          companyId: uid,
          companyName: _companyNameController.text.trim(),
          email: email,
        );
      }

      // 6) Navigate into your app (or back to Login)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isCompanyAdmin
                ? 'Company account created! Please log in.'
                : 'Welcome, $displayName! Your face is now registered.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-up failed: ${e.message}')),
      );
    }
  }


  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // 1) Sign in with Google
      final cred = await _authService.signInWithGoogle();
      final user = cred.user!;
      final uid = user.uid;

      // 2) Check if Firestore profile already exists
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        // 3a) New user → create their profile as DRIVER
        await docRef.set({
          'displayName': user.displayName,
          'email': user.email,
          'role': 'driver',
          'openToWork': false,
          'company': null,
          // faceEmbedding left out for now
        });
        // 3b) Kick off face enrollment
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FaceEnrollmentPage(
              email: user.email!,
              password: '', // no password for Google
              displayName: user.displayName ?? '',
              onEnrollmentComplete: (newEmb, email, pwd, name) async {
                await docRef.update({'faceEmbedding': newEmb});
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
        // 4) Existing user → route based on faceEmbedding
        final data = snapshot.data()!;
        final emb = data['faceEmbedding'] as List<dynamic>?;
        final hasEmbedding = emb != null && emb.isNotEmpty;
        final nextPage = hasEmbedding
            ? FaceRecognitionPage()
            : FaceEnrollmentPage(
          email: user.email!,
          password: '',
          displayName: data['displayName'] as String? ?? '',
          onEnrollmentComplete: (newEmb, e, p, n) async {
            await docRef.update({'faceEmbedding': newEmb});
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Dashboard()),
            );
          },
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => nextPage),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Google sign-up failed: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signUp() {
    final name    = _nameController.text.trim();
    final email   = _emailController.text.trim();
    final pass    = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (name.isEmpty) {
      _showMessage('Please enter your name');
      return;
    }
    if (pass != confirm || pass.length < 6) {
      _showMessage('Passwords must match and be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);
    // 2) Hand off to FaceEnrollmentPage:
    try {
      if (_isCompanyAdmin) {
        // ─────── COMPANY ADMIN FLOW ───────
        // call your same registration method but with an empty embedding
        // since _completeRegistration will skip saving embeddings when role=company_admin
        _completeRegistration(
          [], // empty embedding
          email,
          pass,
          name,
        );
      } else {
        // ─────── DRIVER FLOW ───────
        // go to face enrollment, which will call _completeRegistration once done
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                FaceEnrollmentPage(
                  email: email,
                  password: pass,
                  displayName: name,
                  onEnrollmentComplete: _completeRegistration,
                ),
          ),
        );
      }
    }
    finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ▶ full-screen gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue, // swap for your brand
              Color(0xFF4776E6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // ▶ App title
              const Text(
                'DriveSense',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              // ▶ white rounded card
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
                          // ▶ headers
                          const Text(
                            'Get Started',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create a new account',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ▶ role selector
                          Row(
                            children: [
                              Radio<bool>(
                                fillColor: MaterialStateProperty.all(Colors.blue),
                                value: false,
                                groupValue: _isCompanyAdmin,
                                onChanged: (v) => setState(() => _isCompanyAdmin = v!),
                              ),
                              const Text('Driver'),
                              Radio<bool>(
                                fillColor: MaterialStateProperty.all(Colors.blue),
                                value: true,
                                groupValue: _isCompanyAdmin,
                                onChanged: (v) => setState(() => _isCompanyAdmin = v!),
                              ),
                              const Text('Company Admin'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ▶ company name if needed
                          if (_isCompanyAdmin) ...[
                            TextField(
                              controller: _companyNameController,
                              decoration: InputDecoration(
                                hintText: 'Company Name',
                                filled: true,
                                fillColor: const Color(0xFFF5F6FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(50),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 18, horizontal: 20),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ▶ name
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: 'Name',
                              filled: true,
                              fillColor: const Color(0xFFF5F6FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 20),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ▶ email
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Email',
                              filled: true,
                              fillColor: const Color(0xFFF5F6FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 20),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ▶ password
                          TextField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              filled: true,
                              fillColor: const Color(0xFFF5F6FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 20),
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
                          const SizedBox(height: 16),

                          // ▶ confirm password
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: !_showConfirmPassword,
                            decoration: InputDecoration(
                              hintText: 'Confirm Password',
                              filled: true,
                              fillColor: const Color(0xFFF5F6FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () => setState(() =>
                                _showConfirmPassword =
                                !_showConfirmPassword),
                              ),
                            ),
                          ),

                          // ▶ open-to-work
                          if (!_isCompanyAdmin) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  fillColor:
                                  MaterialStateProperty.all(Colors.blue),
                                  value: _openToWork,
                                  onChanged: (v) =>
                                      setState(() => _openToWork = v!),
                                ),
                                const Expanded(
                                  child: Text(
                                    'I am open to work (companies can view my stats)',
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // ▶ error message
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!,
                                style: const TextStyle(color: Colors.red)),
                          ],
                          const SizedBox(height: 20),

                          // ▶ Sign Up button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.blue, // accent
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 18),
                              ),
                              onPressed:
                              _isLoading ? null : () => _signUp(),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2),
                              )
                                  : const Text('Sign Up',
                                  style: TextStyle(
                                    color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ▶ Or sign up with
                          const Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Text('Or sign up with'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ▶ Continue with Google
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
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () => _signUpWithGoogle(),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ▶ already have account?
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                                style:
                                TextStyle(color: Colors.black54),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const LoginPage()),
                                ),
                                child: const Text(
                                  'Sign In here',
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
