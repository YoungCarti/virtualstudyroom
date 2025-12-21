import 'dart:ui';


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/gradient_background.dart';

class EditProfilePage extends StatefulWidget {
  final String? userDocId;
  const EditProfilePage({super.key, this.userDocId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _fullNameController = TextEditingController();
  final _campusController = TextEditingController();
  final _favGroupController = TextEditingController();
  final _bioController = TextEditingController();
  
  // State
  List<String> _interests = [];
  bool _loading = false;
  late final String _docId;
  final _users = FirebaseFirestore.instance.collection('users');
  bool _hasUnsavedChanges = false;
  String _role = 'student';      // student | lecturer
  String _program = 'BCS';       // BCS | BSE

  // Interest Colors Palette
  final List<Color> _tagColors = [
    const Color(0xFF7C3AED), // Purple
    const Color(0xFF0D9488), // Teal
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFDC2626), // Red
    const Color(0xFFEA580C), // Orange
    const Color(0xFFEC4899), // Pink
    const Color(0xFF10B981), // Green
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF06B6D4), // Cyan
  ];

  @override
  void initState() {
    super.initState();
    _docId = widget.userDocId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_docId.isNotEmpty) _loadProfile();
    
    // Listen for changes to set unsaved flag
    _fullNameController.addListener(_onFieldChanged);
    _campusController.addListener(_onFieldChanged);
    _favGroupController.addListener(_onFieldChanged);
    _bioController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final snap = await _users.doc(_docId).get();
      if (!snap.exists) return;
      final data = snap.data()!;
      setState(() {
        _fullNameController.text = data['fullName'] ?? data['name'] ?? '';
        _role = (data['role'] ?? 'student').toString().toLowerCase();
        _program = (data['program'] ?? 'BCS').toString().toUpperCase();
        _campusController.text = (data['campus'] ?? '').toString().isEmpty
            ? 'UNIMY'
            : data['campus'];
        _favGroupController.text = data['favGroup'] ?? '';
        _bioController.text = data['bio'] ?? '';
        
        if (data['interests'] != null) {
          _interests = List<String>.from(data['interests']);
        } else {
          // Default interests if none exist
          _interests = [
            "Machine Learning",
            "Web Development",
            "Data Science",
            "Cybersecurity",
            "Mobile Apps"
          ];
        }
        _hasUnsavedChanges = false; // Reset after load
      });
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _campusController.dispose();
    _favGroupController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _updatePhoto() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );
      
      if (image != null) {
        // In a real app, upload to Firebase Storage here and get URL
        // For now, we'll just show a snackbar as we don't have storage setup in this snippet
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo selected (Upload logic placeholder)')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _addInterest() {
    if (_interests.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 interests allowed')),
      );
      return;
    }

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Add Interest', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. AI, Music, Sports',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF22D3EE))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _interests.add(controller.text.trim());
                  _hasUnsavedChanges = true;
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Color(0xFF22D3EE))),
          ),
        ],
      ),
    );
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveProfile() async {
    if (_docId.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;
    if (_interests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one interest')),
      );
      return;
    }

    setState(() => _loading = true);

    final updateData = <String, dynamic>{
      'fullName': _fullNameController.text.trim(),
      'name': _fullNameController.text.trim(), // Legacy support
      'role': _role,
      'program': _program,
      'campus': _campusController.text.trim().isEmpty
          ? 'UNIMY'
          : _campusController.text.trim(),
      'favGroup': _favGroupController.text.trim(),
      'bio': _bioController.text.trim(),
      'interests': _interests,
    };

    try {
      await _users.doc(_docId).set(updateData, SetOptions(merge: true));

      // Update Auth Display Name
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.displayName != _fullNameController.text.trim()) {
        await user.updateDisplayName(_fullNameController.text.trim());
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A3E),
        title: const Text('Unsaved Changes', style: TextStyle(color: Colors.white)),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // 1. Background removed
            // Ambient Glow
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
                        const Color(0xFF7C3AED).withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                      radius: 0.8,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Column(
                children: [
                  // 2. Top Navigation Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _GlassIconButton(
                          icon: Icons.chevron_left,
                          onTap: () async {
                            if (await _onWillPop()) {
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                        ),
                        _GlassIconButton(
                          icon: Icons.check,
                          onTap: _loading ? () {} : _saveProfile,
                          isLoading: _loading,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            
                            // 3. Profile Photo Section
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        width: 3,
                                      ),
                                      image: const DecorationImage(
                                        image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: _updatePhoto,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF22D3EE).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.camera_alt, color: Color(0xFF22D3EE), size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            "Update Photo",
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF22D3EE),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // 4. Form Fields
                            _buildTextField(
                              controller: _fullNameController,
                              label: "Full name",
                              icon: Icons.person_outline,
                              iconColor: const Color(0xFF22D3EE),
                              validator: (v) => (v == null || v.length < 2) ? 'Min 2 characters required' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            // Role toggle
                            _buildLabel("Role"),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _toggleButton(
                                    label: 'Student',
                                    selected: _role == 'student',
                                    onTap: () {
                                      setState(() {
                                        _role = 'student';
                                        _hasUnsavedChanges = true;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _toggleButton(
                                    label: 'Lecturer',
                                    selected: _role == 'lecturer',
                                    onTap: () {
                                      setState(() {
                                        _role = 'lecturer';
                                        _hasUnsavedChanges = true;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Program toggle
                            _buildLabel("Program"),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: _toggleButton(
                                    label: 'BCS',
                                    selected: _program == 'BCS',
                                    onTap: () {
                                      setState(() {
                                        _program = 'BCS';
                                        _hasUnsavedChanges = true;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _toggleButton(
                                    label: 'BSE',
                                    selected: _program == 'BSE',
                                    onTap: () {
                                      setState(() {
                                        _program = 'BSE';
                                        _hasUnsavedChanges = true;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _campusController,
                              label: "Campus",
                              icon: Icons.location_city_outlined,
                              iconColor: const Color(0xFF0D9488),
                              validator: (v) => (v == null || v.isEmpty) ? 'Campus is required' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _favGroupController,
                              label: "Fav Group",
                              icon: Icons.groups_outlined,
                              iconColor: const Color(0xFF14B8A6),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildTextField(
                              controller: _bioController,
                              label: "Bio",
                              icon: Icons.person_outline,
                              iconColor: const Color(0xFF22D3EE),
                              maxLines: 4,
                              maxLength: 250,
                              alignTop: true,
                            ),

                            const SizedBox(height: 16),

                            // 5. Interests Section
                            _buildLabel("Interests"),
                            const SizedBox(height: 8),
                            _GlassContainer(
                              padding: const EdgeInsets.all(12),
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 60),
                                width: double.infinity,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ..._interests.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final interest = entry.value;
                                      final color = _tagColors[index % _tagColors.length];
                                      return _InterestTag(
                                        label: interest,
                                        color: color,
                                        onRemove: () => _removeInterest(interest),
                                      );
                                    }),
                                    // Add Button
                                    GestureDetector(
                                      onTap: _addInterest,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            style: BorderStyle.solid,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Icon(Icons.add, color: Color(0xFF22D3EE), size: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color iconColor,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    bool alignTop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        _GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(top: alignTop ? 4 : 0),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: maxLines,
                  maxLength: maxLength,
                  cursorColor: const Color(0xFF22D3EE),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    counterText: "", // Hide counter
                  ),
                  validator: validator,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
          ),
        ),
      );

  Widget _toggleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF22D3EE).withOpacity(0.12) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF22D3EE) : Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? const Color(0xFF22D3EE) : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassContainer({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
            child: isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _InterestTag extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onRemove;

  const _InterestTag({
    required this.label,
    required this.color,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.7), size: 14),
          ),
        ],
      ),
    );
  }
}
