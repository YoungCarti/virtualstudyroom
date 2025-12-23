import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'class_details_page.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key, this.role = 'student'});
  final String role;

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  final _enrollCodeCtrl = TextEditingController();
  final _createCodeCtrl = TextEditingController();
  final _createNameCtrl = TextEditingController();

  bool _savingEnroll = false;
  bool _savingCreate = false;

  @override
  void dispose() {
    _enrollCodeCtrl.dispose();
    _createCodeCtrl.dispose();
    _createNameCtrl.dispose();
    super.dispose();
  }

  // Enroll Logic
  Future<void> _enroll() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = _enrollCodeCtrl.text.trim();
    if (uid == null || code.isEmpty) return;

    setState(() => _savingEnroll = true);

    try {
      final classDoc = await FirebaseFirestore.instance.collection('classes').doc(code).get();

      if (!classDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class not found')));
        }
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'enrolledClasses': FieldValue.arrayUnion([code]),
      }, SetOptions(merge: true));

      _enrollCodeCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enrolled in $code')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to enroll: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingEnroll = false);
    }
  }

  // Create Class Logic
  Future<void> _createClass() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = _createCodeCtrl.text.trim();
    final name = _createNameCtrl.text.trim();
    if (uid == null || code.isEmpty || name.isEmpty) return;

    setState(() => _savingCreate = true);

    try {
      final classRef = FirebaseFirestore.instance.collection('classes').doc(code);
      final classDoc = await classRef.get();
      
      if (classDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class code already exists')));
        }
        return;
      }

      await classRef.set({
        'className': name,
        'code': code,
        'lecturerId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Init subcollections
      await classRef.collection('assignments').doc('_placeholder').set({'_': true});
      await classRef.collection('groups').doc('_placeholder').set({'_': true});
      await classRef.collection('materials').doc('_placeholder').set({'_': true});

      // Enroll lecturer
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'enrolledClasses': FieldValue.arrayUnion([code]),
      }, SetOptions(merge: true));

      _createCodeCtrl.clear();
      _createNameCtrl.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Class "$name" created')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create class: $e')));
      }
    } finally {
      if (mounted) setState(() => _savingCreate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLecturer = widget.role == 'lecturer';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Theme Colors
    final Color topColor = const Color(0xFF7C3AED).withValues(alpha: 0.15); // Slightly stronger
    final Color bottomColor = const Color(0xFFC026D3).withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A), // ★★★ Dark Base Color added here
      body: Stack(
        children: [
          // 1. Background Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, bottomColor],
              ),
            ),
          ),

          // 2. Ambient Glow Orbs
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2), // Violet
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.15), // Cyan
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'My Classes',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- ENROLLED CLASSES LIST ---
                  if (uid != null)
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final data = snapshot.data?.data() ?? {};
                        final enrolledClasses = List<String>.from(data['enrolledClasses'] ?? []);

                        return _GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enrolled Classes',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (enrolledClasses.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Text(
                                      'No classes yet.',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withValues(alpha: 0.5),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: enrolledClasses.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (_, i) {
                                    final classCode = enrolledClasses[i];
                                    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                      future: FirebaseFirestore.instance.collection('classes').doc(classCode).get(),
                                      builder: (context, classSnap) {
                                        if (!classSnap.hasData) return const SizedBox.shrink();
                                        final classData = classSnap.data?.data() ?? {};
                                        final className = classData['className'] ?? classCode;

                                        return _ClassListTile(
                                          classCode: classCode,
                                          className: className,
                                          isLecturer: isLecturer,
                                        );
                                      },
                                    );
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 24),

                  // --- ENROLL SECTION ---
                  _GlassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enroll in a class',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _GlassTextField(
                                controller: _enrollCodeCtrl,
                                hintText: 'Enter class code',
                              ),
                            ),
                            const SizedBox(width: 12),
                            _ActionButton(
                              label: 'Enroll',
                              isLoading: _savingEnroll,
                              onTap: _savingEnroll ? null : _enroll,
                              color: const Color(0xFFA855F7), // Purple Accent
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // --- CREATE SECTION (Lecturer Only) ---
                  if (isLecturer) ...[
                    const SizedBox(height: 24),
                    _GlassContainer(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create a class',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _GlassTextField(
                            controller: _createNameCtrl,
                            hintText: 'Class name (e.g. CS101 Lecture)',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _GlassTextField(
                                  controller: _createCodeCtrl,
                                  hintText: 'Unique Code',
                                ),
                              ),
                              const SizedBox(width: 12),
                              _ActionButton(
                                label: 'Create',
                                isLoading: _savingCreate,
                                onTap: _savingCreate ? null : _createClass,
                                color: const Color(0xFFEC4899), // Pink Accent
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGETS ---

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassContainer({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3), // ★ Darker Tint for better contrast
            borderRadius: BorderRadius.circular(24),
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

class _ClassListTile extends StatelessWidget {
  final String classCode;
  final String className;
  final bool isLecturer;

  const _ClassListTile({
    required this.classCode,
    required this.className,
    required this.isLecturer,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ClassDetailsPage(
                classCode: classCode,
                className: className,
                isLecturer: isLecturer,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.class_outlined, color: Color(0xFFA855F7), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      className,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      classCode,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _GlassTextField({required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          isDense: true,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color color;

  const _ActionButton({
    required this.label,
    required this.isLoading,
    this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}