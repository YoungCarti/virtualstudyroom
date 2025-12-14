import 'package:flutter/material.dart';
import 'assignment_edit_details_page.dart';

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

  // Sample data (local for now, will wire to Firebase later)
  Map<String, dynamic> get _assignmentData => {
        'title': 'Assignment 1',
        'description': 'Complete the programming exercises in Chapter 3',
        'dueDate': 'January 15, 2025',
        'createdAt': 'November 22, 2025',
        'createdBy': 'uid_lecturer_test',
      };

  List<Map<String, String>> get _submissions => [
        {'groupId': 'group01', 'fileName': 'GroupReport.pdf', 'submittedBy': 'student1_uid', 'submittedAt': 'Nov 22, 2025 3:15 AM'},
      ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_assignmentData['title'] as String),
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
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
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
                    _assignmentData['description'] as String,
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
                        'Due: ${_assignmentData['dueDate']}',
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
                        'Created: ${_assignmentData['createdAt']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submissions section
            Text('Submissions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_submissions.isEmpty)
              const Text('No submissions yet.')
            else
              ..._submissions.map((s) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.upload_file_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['fileName'] ?? '',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Group: ${s['groupId']}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'Submitted: ${s['submittedAt']}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}