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
  bool _isCompanyAdmin = false;
  bool _openToWork = false;
  bool _isLoading = false;
  final _companyNameController = TextEditingController();
  final _companyService = CompanyService();  // ← import and instantiate
  final _nameController            = TextEditingController();
  final _emailController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                const Text('Create your account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text('Sign Up',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.blueAccent),
                ),
                const SizedBox(height: 8),
                const Text('Enter the details below to create your account',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // --- Role selector ---
                Row(
                  children: [
                    Radio<bool>(
                      fillColor: MaterialStateProperty.resolveWith((states) => Colors.blueAccent),
                      value: false,
                      groupValue: _isCompanyAdmin,
                      onChanged: (v) => setState(() => _isCompanyAdmin = v!),
                    ),
                    const Text('Driver'),
                    Radio<bool>(
                      fillColor: MaterialStateProperty.resolveWith((states) => Colors.blueAccent),
                      value: true,
                      groupValue: _isCompanyAdmin,
                      onChanged: (v) => setState(() => _isCompanyAdmin = v!),
                    ),
                    const Text('Company Admin'),
                  ],
                ),

                // Conditionally show company-name input
                if (_isCompanyAdmin) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _companyNameController,
                    decoration: InputDecoration(
                      labelText: 'Company Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],


                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'At least 6 characters',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 30),

                // Only show “Open to work?” when registering as DRIVER
                if (!_isCompanyAdmin) ...[
                  Row(
                    children: [
                      Checkbox(
                        fillColor: MaterialStateProperty.resolveWith((states) => Colors.transparent),
                        value: _openToWork,
                        onChanged: (v) => setState(() => _openToWork = v!),
                        checkColor: Colors.blueAccent,
                      ),
                      const Expanded(
                        child: Text("I am open to work (companies can view my stats)"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Center(
                    child: Text('Sign Up',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: _signUpWithGoogle,
                    icon: Image.asset(
                      'assets/images/google-logo.png',
                      width: 24, height: 24,
                    ),
                    label: const Text('Sign Up with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),


                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account? ',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
                        child: const Text('Login',
                          style: TextStyle(fontSize: 16, color: Color(0xFF1976D2)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
