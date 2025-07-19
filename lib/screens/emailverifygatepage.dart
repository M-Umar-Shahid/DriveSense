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
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _autoCheck());
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

  Future<void> _autoCheck() async {
    final u = _auth.currentUser;
    if (u == null) return;
    await u.reload();
    if (u.emailVerified) {
      _timer?.cancel();
      widget.onVerified();
    }
  }

  Future<void> _manualCheck() async {
    setState(() => _checking = true);
    final u = _auth.currentUser!;
    await u.reload();
    if (u.emailVerified) {
      widget.onVerified();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email still not verified.")),
      );
    }
    setState(() => _checking = false);
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
                    'Tap it, then come back here or use the button below.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Resend button
              ElevatedButton(
                onPressed: _sendVerificationEmail,
                child: Text(_sent ? 'Resend verification email' : 'Send verification email'),
              ),

              const SizedBox(height: 12),

              // I've verified button
              ElevatedButton(
                onPressed: _checking ? null : _manualCheck,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: _checking
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text("I've Verified"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
