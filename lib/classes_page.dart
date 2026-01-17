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

  Future<void> _showEnrollDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Enroll in a Class', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter the class code provided by your instructor.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 16),
            _GlassTextField(controller: _enrollCodeCtrl, hintText: 'Class Code'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _enroll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22D3EE),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Enroll'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateClassDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Create a Class', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter details to create a new class.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 16),
            _GlassTextField(controller: _createNameCtrl, hintText: 'Class Name'),
            const SizedBox(height: 12),
            _GlassTextField(controller: _createCodeCtrl, hintText: 'Unique Class Code'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createClass();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22D3EE),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Enrolled Classes',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.add, color: Color(0xFF22D3EE)),
                                    tooltip: isLecturer ? 'Create a class' : 'Enroll in a class',
                                    onPressed: () => isLecturer ? _showCreateClassDialog(context) : _showEnrollDialog(context),
                                  ),
                                ),
                              ],
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
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: enrolledClasses.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 20),
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
                
                                      return _ClassCard(
                                        classCode: classCode,
                                        className: className,
                                        lecturerId: classData['lecturerId'],
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
                  
                  // Bottom section removed - moved to dialog
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

// Removed _ClassListTile as it's no longer used

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

class _ClassCard extends StatelessWidget {
  final String classCode;
  final String className;
  final String? lecturerId;
  final bool isLecturer;
  final int index;

  const _ClassCard({
    required this.classCode,
    required this.className,
    this.lecturerId,
    required this.isLecturer,
    required this.index,
  });

  // Gradients for cover
  static const List<LinearGradient> _gradients = [
     LinearGradient(colors: [Color(0xFFFCA5A5), Color(0xFFFECACA)], begin: Alignment.topLeft, end: Alignment.bottomRight), // Red
     LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA5B4FC)], begin: Alignment.topLeft, end: Alignment.bottomRight), // Indigo
     LinearGradient(colors: [Color(0xFF10B981), Color(0xFF6EE7B7)], begin: Alignment.topLeft, end: Alignment.bottomRight), // Emerald
     LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFCD34D)], begin: Alignment.topLeft, end: Alignment.bottomRight), // Amber
  ];

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[index % _gradients.length];
    
    // Simulate progress (deterministic based on code length to keep it consistent but varied)
    final totalMaterials = 10 + (classCode.hashCode % 10); 
    final completedMaterials = (classCode.hashCode % totalMaterials);
    final progressColor = index % 2 == 0 ? const Color(0xFF991B1B) : const Color(0xFF10B981); // Red or Green pill bg

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
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E), // Card Dark bg
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            // TOP: Cover Image Area
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                  ),
                  // Abstract patterns or icon
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      Icons.school,
                      size: 150,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  // Instructor Chip (Floating)
                  Positioned(
                    bottom: 12,
                    left: 16,
                    child: _LecturerChip(lecturerId: lecturerId),
                  ),
                ],
              ),
            ),
            
            // BOTTOM: Info Area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            className,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalMaterials materials',
                            style: GoogleFonts.inter(
                              color: Colors.grey[400],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Progress Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: progressColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: progressColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '$completedMaterials/$totalMaterials',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LecturerChip extends StatelessWidget {
  final String? lecturerId;
  const _LecturerChip({this.lecturerId});

  @override
  Widget build(BuildContext context) {
    if (lecturerId == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(lecturerId).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        // Check 'name', then 'fullName', default to 'Instructor'
        final name = data?['name'] ?? data?['fullName'] ?? 'Instructor';
        // Simple avatar simulation
        final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
               BoxShadow(
                 color: Colors.black.withValues(alpha: 0.1),
                 blurRadius: 4,
                 offset: const Offset(0, 2),
               )
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF22D3EE),
                child: Text(initial, style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Text(
                name,
                style: GoogleFonts.inter(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        );
      },
    );
  }
}