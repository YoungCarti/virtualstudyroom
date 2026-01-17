import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'widgets/animated_components.dart';
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

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Same as homepage
      body: Stack(
        children: [
          // Clean dark background - no glassmorphism (matching homepage)
          Container(
            color: const Color(0xFF0D1117),
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

                  // --- ENROLLED CLASSES GRID ---
                  if (uid != null)
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final data = snapshot.data?.data() ?? {};
                        final enrolledClasses = List<String>.from(data['enrolledClasses'] ?? []);

                        return Column(
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
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Column(
                                    children: [
                                      Icon(Icons.school_outlined, 
                                           color: Colors.grey[700], size: 48),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No classes enrolled yet',
                                        style: GoogleFonts.inter(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: enrolledClasses.length,
                                itemBuilder: (_, i) {
                                  final classCode = enrolledClasses[i];
                                  return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                    future: FirebaseFirestore.instance.collection('classes').doc(classCode).get(),
                                    builder: (context, classSnap) {
                                      if (!classSnap.hasData) {
                                        return const SizedBox.shrink();
                                      }
                                      final classData = classSnap.data?.data() ?? {};
                                      final className = classData['className'] ?? classCode;

                                      return _ClassGridCard(
                                        classCode: classCode,
                                        className: className,
                                        isLecturer: isLecturer,
                                        index: i,
                                      );
                                    },
                                  );
                                },
                              ),
                          ],
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
                              color: const Color(0xFF22D3EE), // Cyan Accent
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
                                color: const Color(0xFF22D3EE), // Cyan Accent
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
    // Solid dark card style (matching homepage)
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: child,
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
                  color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.class_outlined, color: Color(0xFF22D3EE), size: 24),
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

class _ClassGridCard extends StatelessWidget {
  final String classCode;
  final String className;
  final bool isLecturer;
  final int index;

  const _ClassGridCard({
    required this.classCode,
    required this.className,
    required this.isLecturer,
    required this.index,
  });

  // Color palette for class cards
  static const List<Color> _backgroundColors = [
    Color(0xFFFEE2E2), // Pink/Red
    Color(0xFFE0E7FF), // Indigo
    Color(0xFFD1FAE5), // Green
    Color(0xFFFEF3C7), // Amber
    Color(0xFFDBEAFE), // Blue
    Color(0xFFCFFAFE), // Cyan
    Color(0xFFF3E8FF), // Purple
    Color(0xFFFFE4E6), // Rose
  ];

  static const List<Color> _iconColors = [
    Color(0xFFDC2626), // Red
    Color(0xFF4F46E5), // Indigo
    Color(0xFF059669), // Green
    Color(0xFFD97706), // Amber
    Color(0xFF2563EB), // Blue
    Color(0xFF0891B2), // Cyan
    Color(0xFF9333EA), // Purple
    Color(0xFFE11D48), // Rose
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = _backgroundColors[index % _backgroundColors.length];
    final iconColor = _iconColors[index % _iconColors.length];
    
    // Get initials from class name
    final initials = className.split(' ')
        .take(2)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();

    return GestureDetector(
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  color: iconColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            className,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}