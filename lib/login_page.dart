import 'app_fonts.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth_service.dart';
import 'auth_page.dart';
import 'home_dashboard.dart';
import 'register_page.dart';
import 'widgets/gradient_background.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final credentials = await _auth.getSavedCredentials();
    if (credentials['email'] != null && credentials['password'] != null) {
      setState(() {
        _emailController.text = credentials['email']!;
        _passwordController.text = credentials['password']!;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- NEW: Reset Password Functionality with Matching UI ---
  void _showForgotPasswordSheet() {
    final resetEmailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 24,
          right: 24,
          top: 32,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A), // Dark background matching your theme
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reset Password',
              textAlign: TextAlign.center,
              style: AppFonts.clashGrotesk(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enter your email to receive a reset link.',
              textAlign: TextAlign.center,
              style: AppFonts.clashGrotesk(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 24),
            // Reusing your glassmorphism style input for consistency
            _buildInput(
              controller: resetEmailController,
              placeholder: 'Email Address',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () async {
                  final email = resetEmailController.text.trim();
                  if (email.isEmpty) return;
                  try {
                    await _auth.sendPasswordResetEmail(email);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Reset link sent to your email!"),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color(0xFF3B82F6),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFFEF4444),
                      ),
                    );
                  }
                },
                child: Text(
                  'Send Reset Link',
                  style: AppFonts.clashGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _validate() {
    bool isValid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      isValid = false;
    } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email');
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      isValid = false;
    } else if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleLogin() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (_rememberMe) {
        await _auth.saveCredentials(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await _auth.clearSavedCredentials();
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeDashboardPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocialLogin(
      Future<dynamic> Function() signInMethod) async {
    setState(() => _isLoading = true);
    try {
      final result = await signInMethod();
      if (result != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeDashboardPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Stack(
          children: [
            // Ambient Glow
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6).withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.school_rounded,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'StudyLink',
                          style: AppFonts.clashGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),

                    // Welcome Title
                    Text(
                      'Sign in to your\nAccount',
                      style: AppFonts.clashGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Sign Up Link
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: AppFonts.clashGrotesk(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          children: [
                            TextSpan(
                              text: 'Sign Up',
                              style: AppFonts.clashGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF22D3EE),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Form
                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _emailController,
                      placeholder: 'Enter your email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    _buildInput(
                      controller: _passwordController,
                      placeholder: 'Enter your password',
                      icon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      isPassword: true,
                      errorText: _passwordError,
                    ),
                    const SizedBox(height: 16),

                    // Remember Me & Forgot Password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () =>
                              setState(() => _rememberMe = !_rememberMe),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _rememberMe
                                      ? const Color(0xFF22D3EE)
                                      : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(6),
                                  border: _rememberMe
                                      ? null
                                      : Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                  gradient: _rememberMe
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF22D3EE),
                                            Color(0xFF8B5CF6)
                                          ],
                                        )
                                      : null,
                                ),
                                child: _rememberMe
                                    ? const Icon(Icons.check,
                                        size: 14, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remember me',
                                style: AppFonts.clashGrotesk(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _showForgotPasswordSheet,
                          child: Text(
                            'Forgot Password ?',
                            style: AppFonts.clashGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF22D3EE),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    GestureDetector(
                      onTap: _isLoading ? null : _handleLogin,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 56,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Log In',
                                  style: AppFonts.clashGrotesk(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Social Login Divider
                    Row(
                      children: [
                        Expanded(
                            child:
                                Divider(color: Colors.white.withOpacity(0.1))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Or login with',
                            style: AppFonts.clashGrotesk(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                        Expanded(
                            child:
                                Divider(color: Colors.white.withOpacity(0.1))),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Social Buttons
                    _buildSocialButton(
                      text: 'Continue with Google',
                      icon: FontAwesomeIcons.google,
                      onTap: () => _handleSocialLogin(_auth.signInWithGoogle),
                    ),
                    const SizedBox(height: 24),

                    // Terms
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'By signing up, you agree to the Terms of Service and Data Processing Agreement',
                        textAlign: TextAlign.center,
                        style: AppFonts.clashGrotesk(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppFonts.clashGrotesk(
        fontSize: 13,
        color: Colors.white.withOpacity(0.5),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool isPassword = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: errorText != null
                      ? const Color(0xFFEF4444).withOpacity(0.6)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                obscureText: obscureText,
                style: AppFonts.clashGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                cursorColor: const Color(0xFF22D3EE),
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: AppFonts.clashGrotesk(
                    color: Colors.white.withOpacity(0.4),
                  ),
                  prefixIcon: Icon(icon,
                      color: Colors.white.withOpacity(0.5), size: 20),
                  suffixIcon: isPassword
                      ? GestureDetector(
                          onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white.withOpacity(0.5),
                            size: 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText,
              style: AppFonts.clashGrotesk(
                fontSize: 12,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: AppFonts.clashGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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