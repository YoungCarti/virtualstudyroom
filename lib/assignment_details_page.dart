import 'app_fonts.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'assignment_service.dart';
import 'assignment_edit_details_page.dart';
import 'submit_assignment_page.dart';

class AssignmentDetailsPage extends StatelessWidget {
  const AssignmentDetailsPage({
    super.key,
    required this.classCode,
    required this.assignmentId,
    required this.isLecturer,
  });

  final String classCode;
  final String assignmentId;
  final bool isLecturer;

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final Color topColor = const Color(0xFF7C3AED).withValues(alpha: 0.15);
    final Color bottomColor = const Color(0xFFC026D3).withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A), // Dark Base
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

          // 2. Ambient Glow Orbs
          Positioned(
            top: -100,
            right: -50,
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
            left: -80,
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

          // 3. Main Content
          SafeArea(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(classCode)
                  .collection('assignments')
                  .doc(assignmentId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                    child: Text(
                      'Assignment not found',
                      style: AppFonts.clashGrotesk(color: Colors.white70),
                    ),
                  );
                }

                final assignment = Assignment.fromFirestore(snapshot.data!, classCode);

                return Column(
                  children: [
                    // Custom App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _GlassIconButton(
                            icon: Icons.chevron_left,
                            onTap: () => Navigator.pop(context),
                          ),
                          Text(
                            'Assignment Details',
                            style: AppFonts.clashGrotesk(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isLecturer)
                            Row(
                              children: [
                                _GlassIconButton(
                                  icon: Icons.edit_outlined,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => AssignmentEditDetailsPage(
                                          classCode: classCode,
                                          assignmentId: assignmentId,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                _GlassIconButton(
                                  icon: Icons.delete_outline,
                                  iconColor: const Color(0xFFF43F5E), // Red
                                  onTap: () => _handleDelete(context),
                                ),
                              ],
                            )
                          else
                            const SizedBox(width: 48), // Placeholder for alignment
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Info Card
                            _GlassContainer(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    assignment.title,
                                    style: AppFonts.clashGrotesk(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    assignment.description,
                                    style: AppFonts.clashGrotesk(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Divider(color: Colors.white.withValues(alpha: 0.1)),
                                  const SizedBox(height: 16),
                                  _DetailRow(
                                    icon: Icons.calendar_today_outlined,
                                    label: "Due Date",
                                    value: DateFormat('MMM d, yyyy  h:mm a').format(assignment.dueDate),
                                    color: const Color(0xFFF59E0B), // Amber
                                  ),
                                  const SizedBox(height: 12),
                                  _DetailRow(
                                    icon: Icons.access_time,
                                    label: "Created",
                                    value: DateFormat('MMM d, yyyy').format(assignment.createdAt),
                                    color: const Color(0xFF22D3EE), // Cyan
                                  ),
                                  if (assignment.attachmentUrl != null) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Downloading file...')),
                                          );
                                        },
                                        child: Row(
                                          children: [
                                            const Icon(Icons.attach_file, color: Color(0xFFA855F7)),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                assignment.attachmentName ?? 'Attached File',
                                                style: AppFonts.clashGrotesk(
                                                  color: const Color(0xFFA855F7),
                                                  fontWeight: FontWeight.w500,
                                                  decoration: TextDecoration.underline,
                                                  decorationColor: const Color(0xFFA855F7),
                                                ),
                                              ),
                                            ),
                                            const Icon(Icons.download_rounded, color: Colors.white54, size: 20),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Submissions Header
                            Text(
                              'Submissions',
                              style: AppFonts.clashGrotesk(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Content based on Role
                            if (isLecturer)
                              _buildLecturerView(assignment)
                            else
                              _buildStudentView(assignment),
                              
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Text('Delete Assignment', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this assignment? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFF43F5E))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AssignmentService.instance.deleteAssignment(classCode, assignmentId);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Widget _buildLecturerView(Assignment assignment) {
    return StreamBuilder<List<Submission>>(
      stream: AssignmentService.instance.getSubmissions(classCode, assignmentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final submissions = snapshot.data ?? [];

        if (submissions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No submissions yet.',
                style: AppFonts.clashGrotesk(color: Colors.white54),
              ),
            ),
          );
        }

        return Column(
          children: submissions.map((s) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: _GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person_outline, color: Color(0xFFA855F7)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.studentName,
                          style: AppFonts.clashGrotesk(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (s.attachmentName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            s.attachmentName!,
                            style: AppFonts.clashGrotesk(
                              color: const Color(0xFF22D3EE),
                              fontSize: 13,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          s.submittedAt != null 
                              ? DateFormat('MMM d, h:mm a').format(s.submittedAt!) 
                              : 'Unknown',
                          style: AppFonts.clashGrotesk(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (s.attachmentUrl != null)
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: Colors.white70),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading submission...')),
                        );
                      },
                    ),
                ],
              ),
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildStudentView(Assignment assignment) {
    return FutureBuilder<Map<String, String>?>(
      future: assignment.submissionType == 'group'
          ? AssignmentService.instance.getStudentGroup(
              classCode, FirebaseAuth.instance.currentUser?.uid ?? '')
          : Future.value(null),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groupInfo = groupSnapshot.data;
        final groupId = groupInfo?['groupId'];
        final groupName = groupInfo?['groupName'];
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

        // Warning for group assignment
        if (assignment.submissionType == 'group' && groupId == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is a group assignment. You must be in a group to submit.',
                    style: AppFonts.clashGrotesk(color: const Color(0xFFF59E0B)),
                  ),
                ),
              ],
            ),
          );
        }

        final submissionIdToCheck = assignment.submissionType == 'group' ? groupId! : uid;

        return StreamBuilder<Submission?>(
          stream: AssignmentService.instance.getSubmission(
            classCode, assignmentId, submissionIdToCheck,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final mySubmission = snapshot.data;
            
            if (mySubmission != null) {
              // Submitted View
              return _GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.submissionType == 'group' 
                                ? 'Submitted by ${mySubmission.studentName}' 
                                : 'Submitted',
                            style: AppFonts.clashGrotesk(
                              color: const Color(0xFF10B981),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mySubmission.submittedAt != null 
                                ? DateFormat('MMM d, h:mm a').format(mySubmission.submittedAt!) 
                                : '',
                            style: AppFonts.clashGrotesk(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          if (mySubmission.attachmentName != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              mySubmission.attachmentName!,
                              style: AppFonts.clashGrotesk(
                                color: Colors.white54,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Submit Button
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SubmitAssignmentPage(
                          classCode: classCode,
                          assignmentId: assignmentId,
                          groupId: groupId,
                          groupName: groupName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    assignment.submissionType == 'group' 
                        ? 'Submit for Group ($groupName)' 
                        : 'Submit Assignment',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA855F7), // Primary Purple
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

// --- WIDGET HELPERS ---

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassContainer({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3), // Dark Tint
            borderRadius: BorderRadius.circular(20),
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
  final Color? iconColor;

  const _GlassIconButton({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppFonts.clashGrotesk(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppFonts.clashGrotesk(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}