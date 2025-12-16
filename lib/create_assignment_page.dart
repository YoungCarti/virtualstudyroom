import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'assignment_service.dart';

class CreateAssignmentPage extends StatefulWidget {
  const CreateAssignmentPage({
    super.key,
    required this.classCode,
  });

  final String classCode;

  @override
  State<CreateAssignmentPage> createState() => _CreateAssignmentPageState();
}

class _CreateAssignmentPageState extends State<CreateAssignmentPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dueDate;
  
  // File handling
  File? _selectedFile; // For mobile
  Uint8List? _selectedFileBytes; // For web
  String? _selectedFileName;
  String _submissionType = 'individual';

  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

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
    if (_titleCtrl.text.isEmpty || _dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and due date')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);

    try {
      await AssignmentService.instance.createAssignment(
        classCode: widget.classCode,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dueDate: _dueDate!,
        createdBy: uid,
        file: _selectedFile,
        fileBytes: _selectedFileBytes,
        fileName: _selectedFileName,
        submissionType: _submissionType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create assignment: $e')),
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
        title: const Text('Create Assignment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Assignment Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Due Date Picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _dueDate = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      _dueDate == null
                          ? 'Select Due Date'
                          : DateFormat('MMM d, yyyy').format(_dueDate!),
                      style: TextStyle(
                        color: _dueDate == null ? Colors.grey : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submission Type Dropdown
            DropdownButtonFormField<String>(
              value: _submissionType,
              decoration: const InputDecoration(
                labelText: 'Submission Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'individual', child: Text('Individual Submission')),
                DropdownMenuItem(value: 'group', child: Text('Group Submission')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _submissionType = val);
              },
            ),
            const SizedBox(height: 24),

            // File Upload
            const Text(
              'Attachment (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E2E) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  if (_selectedFileName != null) ...[
                    Icon(Icons.insert_drive_file, size: 40, color: Theme.of(context).primaryColor),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFileName!,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedFile = null;
                          _selectedFileBytes = null;
                          _selectedFileName = null;
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('Remove', style: TextStyle(color: Colors.red)),
                    ),
                  ] else ...[
                    const Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('Tap to upload a file'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _pickFile,
                      child: const Text('Choose File'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Create Assignment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
