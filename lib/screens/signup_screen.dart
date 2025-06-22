import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../services/company_service.dart';
import 'face_enrollment_screen.dart';
import 'face_recognition_screen.dart';
import 'login_screen.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool  _isCompanyAdmin      = false;
  bool  _openToWork          = false;
  bool  _isLoading           = false;
  bool  _showPassword        = false;
  bool  _showConfirmPassword = false;
  String? _error;

  final _companyNameCtrl     = TextEditingController();
  final _nameCtrl            = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  final _authService    = AuthService();
  final _companyService = CompanyService();
  final _auth           = FirebaseAuth.instance;

  /// Called once face-enrollment finishes (or immediately for admins).
  Future<void> _completeRegistration(
      List<double> embedding,
      String email,
      String password,
      String displayName,
      ) async {
    setState(() => _isLoading = true);
    try {
      // 1) Create FirebaseAuth user
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );

      // 2) Update displayName
      await cred.user!
          .updateDisplayName(displayName);
      await cred.user!.reload();

      final uid = cred.user!.uid;

      // 3) Build the new Firestore shape
      final userData = <String, dynamic>{
        'displayName':    displayName,
        'email':          email,
        'role':           _isCompanyAdmin ? 'company_admin' : 'driver',
        'openToWork':     _openToWork,
        'companyHistory': <String>[],
        'assignments':    <Map<String,dynamic>>[],
      };
      if (!_isCompanyAdmin) {
        // only drivers get face embeddings
        userData['faceEmbedding'] = embedding;
      }

      // 4) Write user doc
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      // 5) If admin, also create their company record
      if (_isCompanyAdmin) {
        await _companyService.createCompany(
          companyId:   uid,
          companyName: _companyNameCtrl.text.trim(),
          email:       email,
        );
      }

      // 6) Back to login
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            _isCompanyAdmin
                ? 'Company created – please log in.'
                : 'Welcome, $displayName! Your face is now registered.'
        )),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-up failed: ${e.message}')),
      );
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final cred = await _authService.signInWithGoogle();
      final user = cred.user!;
      final uid  = user.uid;

      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snapshot = await docRef.get();

      if (!snapshot.exists) {
        // brand new Google driver
        await docRef.set({
          'displayName':    user.displayName,
          'email':          user.email,
          'role':           'driver',
          'openToWork':     false,
          'photoURL':    user.photoURL,
          'companyHistory': <String>[],
          'assignments':    <Map<String,dynamic>>[],
        });
        // then do face enrollment
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => FaceEnrollmentPage(
              email: user.email!,
              password: '',
              displayName: user.displayName ?? '',
              onEnrollmentComplete: (emb, e, p, n) async {
                await docRef.update({'faceEmbedding': emb});
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
          ),
        );
      } else {
        // existing Google user → enroll or recognize
        final data = snapshot.data()!;
        final emb  = (data['faceEmbedding'] as List<dynamic>?) ?? [];
        final next = emb.isNotEmpty
            ? const FaceRecognitionPage()
            : FaceEnrollmentPage(
          email:       user.email!,
          password:    '',
          displayName: data['displayName'] as String? ?? '',
          onEnrollmentComplete: (emb, e, p, n) async {
            await docRef.update({'faceEmbedding': emb});
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => next),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-up failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _signUp() {
    final name    = _nameCtrl.text.trim();
    final email   = _emailCtrl.text.trim();
    final pass    = _passwordCtrl.text;
    final confirm = _confirmPasswordCtrl.text;

    if (name.isEmpty) {
      _showError('Please enter your name');
      return;
    }
    if (pass.length < 6 || pass != confirm) {
      _showError('Passwords must match and be at least 6 chars');
      return;
    }

    // For both admins and drivers, just complete registration.
    // Face enrollment will be triggered later on first login when appropriate.
    _completeRegistration([], email, pass, name);
  }


  void _showError(String msg) {
    setState(() { _error = msg; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
              const Text(
                'DriveSense',
                style: TextStyle(
                    color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 30),
              Flexible(
                fit: FlexFit.loose,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(24)
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const Text('Get Started',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 8),
                        const Text('Create a new account',
                            style: TextStyle(fontSize: 15, color: Colors.black54)
                        ),
                        const SizedBox(height: 24),

                        // Role switch
                        Row(
                          children: [
                            Radio<bool>(
                              value: false, groupValue: _isCompanyAdmin,
                              onChanged: (v) => setState(()=>_isCompanyAdmin=v!),
                            ),
                            const Text('Driver'),
                            Radio<bool>(
                              value: true, groupValue: _isCompanyAdmin,
                              onChanged: (v) => setState(()=>_isCompanyAdmin=v!),
                            ),
                            const Text('Company Admin'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Company name (admins)
                        if (_isCompanyAdmin)
                          TextField(
                            controller: _companyNameCtrl,
                            decoration: InputDecoration(
                              hintText: 'Company Name',
                              filled: true, fillColor: const Color(0xFFF5F6FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),
                        // Name, Email, Password, Confirm
                        for (final tuple in [
                          [_nameCtrl, 'Name', false],
                          [_emailCtrl, 'Email', false],
                          [_passwordCtrl, 'Password', true],
                          [_confirmPasswordCtrl, 'Confirm Password', true],
                        ])
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextField(
                              controller: tuple[0] as TextEditingController,
                              obscureText: tuple[2] as bool ? !_showPassword : false,
                              decoration: InputDecoration(
                                hintText: tuple[1] as String,
                                filled: true, fillColor: const Color(0xFFF5F6FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(50),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: (tuple[2] as bool)
                                    ? IconButton(
                                  icon: Icon(
                                      _showPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off
                                  ),
                                  onPressed: () => setState(()=>_showPassword = !_showPassword),
                                )
                                    : null,
                              ),
                            ),
                          ),

                        // Open-to-work (drivers only)
                        if (!_isCompanyAdmin)
                          Row(
                            children: [
                              Checkbox(
                                value: _openToWork,
                                onChanged: (v)=>setState(()=>_openToWork=v!),
                              ),
                              const Expanded(
                                child: Text('I am open to work'),
                              ),
                            ],
                          ),

                        const SizedBox(height: 20),
                        // Sign Up button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Sign Up',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold
                                )),
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Google
                        if (!_isCompanyAdmin)
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _signUpWithGoogle,
                            icon: Image.asset('assets/images/google-logo.png', width:24),
                            label: const Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFE0E0E0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                            ),
                          ),

                        const SizedBox(height: 18),
                        // Back to login
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? ",
                                style: TextStyle(color: Colors.black54)),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                              ),
                              child: const Text('Sign In here',
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold
                                  )),
                            ),
                          ],
                        ),
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
}
