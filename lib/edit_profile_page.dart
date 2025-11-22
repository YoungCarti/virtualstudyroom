import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color _primaryCyan = Color(0xFF5BB5D9);
const Color _darkBackground = Color(0xFF1C1C28);
const Color _cardBackground = Color(0xFF2A2A3E);

class EditProfilePage extends StatefulWidget {
  // accept optional userDocId to edit; default to current auth user
  final String? userDocId;
  const EditProfilePage({super.key, this.userDocId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _programController = TextEditingController();
  final _studentIdController = TextEditingController();

  String _role = 'student'; // student | lecturer

  bool _loading = false;
  late final String _docId;
  final _users = FirebaseFirestore.instance.collection('users');

  @override
  void initState() {
    super.initState();
    _docId = widget.userDocId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    if (_docId.isNotEmpty) _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final snap = await _users.doc(_docId).get();
      if (!snap.exists) return;
      final data = snap.data()!;
      setState(() {
        // prefer fullName, fallback to legacy name
        _fullNameController.text = data['fullName'] ?? data['name'] ?? '';
        _emailController.text = data['email'] ?? '';
        _role = (data['role'] ?? 'student') as String;
        _programController.text = data['program'] ?? '';
        _studentIdController.text = data['studentID'] ?? '';
      });
    } catch (e) {
      // ignore load errors
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _programController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_docId.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final updateData = <String, dynamic>{
      'fullName': _fullNameController.text.trim(),
      // keep legacy 'name' in sync for older code
      'name': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'role': _role,
    };

    if (_role == 'student') {
      updateData['program'] = _programController.text.trim();
      final sid = _studentIdController.text.trim();
      if (sid.isNotEmpty) updateData['studentID'] = sid;
      else updateData['studentID'] = FieldValue.delete();
    } else {
      // remove student-specific keys when lecturer
      updateData['program'] = FieldValue.delete();
      updateData['studentID'] = FieldValue.delete();
    }

    try {
      // merge to avoid clobbering other fields (createdAt, enrolledClasses, etc.)
      await _users.doc(_docId).set(updateData, SetOptions(merge: true));

      // also update displayName in Auth user if changed
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.displayName != _fullNameController.text.trim()) {
        try {
          await user.updateDisplayName(_fullNameController.text.trim());
        } catch (_) {}
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        backgroundColor: _darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture (unchanged)
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                        image: const DecorationImage(
                          image: NetworkImage('https://i.pravatar.cc/150?img=33'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _primaryCyan,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Full Name Field
              _buildLabel('Full name'),
              _buildTextField(controller: _fullNameController, hintText: 'Enter your full name'),
              const SizedBox(height: 20),

              // Role Field (student / lecturer)
              _buildLabel('Role'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3A3A52)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _role,
                    isExpanded: true,
                    dropdownColor: _cardBackground,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8B8B9F)),
                    items: ['student', 'lecturer'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _role = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Email Field
              _buildLabel('Email'),
              _buildTextField(controller: _emailController, hintText: 'you@university.edu', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),

              // Academic fields for students only
              if (_role == 'student') ...[
                _buildLabel('Program'),
                _buildTextField(controller: _programController, hintText: 'e.g. BSc Computer Science'),
                const SizedBox(height: 20),
                _buildLabel('Student ID (optional)'),
                _buildTextField(controller: _studentIdController, hintText: 'Student ID / registration number'),
                const SizedBox(height: 20),
              ],

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryCyan,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Update Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(color: _cardBackground, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF3A3A52))),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF8B8B9F), fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: const Color(0xFF8B8B9F), size: 20) : null,
        ),
        validator: (v) {
          if (hintText.toLowerCase().contains('email') && (v == null || !v.contains('@'))) {
            return 'Enter a valid email';
          }
          if (hintText.toLowerCase().contains('name') && (v == null || v.trim().isEmpty)) {
            return 'Enter your name';
          }
          return null;
        },
      ),
    );
  }
}
