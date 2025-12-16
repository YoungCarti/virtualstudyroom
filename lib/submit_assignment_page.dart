import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'assignment_service.dart';

class SubmitAssignmentPage extends StatefulWidget {
  const SubmitAssignmentPage({
    super.key,
    required this.classCode,
    required this.assignmentId,
    this.groupId,
    this.groupName,
  });

  final String classCode;
  final String assignmentId;
  final String? groupId;
  final String? groupName;

  @override
  State<SubmitAssignmentPage> createState() => _SubmitAssignmentPageState();
}

class _SubmitAssignmentPageState extends State<SubmitAssignmentPage> {
  // File handling
  File? _selectedFile; // For mobile
  Uint8List? _selectedFileBytes; // For web
  String? _selectedFileName;

  bool _isLoading = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: kIsWeb, // Important for web
      );

      if (result != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          if (kIsWeb) {
            _selectedFileBytes = result.files.single.bytes;
          } else {
            _selectedFile = File(result.files.single.path!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to submit')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await AssignmentService.instance.submitAssignment(
        classCode: widget.classCode,
        assignmentId: widget.assignmentId,
        studentId: user.uid,
        studentName: user.displayName ?? 'Unknown Student',
        file: _selectedFile,
        fileBytes: _selectedFileBytes,
        fileName: _selectedFileName,
        groupId: widget.groupId,
        groupName: widget.groupName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit assignment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Assignment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload your work',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.groupName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Submitting for group: ${widget.groupName}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Please select the file you want to submit for this assignment.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // File Upload
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.grey[300]!,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  if (_selectedFileName != null) ...[
                    Icon(Icons.insert_drive_file, size: 48, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      _selectedFileName!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedFile = null;
                          _selectedFileBytes = null;
                          _selectedFileName = null;
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Remove File', style: TextStyle(color: Colors.red)),
                    ),
                  ] else ...[
                    Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'Tap to browse files',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: _pickFile,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Choose File'),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Submit Assignment', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
