import 'app_fonts.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import 'assignment_service.dart';
import 'assignment_edit_details_page.dart';

// Ocean Sunset Color Scheme
class _AppColors {
  static const background = Color(0xFF0A1929);
  static const cardBg = Color(0xFF122A46);
  static const primary = Color(0xFF2196F3);
  static const accent1 = Color(0xFFFF6B6B);
  static const accent2 = Color(0xFF4ECDC4);
  static const secondary = Color(0xFFFFB347);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF90A4AE);
  static const divider = Color(0xFF1E3A5F);
}

class AssignmentDetailsPage extends StatefulWidget {
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
  State<AssignmentDetailsPage> createState() => _AssignmentDetailsPageState();
}

class _AssignmentDetailsPageState extends State<AssignmentDetailsPage> {
  // Lecturer file upload state
  File? _selectedFile;
  String? _selectedFileName;
  bool _isUploading = false;
  
  // Student submission state
  File? _studentFile;
  String? _studentFileName;
  String? _studentGroupId;
  String? _studentGroupName;
  
  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
          _isUploading = true;
        });
        
        final fileName = _selectedFileName ?? 'file';
        final ref = FirebaseStorage.instance
            .ref()
            .child('assignments')
            .child(widget.classCode)
            .child(widget.assignmentId)
            .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
        
        await ref.putFile(_selectedFile!);
        final fileUrl = await ref.getDownloadURL();
        
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classCode)
            .collection('assignments')
            .doc(widget.assignmentId)
            .update({
          'attachmentUrl': fileUrl,
          'attachmentName': fileName,
        });
        
        if (mounted) {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document uploaded successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }
  
  // Student: Pick file only (store locally, don't upload yet)
  Future<void> _pickStudentFile(String? groupId, String? groupName) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      
      if (result != null && result.files.single.path != null) {
        setState(() {
          _studentFile = File(result.files.single.path!);
          _studentFileName = result.files.single.name;
          _studentGroupId = groupId;
          _studentGroupName = groupName;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting file: $e')),
        );
      }
    }
  }
  
  // Student: Submit the selected file
  Future<void> _submitStudentFile() async {
    if (_studentFile == null || _studentFileName == null) return;
    
    try {
      setState(() => _isUploading = true);
      
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final submissionId = _studentGroupId ?? uid;
      
      // Get student name
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final studentName = _studentGroupName ?? userDoc.data()?['displayName'] ?? 'Unknown';
      
      // Upload file to storage - path must match storage.rules
      final ref = FirebaseStorage.instance
          .ref()
          .child('classes')
          .child(widget.classCode)
          .child('assignments')
          .child(widget.assignmentId)
          .child('submissions')
          .child('${submissionId}_$_studentFileName');
      
      await ref.putFile(_studentFile!);
      final fileUrl = await ref.getDownloadURL();
      
      // Save submission to Firestore
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classCode)
          .collection('assignments')
          .doc(widget.assignmentId)
          .collection('submissions')
          .doc(submissionId)
          .set({
        'studentId': uid,
        'studentName': studentName,
        'attachmentUrl': fileUrl,
        'attachmentName': _studentFileName,
        'submittedAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        setState(() {
          _isUploading = false;
          _studentFile = null;
          _studentFileName = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    }
  }
  
  Future<void> _downloadAndOpenFile(String fileUrl, String fileName) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: _AppColors.primary),
        ),
      );

      final response = await http.get(Uri.parse(fileUrl));
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      if (mounted) Navigator.pop(context);

      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _AppColors.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _AppColors.divider),
        ),
        title: Text('Delete Assignment', style: TextStyle(color: _AppColors.textPrimary)),
        content: Text(
          'Are you sure you want to delete this assignment?',
          style: TextStyle(color: _AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: _AppColors.accent1)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AssignmentService.instance.deleteAssignment(widget.classCode, widget.assignmentId);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assignment deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classCode)
              .collection('assignments')
              .doc(widget.assignmentId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _AppColors.primary));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Text('Assignment not found', style: TextStyle(color: _AppColors.textSecondary)),
              );
            }

            final assignment = Assignment.fromFirestore(snapshot.data!, widget.classCode);

            // Use Stack for floating button
            return Stack(
              children: [
                Column(
                  children: [
                    // App Bar with Class Pill
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 16),
                          // Class Name Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _AppColors.cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _AppColors.divider),
                            ),
                            child: FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('classes')
                                  .doc(widget.classCode)
                                  .get(),
                              builder: (context, classSnapshot) {
                                final className = classSnapshot.data?.get('className') ?? widget.classCode;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: _AppColors.accent2,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.class_, color: Colors.white, size: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      className,
                                      style: AppFonts.clashGrotesk(
                                        color: _AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const Spacer(),
                          if (widget.isLecturer) ...[
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => AssignmentEditDetailsPage(
                                      classCode: widget.classCode,
                                      assignmentId: widget.assignmentId,
                                    ),
                                  ),
                                );
                              },
                              child: Icon(Icons.edit_outlined, color: _AppColors.textSecondary, size: 22),
                            ),
                            const SizedBox(width: 16),
                            GestureDetector(
                              onTap: _handleDelete,
                              child: Icon(Icons.delete_outline, color: _AppColors.accent1, size: 22),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Assignment Title
                            Text(
                              assignment.title,
                              style: AppFonts.clashGrotesk(
                                color: _AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Assignment Description
                            Text(
                              assignment.description.isNotEmpty 
                                  ? assignment.description 
                                  : 'No description provided.',
                              style: AppFonts.clashGrotesk(
                                color: _AppColors.textSecondary,
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 28),
                            
                            // Info Rows with Dots
                            _buildInfoRow('Date Created', DateFormat('MMMM d, yy; hh:mm a').format(assignment.createdAt)),
                            _buildInfoRow('Deadline', DateFormat('MMMM d, yy; hh:mm a').format(assignment.dueDate)),
                            _buildInfoRow('Assignment Type', assignment.submissionType == 'group' ? 'Group' : 'Individual'),
                            // Status - dynamic for students
                            if (widget.isLecturer)
                              _buildInfoRow('Status', _getStatus(assignment.dueDate))
                            else
                              _buildStudentStatusRow(assignment),
                            
                            const SizedBox(height: 32),
                            
                            // Lecturer's Document (visible to everyone if exists)
                            if (assignment.attachmentUrl != null && assignment.attachmentUrl!.isNotEmpty) ...[
                              GestureDetector(
                                onTap: () => _downloadAndOpenFile(
                                  assignment.attachmentUrl!,
                                  assignment.attachmentName ?? 'document',
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _AppColors.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _AppColors.divider),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: _AppColors.primary.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.description_outlined, color: _AppColors.primary),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              assignment.attachmentName ?? 'Document',
                                              style: AppFonts.clashGrotesk(
                                                color: _AppColors.textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Tap to view',
                                              style: AppFonts.clashGrotesk(
                                                color: _AppColors.primary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.open_in_new, color: _AppColors.primary, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            
                            // Lecturer-only: Upload document section
                            if (widget.isLecturer && (assignment.attachmentUrl == null || assignment.attachmentUrl!.isEmpty)) ...[
                              _buildLecturerUploadSection(),
                              const SizedBox(height: 24),
                            ],
                            
                            // For lecturers: show submissions list
                            // For students: show their submission section
                            if (widget.isLecturer)
                              _buildLecturerSubmissionsSection()
                            else
                              _buildStudentSubmissionSection(assignment),
                              
                            // Extra padding for floating button
                            if (!widget.isLecturer) const SizedBox(height: 100),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Floating button for students
                if (!widget.isLecturer)
                  _buildBottomSubmitButton(assignment),
              ],
            );
          },
        ),
      ),
    );
  }
  
  String _getStatus(DateTime dueDate) {
    final now = DateTime.now();
    if (dueDate.isBefore(now)) {
      return 'Overdue';
    } else {
      final diff = dueDate.difference(now);
      if (diff.inDays == 0) {
        return 'Due Today';
      } else if (diff.inDays == 1) {
        return 'Due Tomorrow';
      } else {
        return 'Due in ${diff.inDays} days';
      }
    }
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppFonts.clashGrotesk(
                color: _AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppFonts.clashGrotesk(
                color: _AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStudentStatusRow(Assignment assignment) {
    return FutureBuilder<Map<String, String>?>(
      future: assignment.submissionType == 'group'
          ? AssignmentService.instance.getStudentGroup(
              widget.classCode, FirebaseAuth.instance.currentUser?.uid ?? '')
          : Future.value(null),
      builder: (context, groupSnapshot) {
        final groupId = groupSnapshot.data?['groupId'];
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        
        if (assignment.submissionType == 'group' && groupId == null) {
          return _buildInfoRow('Status', 'Not in a group');
        }
        
        final submissionIdToCheck = assignment.submissionType == 'group' ? (groupId ?? uid) : uid;
        
        return StreamBuilder<Submission?>(
          stream: AssignmentService.instance.getSubmission(
            widget.classCode, widget.assignmentId, submissionIdToCheck,
          ),
          builder: (context, snapshot) {
            final hasSubmitted = snapshot.data != null;
            
            if (hasSubmitted) {
              // Show "Submitted" in green
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _AppColors.accent2,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: Text(
                        'Status',
                        style: AppFonts.clashGrotesk(
                          color: _AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Submitted',
                        style: AppFonts.clashGrotesk(
                          color: _AppColors.accent2,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // Not submitted - show due date status
            return _buildInfoRow('Status', _getStatus(assignment.dueDate));
          },
        );
      },
    );
  }
  
  Widget _buildLecturerUploadSection() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: _AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _AppColors.divider),
        ),
        child: Column(
          children: [
            if (_isUploading)
              CircularProgressIndicator(color: _AppColors.primary)
            else ...[
              Icon(Icons.cloud_upload_outlined, color: _AppColors.textSecondary, size: 48),
              const SizedBox(height: 12),
              Text(
                'Click to upload assignment document',
                style: AppFonts.clashGrotesk(color: _AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStudentSubmissionSection(Assignment assignment) {
    return FutureBuilder<Map<String, String>?>(
      future: assignment.submissionType == 'group'
          ? AssignmentService.instance.getStudentGroup(
              widget.classCode, FirebaseAuth.instance.currentUser?.uid ?? '')
          : Future.value(null),
      builder: (context, groupSnapshot) {
        if (groupSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _AppColors.primary));
        }

        final groupInfo = groupSnapshot.data;
        final groupId = groupInfo?['groupId'];
        final groupName = groupInfo?['groupName'];
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

        if (assignment.submissionType == 'group' && groupId == null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _AppColors.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: _AppColors.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is a group assignment. You must be in a group to submit.',
                    style: AppFonts.clashGrotesk(color: _AppColors.secondary),
                  ),
                ),
              ],
            ),
          );
        }

        final submissionIdToCheck = assignment.submissionType == 'group' ? groupId! : uid;

        return StreamBuilder<Submission?>(
          stream: AssignmentService.instance.getSubmission(
            widget.classCode, widget.assignmentId, submissionIdToCheck,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _AppColors.primary));
            }
            
            final mySubmission = snapshot.data;
            
            if (mySubmission != null) {
              // Already submitted
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _AppColors.accent2.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _AppColors.accent2.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: _AppColors.accent2, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Submitted',
                            style: AppFonts.clashGrotesk(
                              color: _AppColors.accent2,
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
                              color: _AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // Not submitted - show upload card
            return GestureDetector(
              onTap: _isUploading ? null : () => _pickStudentFile(groupId, groupName),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: _AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _AppColors.divider),
                ),
                child: Column(
                  children: [
                    if (_studentFile != null && _studentFileName != null) ...[
                      // File selected - show file info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.description_outlined, color: _AppColors.primary, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _studentFileName!,
                        style: AppFonts.clashGrotesk(
                          color: _AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to change file',
                        style: AppFonts.clashGrotesk(
                          color: _AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ] else ...[
                      // No file selected - show upload prompt
                      Icon(Icons.cloud_upload_outlined, color: _AppColors.textSecondary, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Click to upload your document',
                        style: AppFonts.clashGrotesk(color: _AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildLecturerSubmissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Submissions',
          style: AppFonts.clashGrotesk(
            color: _AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Submission>>(
          stream: AssignmentService.instance.getSubmissions(widget.classCode, widget.assignmentId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _AppColors.primary));
            }

            final submissions = snapshot.data ?? [];

            if (submissions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text('No submissions yet.', style: AppFonts.clashGrotesk(color: _AppColors.textSecondary)),
                ),
              );
            }

            return Column(
              children: submissions.map((s) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _AppColors.divider),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        s.studentName.isNotEmpty ? s.studentName[0].toUpperCase() : '?',
                        style: TextStyle(color: _AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.studentName, style: AppFonts.clashGrotesk(color: _AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                          Text(
                            s.submittedAt != null ? DateFormat('MMM d, h:mm a').format(s.submittedAt!) : 'Unknown',
                            style: AppFonts.clashGrotesk(color: _AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (s.attachmentUrl != null)
                      GestureDetector(
                        onTap: () => _downloadAndOpenFile(s.attachmentUrl!, s.attachmentName ?? 'submission'),
                        child: Icon(Icons.download_rounded, color: _AppColors.primary),
                      ),
                  ],
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildBottomSubmitButton(Assignment assignment) {
    return FutureBuilder<Map<String, String>?>(
      future: assignment.submissionType == 'group'
          ? AssignmentService.instance.getStudentGroup(
              widget.classCode, FirebaseAuth.instance.currentUser?.uid ?? '')
          : Future.value(null),
      builder: (context, groupSnapshot) {
        final groupInfo = groupSnapshot.data;
        final groupId = groupInfo?['groupId'];
        final groupName = groupInfo?['groupName'];
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        
        if (assignment.submissionType == 'group' && groupId == null) {
          return const SizedBox.shrink();
        }
        
        if (uid.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final submissionIdToCheck = assignment.submissionType == 'group' ? groupId! : uid;
        
        return StreamBuilder<Submission?>(
          stream: AssignmentService.instance.getSubmission(
            widget.classCode, widget.assignmentId, submissionIdToCheck,
          ),
          builder: (context, snapshot) {
            final hasSubmitted = snapshot.data != null;
            
            if (hasSubmitted) {
              return const SizedBox.shrink();
            }
            
            // Floating button - disabled if no file selected
            final bool canSubmit = _studentFile != null && !_isUploading;
            
            return Positioned(
              bottom: 32,
              left: 20,
              right: 20,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: canSubmit ? _submitStudentFile : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canSubmit 
                        ? _AppColors.primary.withValues(alpha: 0.15)
                        : _AppColors.cardBg,
                    foregroundColor: canSubmit 
                        ? _AppColors.primary 
                        : _AppColors.textSecondary,
                    disabledBackgroundColor: _AppColors.cardBg,
                    disabledForegroundColor: _AppColors.textSecondary.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: canSubmit ? _AppColors.primary.withValues(alpha: 0.3) : _AppColors.divider,
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: _isUploading
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _AppColors.primary, strokeWidth: 2))
                      : Text(
                          'Upload',
                          style: AppFonts.clashGrotesk(
                            fontSize: 18, 
                            fontWeight: FontWeight.w600, 
                            color: canSubmit ? _AppColors.primary : _AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
