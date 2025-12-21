import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'class_details_page.dart';
import 'widgets/gradient_background.dart';

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

  // Enroll in existing class
  Future<void> _enroll() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = _enrollCodeCtrl.text.trim();
    if (uid == null || code.isEmpty) return;

    setState(() => _savingEnroll = true);

    try {
      // Check if class exists
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(code)
          .get();

      if (!classDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Class not found')),
          );
        }
        return;
      }

      // Add user to enrolledClasses array
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'enrolledClasses': FieldValue.arrayUnion([code]),
      }, SetOptions(merge: true));

      _enrollCodeCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enrolled in $code')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to enroll: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingEnroll = false);
    }
  }

  // Create class (lecturer only)
  Future<void> _createClass() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final code = _createCodeCtrl.text.trim();
    final name = _createNameCtrl.text.trim();
    if (uid == null || code.isEmpty || name.isEmpty) return;

    setState(() => _savingCreate = true);

    try {
      final classRef = FirebaseFirestore.instance.collection('classes').doc(code);
      
      // Check if class code already exists
      final classDoc = await classRef.get();
      if (classDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Class code already exists')),
          );
        }
        return;
      }

      // Create class document
      await classRef.set({
        'className': name,
        'code': code,
        'lecturerId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create subcollections
      await classRef.collection('assignments').doc('_placeholder').set({'_': true});
      await classRef.collection('groups').doc('_placeholder').set({'_': true});
      await classRef.collection('materials').doc('_placeholder').set({'_': true});

      // Enroll lecturer in the class
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        'enrolledClasses': FieldValue.arrayUnion([code]),
      }, SetOptions(merge: true));

      _createCodeCtrl.clear();
      _createNameCtrl.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Class "$name" created')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create class: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingCreate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLecturer = widget.role == 'lecturer';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Material(
      type: MaterialType.transparency,
      child: GradientBackground(
        child: SafeArea(
          bottom: false, // Allow bottom nav to overlap if needed, or handle padding in dashboard
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Added bottom padding for nav bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              const Text(
                'My Classes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
                const SizedBox(height: 24),

                // Enrolled Classes Section (from Firebase)
                if (uid != null)
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data = snapshot.data?.data() ?? {};
                      final enrolledClasses = List<String>.from(
                        data['enrolledClasses'] ?? <dynamic>[],
                      );

                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF33264a),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enrolled Classes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (enrolledClasses.isEmpty)
                              Text(
                                'No classes yet.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 14,
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
                                    future: FirebaseFirestore.instance
                                        .collection('classes')
                                        .doc(classCode)
                                        .get(),
                                    builder: (context, classSnap) {
                                      if (!classSnap.hasData) {
                                        return const SizedBox.shrink();
                                      }

                                      final classData = classSnap.data?.data() ?? {};
                                      final className = classData['className'] ?? classCode;

                                      return InkWell(
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => ClassDetailsPage(
                                                classCode: classCode,
                                                className: className,
                                                isLecturer: isLecturer,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2d2140),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFa855f7)
                                                      .withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.class_outlined,
                                                  color: Color(0xFFa855f7),
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      className,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      classCode,
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withValues(alpha: 0.6),
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right,
                                                color: Colors.white.withValues(alpha: 0.5),
                                              ),
                                            ],
                                          ),
                                        ),
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

                // Enroll section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF33264a),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enroll in a class',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _enrollCodeCtrl,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Enter class code',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF2d2140),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _savingEnroll ? null : _enroll,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFa855f7),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                              ),
                              child: _savingEnroll
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Enroll',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Create section (lecturers only)
                if (isLecturer) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF33264a),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create a class',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _createNameCtrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Class name (e.g., CS101 Lecture A)',
                            hintStyle: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF2d2140),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _createCodeCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: 'Class code (unique)',
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFF2d2140),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _savingCreate ? null : _createClass,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFec4899),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                ),
                                child: _savingCreate
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Create',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
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
      ),
    );
  }
}