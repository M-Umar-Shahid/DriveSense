import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailVerifyGatePage extends StatefulWidget {
  final VoidCallback onVerified;
  const EmailVerifyGatePage({Key? key, required this.onVerified})
      : super(key: key);

  @override
  _EmailVerifyGatePageState createState() => _EmailVerifyGatePageState();
}

class _EmailVerifyGatePageState extends State<EmailVerifyGatePage> {
  final _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _sub;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();

    // Listen to any token change (this fires when you reload or when the user clicks the link)
    _sub = _auth.idTokenChanges().listen((user) async {
      if (user == null) return;
      await user.reload();
      if (user.emailVerified) {
        _sub?.cancel();
        widget.onVerified();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    final user = _auth.currentUser!;
    if (_sent) return;
    try {
      await user.sendEmailVerification();
      _sent = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent')),
      );
    } catch (e) {
      // Optionally show an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'A verification link has been sent to your email.\n'
                'Once you tap it, this screen will automatically continue—even if the app was in the background.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
