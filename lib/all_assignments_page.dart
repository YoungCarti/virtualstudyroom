import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assignment_service.dart';
import 'assignment_details_page.dart';

class AllAssignmentsPage extends StatefulWidget {
  const AllAssignmentsPage({super.key});

  @override
  State<AllAssignmentsPage> createState() => _AllAssignmentsPageState();
}

class _AllAssignmentsPageState extends State<AllAssignmentsPage> {
  final Map<String, List<Assignment>> _assignmentsByClass = {};
  StreamSubscription? _userSubscription;
  final Map<String, StreamSubscription> _classSubscriptions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    for (final sub in _classSubscriptions.values) sub.cancel();
    super.dispose();
  }

  void _startListening() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((userSnap) {
      if (!mounted) return;
      if (!userSnap.exists) {
         if (mounted) setState(() => _isLoading = false);
         return;
      }

      final enrolled = List<String>.from(userSnap.data()?['enrolledClasses'] ?? []);
      _syncSubscriptions(enrolled);
    });
  }

  void _syncSubscriptions(List<String> enrolledClasses) {
    final toRemove = _classSubscriptions.keys.where((k) => !enrolledClasses.contains(k)).toList();
    for (final k in toRemove) {
      _classSubscriptions[k]?.cancel();
      _classSubscriptions.remove(k);
      _assignmentsByClass.remove(k);
    }

    for (final classCode in enrolledClasses) {
      if (!_classSubscriptions.containsKey(classCode)) {
        _classSubscriptions[classCode] = FirebaseFirestore.instance
            .collection('classes')
            .doc(classCode)
            .collection('assignments')
            .where('dueDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
            .snapshots()
            .listen((snap) async {
              String className = '';
              try {
                final classDoc = await FirebaseFirestore.instance.collection('classes').doc(classCode).get();
                className = classDoc.data()?['className'] ?? '';
              } catch (e) {
                // ignore
              }

              if (!mounted) return;

              final assignments = snap.docs.map((d) => Assignment.fromFirestore(d, classCode, className: className)).toList();
              
              if (mounted) {
                setState(() {
                  _assignmentsByClass[classCode] = assignments;
                  _isLoading = false;
                });
              }
            });
      }
    }

    if (enrolledClasses.isEmpty && mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final Color topColor = const Color(0xFF7C3AED).withValues(alpha: 0.15);
    final Color bottomColor = const Color(0xFFC026D3).withValues(alpha: 0.1);

    final now = DateTime.now();
    final allAssignments = _assignmentsByClass.values
        .expand((l) => l)
        .where((a) => a.dueDate.isAfter(now))
        .toList();
    allAssignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, bottomColor],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'All Assignments',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // List
                Expanded(
                  child: _isLoading && allAssignments.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : allAssignments.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_turned_in_outlined, color: Colors.white.withValues(alpha: 0.3), size: 48),
                                  const SizedBox(height: 16),
                                  Text(
                                    'All done!',
                                    style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: allAssignments.length,
                              itemBuilder: (context, index) {
                                return AssignmentItem(
                                  assignment: allAssignments[index],
                                  isLecturer: false, // Viewer mode
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AssignmentItem extends StatelessWidget {
  final Assignment assignment;
  final bool isLecturer;

  const AssignmentItem({
    super.key,
    required this.assignment,
    required this.isLecturer,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = assignment.dueDate.difference(now);
    
    String status;
    Color statusColor;

    if (diff.inDays == 0 && !diff.isNegative) {
      status = 'Today';
      statusColor = const Color(0xFFF43F5E); // Red
    } else if (diff.inDays == 1) {
      status = 'Tomorrow';
      statusColor = const Color(0xFFF59E0B); // Amber
    } else if (diff.isNegative) {
      status = 'Overdue';
      statusColor = Colors.grey;
    } else {
      status = DateFormat('MMM d').format(assignment.dueDate);
      statusColor = const Color(0xFF22D3EE); // Cyan
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AssignmentDetailsPage(
                  classCode: assignment.classCode,
                  assignmentId: assignment.id,
                  isLecturer: isLecturer,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.assignment_outlined, color: statusColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignment.className.isNotEmpty ? assignment.className : assignment.classCode,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.inter(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
