import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('classes')
          .doc(classCode)
          .collection('assignments')
          .doc(assignmentId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Assignment not found')),
          );
        }

        final assignment = Assignment.fromFirestore(snapshot.data!, classCode);

        return Scaffold(
          appBar: AppBar(
            title: Text(assignment.title),
            centerTitle: true,
            actions: [
              if (isLecturer)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
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
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assignment info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        assignment.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Due: ${DateFormat('MMMM d, yyyy').format(assignment.dueDate)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Created: ${DateFormat('MMM d, yyyy').format(assignment.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                          ),
                        ],
                      ),
                      if (assignment.attachmentUrl != null) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            // TODO: Open URL
                            // For now, just show a snackbar or print
                            print('Open URL: ${assignment.attachmentUrl}');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Downloading file...')),
                            );
                          },
                          child: Row(
                            children: [
                              Icon(
                                Icons.attach_file,
                                size: 20,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  assignment.attachmentName ?? 'Attachment',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submissions section
                Text('Submissions', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                
                if (isLecturer)
                  // Lecturer View: Show all submissions
                  StreamBuilder<List<Submission>>(
                    stream: AssignmentService.instance.getSubmissions(classCode, assignmentId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final submissions = snapshot.data ?? [];
                      
                      if (submissions.isEmpty) {
                        return const Text('No submissions yet.');
                      }
                      
                      return Column(
                        children: submissions.map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.studentName,
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    if (s.attachmentName != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        s.attachmentName!,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      'Submitted: ${s.submittedAt != null ? DateFormat('MMM d, h:mm a').format(s.submittedAt!) : 'Unknown'}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: isDark ? Colors.white60 : Colors.black54,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (s.attachmentUrl != null)
                                IconButton(
                                  icon: const Icon(Icons.download_rounded),
                                  onPressed: () {
                                    // TODO: Download file
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Downloading submission...')),
                                    );
                                  },
                                ),
                            ],
                          ),
                        )).toList(),
                      );
                    },
                  )
                else
                  // Student View: Show own submission or submit button
                  StreamBuilder<Submission?>(
                    stream: AssignmentService.instance.getSubmission(
                      classCode, 
                      assignmentId, 
                      FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      final mySubmission = snapshot.data;
                      
                      if (mySubmission != null) {
                        // Already submitted
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Submitted',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'On ${mySubmission.submittedAt != null ? DateFormat('MMM d, h:mm a').format(mySubmission.submittedAt!) : ''}',
                                      style: TextStyle(
                                        color: isDark ? Colors.white70 : Colors.black87,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (mySubmission.attachmentName != null)
                                      Text(
                                        mySubmission.attachmentName!,
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black87,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Not submitted yet
                        return SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SubmitAssignmentPage(
                                    classCode: classCode,
                                    assignmentId: assignmentId,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Submit Assignment'),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}