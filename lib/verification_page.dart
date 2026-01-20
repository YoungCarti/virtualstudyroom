import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_fonts.dart';
import 'home_dashboard.dart';
import 'onboarding_flow_page.dart';
import 'widgets/gradient_background.dart';

class VerificationPage extends StatefulWidget {
  final String email;

  const VerificationPage({
    super.key,
    required this.email,
  });

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  bool _isVerified = false;
  Timer? _timer;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    // Start polling for verification status
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _checkEmailVerified());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
      if (user.emailVerified) {
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _isVerified = true;
          });
          // Small delay for user to see success
          await Future.delayed(const Duration(seconds: 1));
          
          // Check if onboarding is completed
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          final onboardingCompleted = userDoc.data()?['onboardingCompleted'] ?? false;
          
          if (mounted) {
            if (onboardingCompleted) {
              // Go to home if onboarding is already done
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeDashboardPage()),
                (route) => false,
              );
            } else {
              // Go to onboarding flow for new users
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const OnboardingFlowPage()),
                (route) => false,
              );
            }
          }
        }
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification link resent!')),
        );
        setState(() => _canResend = false);
        // Cooldown
        Future.delayed(const Duration(seconds: 30), () {
            if (mounted) setState(() => _canResend = true);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 32),
                Text(
                  'Verify your email',
                  style: AppFonts.clashGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'We have sent a verification link to:\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: AppFonts.clashGrotesk(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please click the link in your email to continue. We are checking automatically...',
                  textAlign: TextAlign.center,
                  style: AppFonts.clashGrotesk(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 48),

                if (_isVerified)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text('Verified! Redirecting...', style: TextStyle(color: Colors.white)),
                    ],
                  )
                else
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      onPressed: _canResend ? _resendVerificationEmail : null,
                      child: Text(
                        _canResend ? 'Resend Link' : 'Wait 30s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                TextButton(
                    onPressed: () {
                         FirebaseAuth.instance.signOut();
                         Navigator.of(context).pop(); // Go back to Register
                    }, 
                    child: const Text('Cancel / Change Email', style: TextStyle(color: Colors.white70))
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
