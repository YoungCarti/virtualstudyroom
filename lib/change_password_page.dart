import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'widgets/gradient_background.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  // Controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  // Visibility State
  bool _isCurrentVisible = false;
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;

  // OTP State
  Timer? _timer;
  int _otpCountdown = 0;

  // Loading State
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startOtpTimer() {
    setState(() {
      _otpCountdown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown == 0) {
        timer.cancel();
        setState(() {});
      } else {
        setState(() {
          _otpCountdown--;
        });
      }
    });
    
    // Simulate sending OTP
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("OTP sent to your registered email"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleUpdatePassword() async {
    // Basic Validation
    if (_currentPasswordController.text.length < 6) {
      _showError("Current password must be at least 6 characters");
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showError("New password must be at least 6 characters");
      return;
    }
    // Complexity check
    final complexityRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!$@%]).+$');
    if (!complexityRegex.hasMatch(_newPasswordController.text)) {
      _showError("New password must contain letters, numbers, and special characters (!\$@%)");
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError("Passwords do not match");
      return;
    }
    if (_otpController.text.length != 6) {
      _showError("Please enter a valid 6-digit OTP");
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ocean Sunset Palette
    final Color topColor = const Color(0xFF0A1929); // Deep Navy
    final Color bottomColor = const Color(0xFF122A46); // Midnight Blue

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, bottomColor],
              ),
            ),
          ),

          // 2. Ambient Glow Orbs (Optimized)
           Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2196F3).withValues(alpha: 0.25), // Electric Blue
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Back Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _GlassBackButton(onTap: () => Navigator.of(context).pop()),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title & Instructions
                  const Text(
                    "Change Password",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'ClashGrotesk',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Your password must be at least 6 characters and should include a combination of numbers, letters and special characters (!\$@%).",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form Fields
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PasswordInput(
                          label: "Current Password",
                          controller: _currentPasswordController,
                          isVisible: _isCurrentVisible,
                          onToggleVisibility: () => setState(() => _isCurrentVisible = !_isCurrentVisible),
                          placeholder: "Test1234",
                        ),
                        const SizedBox(height: 20),
                        _PasswordInput(
                          label: "New Password",
                          controller: _newPasswordController,
                          isVisible: _isNewVisible,
                          onToggleVisibility: () => setState(() => _isNewVisible = !_isNewVisible),
                          placeholder: "Tset4321",
                        ),
                        const SizedBox(height: 20),
                        _PasswordInput(
                          label: "Confirm new password",
                          controller: _confirmPasswordController,
                          isVisible: _isConfirmVisible,
                          onToggleVisibility: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                          placeholder: "Tset4321",
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Forget Password Link
                        GestureDetector(
                          onTap: () {
                            // Handle forgot password
                          },
                          child: const Text(
                            "Forget Password?",
                            style: TextStyle(
                              color: Color(0xFF4ECDC4), // Mint Green
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // OTP Section
                        Text(
                          "Enter OTP",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 2,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: "041623",
                                    hintStyle: TextStyle(color: Colors.white24, letterSpacing: 2),
                                    border: InputBorder.none,
                                    counterText: "",
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _otpCountdown > 0 ? null : _startOtpTimer,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: Colors.white30,
                                ),
                                child: Text(
                                  _otpCountdown > 0 ? "Resend in ${_otpCountdown}s" : "Get OTP",
                                  style: TextStyle(
                                    fontSize: 14, 
                                    fontWeight: FontWeight.w500,
                                    color: _otpCountdown > 0 ? Colors.white70 : const Color(0xFF2196F3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Update Button
                        _UpdatePasswordButton(
                          onTap: _isLoading ? null : _handleUpdatePassword,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _GlassBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: const Icon(
          LucideIcons.chevronLeft,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _PasswordInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final String placeholder;

  const _PasswordInput({
    required this.label,
    required this.controller,
    required this.isVisible,
    required this.onToggleVisibility,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: !isVisible,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: const Color(0xFF2196F3), // Electric Blue
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: GestureDetector(
                onTap: onToggleVisibility,
                child: Icon(
                  isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpdatePasswordButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const _UpdatePasswordButton({
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: onTap == null 
              ? Colors.white.withValues(alpha: 0.05) 
              : const Color(0xFF2196F3).withValues(alpha: 0.8), // Electric Blue
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  "Update Password",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: onTap == null ? 0.5 : 1.0),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
