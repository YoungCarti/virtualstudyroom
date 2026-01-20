import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final String? userDocId;
  const EditProfilePage({super.key, this.userDocId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

// Helper function to get initials from a name
String _getInitials(String name) {
  if (name.isEmpty) return '?';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts[0][0].toUpperCase();
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
  String? _photoUrl;             // Profile photo URL

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
        // Prioritize profilePictureUrl, fallback to photoUrl
        _photoUrl = data['profilePictureUrl'] ?? data['photoUrl'];
        
        if (data['interests'] != null) {
          _interests = List<String>.from(data['interests']);
        } else {
          _interests = ["Machine Learning", "Web Development", "Mobile Apps"];
        }
        _hasUnsavedChanges = false;
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
      
      if (image == null) return;

      setState(() => _loading = true);

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$_docId.jpg');
      
      // Use putData for cross-platform support (especially web)
      final bytes = await image.readAsBytes();
      await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore
      // Save to both fields for backward compatibility
      await _users.doc(_docId).update({
        'photoUrl': downloadUrl,
        'profilePictureUrl': downloadUrl,
      });

      if (mounted) {
        setState(() {
          _photoUrl = downloadUrl;
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!')),
        );
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
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
        backgroundColor: const Color(0xFF122A46), // Midnight Blue
        title: const Text('Add Interest', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. AI, Music',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2196F3))), // Electric Blue
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
            child: const Text('Add', style: TextStyle(color: Color(0xFF2196F3))),
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
      'name': _fullNameController.text.trim(),
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
        backgroundColor: const Color(0xFF122A46), // Midnight Blue
        title: const Text('Unsaved Changes', style: TextStyle(color: Colors.white)),
        content: const Text('Discard changes?', style: TextStyle(color: Colors.white70)),
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
    // Theme Colors (Matching SettingsPage)
    final Color topColor = const Color(0xFF0A1929); // Deep Navy
    final Color bottomColor = const Color(0xFF122A46); // Midnight Blue

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            "Edit Profile",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          actions: [
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.check, color: Color(0xFF4ECDC4)), // Mint Green Success
                onPressed: _saveProfile,
              ),
          ],
        ),
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
              right: -60,
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
            Positioned(
              bottom: 80,
              left: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF4ECDC4).withValues(alpha: 0.2), // Mint Green
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7],
                  ),
                ),
              ),
            ),

            // 3. Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Photo
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 2,
                                ),
                                color: _photoUrl == null || _photoUrl!.isEmpty ? const Color(0xFF2196F3) : null,
                                image: _photoUrl != null && _photoUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(_photoUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _photoUrl == null || _photoUrl!.isEmpty
                                  ? Center(
                                      child: Text(
                                        _getInitials(_fullNameController.text),
                                        style: const TextStyle(
                                          fontSize: 32, // Larger for this page
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: _loading ? null : _updatePhoto,
                              child: _GlassContainer(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_loading)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF2196F3),
                                        ),
                                      )
                                    else
                                      const Icon(Icons.camera_alt, color: Color(0xFF2196F3), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      _loading ? "Uploading..." : "Change Photo",
                                      style: const TextStyle(color: Color(0xFF2196F3), fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Basic Info Section
                      _buildSectionHeader("Personal Info"),
                      _GlassContainer(
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _fullNameController,
                              label: "Full Name",
                              icon: Icons.person_outline,
                              validator: (v) => (v == null || v.length < 2) ? 'Min 2 chars' : null,
                            ),
                            _buildDivider(),
                            _buildTextField(
                              controller: _campusController,
                              label: "Campus",
                              icon: Icons.location_city_outlined,
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                            _buildDivider(),
                            _buildTextField(
                              controller: _favGroupController,
                              label: "Fav Group",
                              icon: Icons.groups_outlined,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),



                      // Bio
                      _buildSectionHeader("About Me"),
                      _GlassContainer(
                        child: _buildTextField(
                          controller: _bioController,
                          label: "Bio",
                          icon: Icons.edit_outlined,
                          maxLines: 4,
                          maxLength: 250,
                          alignTop: true,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Interests
                      _buildSectionHeader("Interests"),
                      _GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ..._interests.asMap().entries.map((entry) {
                                final index = entry.key;
                                final color = _tagColors[index % _tagColors.length];
                                return _InterestTag(
                                  label: entry.value,
                                  color: color,
                                  onRemove: () => _removeInterest(entry.value),
                                );
                              }),
                              GestureDetector(
                                onTap: _addInterest,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: const Icon(Icons.add, color: Color(0xFF2196F3), size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS (Matching Settings Page Style) ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    bool alignTop = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: alignTop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: alignTop ? 4 : 0),
            child: Icon(icon, color: Colors.white70, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller.text.isNotEmpty)
                  Text(
                    label,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                  ),
                TextFormField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                  maxLines: maxLines,
                  maxLength: maxLength,
                  cursorColor: const Color(0xFF2196F3),
                  decoration: InputDecoration(
                    hintText: label,
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    counterText: "",
                  ),
                  validator: validator,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.white.withValues(alpha: 0.1), indent: 16, endIndent: 16);
  }
}

// Reusable Glass Container (Same as SettingsPage)
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _GlassContainer({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF122A46).withValues(alpha: 0.5), // Midnight Blue semi-transparent
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _InterestTag extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onRemove;

  const _InterestTag({required this.label, required this.color, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, color: Colors.white70, size: 14),
          ),
        ],
      ),
    );
  }
}