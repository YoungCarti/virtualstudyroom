import 'app_fonts.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'assignment_details_page.dart';
import 'create_assignment_page.dart';
import 'group_details.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'assignment_service.dart';


// Ocean Sunset Color Scheme
class _AppColors {
  static const background = Color(0xFF0A1929);    // Deep Navy
  static const primary = Color(0xFF2196F3);       // Electric Blue
  static const accent1 = Color(0xFFFF6B6B);       // Coral
  static const accent2 = Color(0xFF4ECDC4);       // Mint
  static const secondary = Color(0xFFFFB347);     // Soft Orange
  static const cardBg = Color(0xFF0D2137);        // Slightly lighter navy
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF90A4AE);
  static const divider = Color(0xFF1E3A5F);
}

class ClassDetailsPage extends StatefulWidget {
  const ClassDetailsPage({
    super.key,
    required this.classCode,
    required this.className,
    this.isLecturer = false,
  });

  final String classCode;
  final String className;
  final bool isLecturer;

  @override
  State<ClassDetailsPage> createState() => _ClassDetailsPageState();
}

class _ClassDetailsPageState extends State<ClassDetailsPage> {
  // Material Upload State
  File? _selectedFile;
  String? _selectedFileName;
  bool _isUploading = false;
  
  // Expanded states for materials
  final Map<int, bool> _expandedMaterials = {};
  
  Future<void> _pickFile(StateSetter setModalState) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );
      if (result != null && result.files.single.path != null) {
        setModalState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  Future<void> _uploadMaterial(String title, String note) async {
    if (_selectedFile == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      final fileName = _selectedFileName ?? 'file';
      final ref = FirebaseStorage.instance
          .ref().child('class_materials').child(widget.classCode)
          .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
      
      await ref.putFile(_selectedFile!);
      final fileUrl = await ref.getDownloadURL();
      
      await FirebaseFirestore.instance
          .collection('classes').doc(widget.classCode)
          .collection('materials').add({
        'title': title,
        'note': note,
        'fileUrl': fileUrl,
        'fileName': fileName,
        'uploadedAt': FieldValue.serverTimestamp(),
        'uploadedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material uploaded successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() {
        _isUploading = false;
        _selectedFile = null;
        _selectedFileName = null;
      });
    }
  }

  Future<void> _deleteMaterial(String docId, String fileUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _StyledDialog(
        title: 'Delete Material?',
        content: Text(
          'This will permanently delete the file.',
          style: AppFonts.clashGrotesk(color: _AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: _AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _AppColors.accent1),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      try {
        await FirebaseStorage.instance.refFromURL(fileUrl).delete();
      } catch (e) {
        debugPrint("Storage delete failed (might be missing): $e");
      }

      await FirebaseFirestore.instance
          .collection('classes').doc(widget.classCode)
          .collection('materials').doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _showAddMaterialDialog() async {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => _StyledDialog(
          title: 'Add Material',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StyledTextField(controller: titleCtrl, hintText: 'Title (e.g., Week 1 Slides)'),
              const SizedBox(height: 12),
              _StyledTextField(controller: noteCtrl, hintText: 'Note (Optional)'),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _pickFile(setModalState),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file, color: _selectedFile != null ? _AppColors.accent2 : _AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedFileName ?? 'Attach PDF or Word',
                          style: TextStyle(color: _selectedFile != null ? _AppColors.textPrimary : _AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isUploading) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(color: _AppColors.primary),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isUploading ? null : () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: _AppColors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _AppColors.primary),
              onPressed: _isUploading 
                  ? null 
                  : () async {
                      if (titleCtrl.text.isEmpty || _selectedFile == null) return;
                      await _uploadMaterial(titleCtrl.text.trim(), noteCtrl.text.trim());
                      if (context.mounted) Navigator.pop(context);
                    },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAndOpenMaterial(BuildContext context, String fileUrl, String fileName) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator(color: _AppColors.primary)),
      );

      final response = await http.get(Uri.parse(fileUrl));
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      if (context.mounted) Navigator.pop(context);

      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: ${result.message}')));
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
      }
    }
  }

  Future<void> _leaveClass() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _StyledDialog(
        title: 'Leave Class?',
        content: Text(
          'Are you sure you want to leave ${widget.className}?',
          style: AppFonts.clashGrotesk(color: _AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: _AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _AppColors.accent1),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'enrolledClasses': FieldValue.arrayRemove([widget.classCode]),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the class.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving class: $e')),
        );
      }
    }
  }

  Future<void> _deleteClass() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _StyledDialog(
        title: 'Delete Class?',
        content: Text(
          'This action cannot be undone. All data will be removed.',
          style: AppFonts.clashGrotesk(color: _AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: _AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _AppColors.accent1),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classCode)
          .delete();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'enrolledClasses': FieldValue.arrayRemove([widget.classCode]),
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class deleted successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting class: $e')),
        );
      }
    }
  }

  Future<void> _showCreateGroupDialog() async {
    final groupNameCtrl = TextEditingController();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    await showDialog<void>(
      context: context,
      builder: (ctx) => _StyledDialog(
        title: 'Create Group',
        content: _StyledTextField(
          controller: groupNameCtrl,
          hintText: 'Group name (e.g., Group A)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _AppColors.primary),
            onPressed: uid == null
                ? null
                : () async {
                    final groupName = groupNameCtrl.text.trim();
                    if (groupName.isEmpty) return;

                    try {
                      final groupRef = FirebaseFirestore.instance
                          .collection('classes')
                          .doc(widget.classCode)
                          .collection('groups')
                          .doc(groupName);

                      await groupRef.set({
                        'groupName': groupName,
                        'members': [uid],
                        'createdAt': FieldValue.serverTimestamp(),
                        'createdBy': uid,
                      });

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Group "$groupName" created')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      }
                    }
                  },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinGroupDialog() async {
    final groupCodeCtrl = TextEditingController();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    await showDialog<void>(
      context: context,
      builder: (ctx) => _StyledDialog(
        title: 'Join Group',
        content: _StyledTextField(
          controller: groupCodeCtrl,
          hintText: 'Enter group name',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _AppColors.textSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _AppColors.primary),
            onPressed: uid == null
                ? null
                : () async {
                    final groupName = groupCodeCtrl.text.trim();
                    if (groupName.isEmpty) return;

                    try {
                      final groupsSnapshot = await FirebaseFirestore.instance
                          .collection('classes')
                          .doc(widget.classCode)
                          .collection('groups')
                          .get();

                      final matchingGroups = groupsSnapshot.docs.where((doc) {
                        final docGroupName = doc.data()['groupName'] as String?;
                        return docGroupName?.toLowerCase() == groupName.toLowerCase();
                      }).toList();

                      if (matchingGroups.isEmpty) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Group not found')),
                          );
                        }
                        return;
                      }

                      final groupDoc = matchingGroups.first;
                      final members = List<String>.from(groupDoc.data()['members'] ?? []);

                      if (members.contains(uid)) {
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('You are already in this group')),
                          );
                        }
                        return;
                      }

                      await groupDoc.reference.update({
                        'members': FieldValue.arrayUnion([uid]),
                      });

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Joined group "${groupDoc.data()['groupName']}"')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to join group: $e')),
                        );
                      }
                    }
                  },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Simple App Bar with back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    ),
                  ),
                  const Spacer(),
                  // Action button (leave/delete)
                  if (uid != null)
                    GestureDetector(
                      onTap: widget.isLecturer ? _deleteClass : _leaveClass,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          widget.isLecturer ? Icons.delete_outline : Icons.exit_to_app,
                          color: _AppColors.accent1,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Class Header with Icon
                    _buildClassHeader(),
                    
                    const SizedBox(height: 24),
                    
                    // About This Class Section
                    _buildAboutSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Lecturer Section
                    _buildLecturerSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Groups Section
                    _buildGroupsSection(uid),
                    
                    const SizedBox(height: 24),
                    
                    // Materials Section
                    _buildMaterialsSection(),
                    
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Bottom View Assignments Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: _AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _ClassAssignmentsPage(
                  classCode: widget.classCode,
                  className: widget.className,
                  isLecturer: widget.isLecturer,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            'View Assignments',
            style: AppFonts.clashGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassHeader() {
    return Row(
      children: [
        // Class Icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_AppColors.secondary, _AppColors.accent1],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              widget.className.isNotEmpty ? widget.className[0].toUpperCase() : '?',
              style: AppFonts.clashGrotesk(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.className,
                style: AppFonts.clashGrotesk(
                  color: _AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.classCode,
                style: AppFonts.clashGrotesk(
                  color: _AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classCode)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final description = data['description'] as String? ?? 
            'Welcome to ${widget.className}. This class covers essential topics and learning materials for students enrolled in the course.';
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About this class',
              style: AppFonts.clashGrotesk(
                color: _AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: AppFonts.clashGrotesk(
                color: _AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLecturerSection() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classCode)
          .snapshots(),
      builder: (context, classSnapshot) {
        final classData = classSnapshot.data?.data() ?? {};
        final lecturerId = classData['lecturerId'] as String?;
        
        if (lecturerId == null) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lecturer',
              style: AppFonts.clashGrotesk(
                color: _AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance.collection('users').doc(lecturerId).get(),
              builder: (context, userSnapshot) {
                final userData = userSnapshot.data?.data() ?? {};
                final name = userData['name'] ?? userData['fullName'] ?? 'Lecturer';
                final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          initial,
                          style: AppFonts.clashGrotesk(
                            color: _AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  name,
                                  style: AppFonts.clashGrotesk(
                                    color: _AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.verified,
                                  color: _AppColors.primary,
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Course Lecturer',
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
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupsSection(String? uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Groups',
              style: AppFonts.clashGrotesk(
                color: _AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (uid != null)
              PopupMenuButton<String>(
                color: _AppColors.cardBg,
                icon: Icon(Icons.more_horiz, color: _AppColors.textSecondary),
                onSelected: (value) {
                  if (value == 'create') _showCreateGroupDialog();
                  else if (value == 'join') _showJoinGroupDialog();
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: 'create',
                    child: Row(children: [
                      Icon(Icons.add, color: _AppColors.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text('Create Group', style: TextStyle(color: _AppColors.textPrimary))
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'join',
                    child: Row(children: [
                      Icon(Icons.login, color: _AppColors.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text('Join Group', style: TextStyle(color: _AppColors.textPrimary))
                    ]),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (uid == null)
          Text('Sign in to view groups.', style: AppFonts.clashGrotesk(color: _AppColors.textSecondary))
        else
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classCode)
                .collection('groups')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: _AppColors.primary));
              }
              if (!snapshot.hasData) {
                return Text('No groups yet.', style: AppFonts.clashGrotesk(color: _AppColors.textSecondary));
              }
              final groups = snapshot.data!.docs
                  .where((doc) => doc.id != '_placeholder')
                  .toList();

              if (groups.isEmpty) {
                return Text('No groups yet.', style: AppFonts.clashGrotesk(color: _AppColors.textSecondary));
              }
              
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final groupData = groups[i].data();
                  final groupId = groups[i].id;
                  final groupName = groupData['groupName'] ?? groupId;
                  final members = List<String>.from(groupData['members'] ?? []);
                  final isMember = members.contains(uid);

                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => GroupDetailsPage(
                            classCode: widget.classCode,
                            groupId: groupId,
                            groupName: groupName,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.groups_rounded, color: isMember ? _AppColors.accent2 : _AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  groupName,
                                  style: AppFonts.clashGrotesk(color: _AppColors.textPrimary, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${members.length} members',
                                  style: AppFonts.clashGrotesk(color: _AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (!isMember)
                            GestureDetector(
                              onTap: () {
                                FirebaseFirestore.instance
                                    .collection('classes').doc(widget.classCode)
                                    .collection('groups').doc(groupId)
                                    .update({'members': FieldValue.arrayUnion([uid])});
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Joined $groupName')));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _AppColors.primary.withValues(alpha: 0.4)),
                                ),
                                child: Text('Join', style: AppFonts.clashGrotesk(color: _AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            )
                          else
                            Icon(Icons.check_circle, color: _AppColors.accent2, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildMaterialsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Materials',
              style: AppFonts.clashGrotesk(
                color: _AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes').doc(widget.classCode)
                  .collection('materials')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.docs
                    .where((d) => d.id != '_placeholder')
                    .length ?? 0;
                return Text(
                  '$count materials',
                  style: AppFonts.clashGrotesk(
                    color: _AppColors.textSecondary,
                    fontSize: 13,
                  ),
                );
              },
            ),
          ],
        ),
        if (widget.isLecturer) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showAddMaterialDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_file, color: _AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Upload',
                    style: AppFonts.clashGrotesk(
                      color: _AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes').doc(widget.classCode)
              .collection('materials')
              .orderBy('uploadedAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _AppColors.primary));
            }
            if (!snapshot.hasData) {
              return Text('No materials uploaded yet.', style: AppFonts.clashGrotesk(color: _AppColors.textSecondary));
            }
            final docs = snapshot.data!.docs
                .where((doc) => doc.id != '_placeholder')
                .toList();

            if (docs.isEmpty) {
              return Text('No materials uploaded yet.', style: AppFonts.clashGrotesk(color: _AppColors.textSecondary));
            }
            
            return Column(
              children: docs.asMap().entries.map((entry) {
                final index = entry.key;
                final doc = entry.value;
                final data = doc.data() as Map<String, dynamic>;
                final isExpanded = _expandedMaterials[index] ?? false;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedMaterials[index] = !isExpanded;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _AppColors.secondary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.description_outlined, color: _AppColors.secondary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title'] ?? 'Untitled',
                                      style: AppFonts.clashGrotesk(
                                        color: _AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (data['note'] != null && data['note'].toString().isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        data['note'],
                                        style: AppFonts.clashGrotesk(
                                          color: _AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: _AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _downloadAndOpenMaterial(context, data['fileUrl'], data['fileName'] ?? 'document'),
                                  icon: Icon(Icons.download, size: 18, color: _AppColors.primary),
                                  label: Text('Open', style: TextStyle(color: _AppColors.primary)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: _AppColors.primary.withValues(alpha: 0.5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              if (widget.isLecturer) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _deleteMaterial(doc.id, data['fileUrl']),
                                  icon: Icon(Icons.delete_outline, color: _AppColors.accent1),
                                  style: IconButton.styleFrom(
                                    backgroundColor: _AppColors.accent1.withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// --- CLASS ASSIGNMENTS PAGE ---

class _ClassAssignmentsPage extends StatelessWidget {
  final String classCode;
  final String className;
  final bool isLecturer;
  
  const _ClassAssignmentsPage({
    required this.classCode,
    required this.className,
    required this.isLecturer,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      appBar: AppBar(
        backgroundColor: _AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$className - Assignments',
          style: AppFonts.clashGrotesk(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (isLecturer)
            IconButton(
              icon: Icon(Icons.add, color: _AppColors.primary),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CreateAssignmentPage(classCode: classCode),
                  ),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<List<Assignment>>(
        stream: AssignmentService.instance.getAssignmentsForClass(classCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _AppColors.primary));
          }
          
          final assignments = (snapshot.data ?? [])
              .where((a) => a.id != '_placeholder')
              .toList();
          
          if (assignments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, color: _AppColors.textSecondary, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'No assignments yet',
                    style: AppFonts.clashGrotesk(color: _AppColors.textSecondary, fontSize: 16),
                  ),
                  if (isLecturer) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => CreateAssignmentPage(classCode: classCode),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create Assignment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: assignments.length,
            itemBuilder: (context, index) {
              final a = assignments[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AssignmentDetailsPage(
                          classCode: classCode,
                          assignmentId: a.id,
                          isLecturer: isLecturer,
                        ),
                      ),
                    );
                  },
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
                            color: _AppColors.accent2.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.assignment_outlined, color: _AppColors.accent2),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: AppFonts.clashGrotesk(
                                  color: _AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Due: ${DateFormat('MMM d, yyyy').format(a.dueDate)}',
                                style: AppFonts.clashGrotesk(
                                  color: _AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: _AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- STYLED WIDGETS ---

class _StyledDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const _StyledDialog({required this.title, required this.content, required this.actions});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _AppColors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _AppColors.divider),
      ),
      title: Text(title, style: AppFonts.clashGrotesk(color: _AppColors.textPrimary)),
      content: content,
      actions: actions,
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _StyledTextField({required this.controller, required this.hintText});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _AppColors.divider),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: _AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: _AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}