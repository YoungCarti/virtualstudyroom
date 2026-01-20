import 'app_fonts.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'auth_service.dart';
import 'login_page.dart';
import 'home_dashboard.dart';
import 'widgets/gradient_background.dart';
import 'verification_page.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'student'; // Default role
  
  // Error messages
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _confirmPasswordError;
  String? _passwordError;
  String? _roleError;

  final _auth = AuthService.instance;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  bool _validate() {
    bool isValid = true;
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _confirmPasswordError = null;
      _passwordError = null;
      _roleError = null;
    });

    if (_firstNameController.text.trim().length < 2) {
      setState(() => _firstNameError = 'Please enter your first name');
      isValid = false;
    }

    if (_lastNameController.text.trim().length < 2) {
      setState(() => _lastNameError = 'Please enter your last name');
      isValid = false;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address');
      isValid = false;
    }

    // Validate role-based email restrictions
    final lowerEmail = email.toLowerCase();
    final isEduEmail = lowerEmail.endsWith('.edu') || lowerEmail.endsWith('.edu.my');
    
    if (_selectedRole == 'lecturer') {
      // Lecturers MUST use .edu emails
      if (!isEduEmail) {
        setState(() => _roleError = 'Lecturer registration requires a .edu email address');
        isValid = false;
      }
    } else if (_selectedRole == 'student') {
      // Students CANNOT use .edu emails
      if (isEduEmail) {
        setState(() => _roleError = 'Students must use a regular email (e.g., gmail.com)');
        isValid = false;
      }
    }


    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _confirmPasswordError = 'Passwords do not match');
      isValid = false;
    }

    final password = _passwordController.text;
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasDigitOrSymbol = password.contains(RegExp(r'[\d\W]'));

    if (password.length < 6 || !hasUpperCase || !hasLowerCase || !hasDigitOrSymbol) {
      setState(() => _passwordError = 'Min 6 chars, uppercase, lowercase, & number/symbol');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleRegister() async {
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {

      
      // 1. Create Account
      await _auth.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: _selectedRole, // Pass selected role
      );

      // 2. Send Verification Link
      final user = _auth.currentUser;
      await user?.sendEmailVerification();
      
      if (mounted) {
        // Navigate to Native Verification Page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerificationPage(
              email: _emailController.text.trim(),
            ),
          ),
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

  void _handleNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    IconButton(
                      onPressed: _handleNavigation,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Header
                    Text(
                      'Create Account',
                      style: AppFonts.clashGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Login Link
                    GestureDetector(
                      onTap: _handleNavigation,
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: AppFonts.clashGrotesk(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                          children: [
                            TextSpan(
                              text: 'Log In',
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
                    const SizedBox(height: 40),

                    // Form
                    // First Name & Last Name
                    Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            label: 'First Name',
                            controller: _firstNameController,
                            placeholder: 'Lois',
                            icon: Icons.person_outline_rounded,
                            errorText: _firstNameError,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInput(
                            label: 'Last Name',
                            controller: _lastNameController,
                            placeholder: 'Becket',
                            icon: Icons.person_outline_rounded,
                            errorText: _lastNameError,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Email
                    _buildInput(
                      label: 'Email',
                      controller: _emailController,
                      placeholder: 'Enter your email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 20),

                    // Role Selection
                    _buildRoleSelector(),
                    const SizedBox(height: 20),



                    // Password
                    _buildInput(
                      label: 'Password',
                      controller: _passwordController,
                      placeholder: 'Create a password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                      errorText: _passwordError,
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password
                    _buildInput(
                      label: 'Confirm Password',
                      controller: _confirmPasswordController,
                      placeholder: 'Re-enter password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: true,
                      obscureText: _obscureConfirmPassword,
                      onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      errorText: _confirmPasswordError,
                    ),
                    const SizedBox(height: 40),

                    // Register Button
                    GestureDetector(
                      onTap: _isLoading ? null : _handleRegister,
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
                                  'Create Account',
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
                    
                    // Terms
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'By creating an account, you agree to our Terms of Service and Privacy Policy',
                        textAlign: TextAlign.center,
                        style: AppFonts.clashGrotesk(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.5),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('I am a'),
        const SizedBox(height: 8),
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
                  color: _roleError != null
                      ? const Color(0xFFEF4444).withOpacity(0.6)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.school_outlined,
                    color: Colors.white.withOpacity(0.5),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1E1E2E),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        style: AppFonts.clashGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'student',
                            child: Text('Student'),
                          ),
                          DropdownMenuItem(
                            value: 'lecturer',
                            child: Text('Lecturer'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRole = value;
                              _roleError = null;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_roleError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _roleError!,
              style: AppFonts.clashGrotesk(
                fontSize: 12,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        // Info text for lecturer
        if (_selectedRole == 'lecturer')
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: const Color(0xFF22D3EE).withOpacity(0.8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Requires a valid .edu email address',
                    style: AppFonts.clashGrotesk(
                      fontSize: 12,
                      color: const Color(0xFF22D3EE).withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
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
                  prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5), size: 20),
                  suffixIcon: isPassword
                      ? GestureDetector(
                          onTap: onToggleVisibility,
                          child: Icon(
                            obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.white.withOpacity(0.5),
                            size: 20,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
}
