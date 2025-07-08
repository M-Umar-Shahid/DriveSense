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
  Timer? _timer;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      final u = _auth.currentUser;
      if (u == null) return;
      await u.reload();
      if (!mounted) return;
      if (u.emailVerified) {
        _timer?.cancel();
        widget.onVerified();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    final user = _auth.currentUser!;
    try {
      await user.sendEmailVerification();
      setState(() => _sent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending email: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A verification link has been sent to your email.\n'
                    'Once you tap it, this screen will automatically continue—even if the app was in the background.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _sent ? _sendVerificationEmail : _sendVerificationEmail,
                child: const Text('Resend verification email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
