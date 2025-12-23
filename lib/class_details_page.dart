import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'assignment_details_page.dart';
import 'create_assignment_page.dart';
import 'group_details.dart';
import 'assignment_service.dart';

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
  // Temporary sample data
  List<Map<String, String>> get _materials => [
        {'title': 'Syllabus.pdf', 'note': 'Course overview'},
        {'title': 'Week1 Slides', 'note': 'Intro lecture'},
      ];

  // Logic to Leave Class (Student)
  Future<void> _leaveClass() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: 'Leave Class?',
        content: Text(
          'Are you sure you want to leave ${widget.className}?',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)), // Red
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

  // Logic to Delete Class (Lecturer)
  Future<void> _deleteClass() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _GlassDialog(
        title: 'Delete Class?',
        content: Text(
          'This action cannot be undone. All data will be removed.',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF43F5E)),
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
      builder: (ctx) => _GlassDialog(
        title: 'Create Group',
        content: _GlassTextField(
          controller: groupNameCtrl,
          hintText: 'Group name (e.g., Group A)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFA855F7)),
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
      builder: (ctx) => _GlassDialog(
        title: 'Join Group',
        content: _GlassTextField(
          controller: groupCodeCtrl,
          hintText: 'Enter group name',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFA855F7)),
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
            left: -50,
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
            right: -80,
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

          // 3. Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.chevron_left,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.className,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              widget.classCode,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _GlassIconButton(
                        icon: widget.isLecturer ? Icons.delete_outline : Icons.exit_to_app,
                        iconColor: const Color(0xFFF43F5E), // Red
                        onTap: widget.isLecturer ? _deleteClass : _leaveClass,
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Assignments Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Assignments',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.isLecturer)
                              _GlassSmallButton(
                                label: 'Create',
                                icon: Icons.add,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => CreateAssignmentPage(
                                        classCode: widget.classCode,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (uid == null)
                          Text('Sign in to view assignments.', style: GoogleFonts.inter(color: Colors.white54))
                        else
                          StreamBuilder<List<Assignment>>(
                            stream: AssignmentService.instance.getAssignmentsForClass(widget.classCode),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final assignments = snapshot.data ?? [];
                              if (assignments.isEmpty) {
                                return Text('No assignments yet.', style: GoogleFonts.inter(color: Colors.white54));
                              }
                              return Column(
                                children: assignments
                                    .map((a) => InkWell(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) => AssignmentDetailsPage(
                                                  classCode: widget.classCode,
                                                  assignmentId: a.id,
                                                  isLecturer: widget.isLecturer,
                                                ),
                                              ),
                                            );
                                          },
                                          child: _CardTile(
                                            title: a.title,
                                            subtitle: 'Due: ${DateFormat('MMM d').format(a.dueDate)}',
                                            icon: Icons.assignment_outlined,
                                            iconColor: const Color(0xFF22D3EE),
                                          ),
                                        ))
                                    .toList(),
                              );
                            },
                          ),

                        const SizedBox(height: 32),

                        // Groups Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Groups',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (uid != null)
                              PopupMenuButton<String>(
                                color: const Color(0xFF2d2140),
                                icon: const Icon(Icons.more_horiz, color: Colors.white),
                                onSelected: (value) {
                                  if (value == 'create') _showCreateGroupDialog();
                                  else if (value == 'join') _showJoinGroupDialog();
                                },
                                itemBuilder: (BuildContext context) => [
                                  PopupMenuItem(
                                    value: 'create',
                                    child: Row(children: const [
                                      Icon(Icons.add, color: Colors.white70, size: 18),
                                      SizedBox(width: 8),
                                      Text('Create Group', style: TextStyle(color: Colors.white))
                                    ]),
                                  ),
                                  PopupMenuItem(
                                    value: 'join',
                                    child: Row(children: const [
                                      Icon(Icons.login, color: Colors.white70, size: 18),
                                      SizedBox(width: 8),
                                      Text('Join Group', style: TextStyle(color: Colors.white))
                                    ]),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (uid == null)
                          Text('Sign in to view groups.', style: GoogleFonts.inter(color: Colors.white54))
                        else
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('classes')
                                .doc(widget.classCode)
                                .collection('groups')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return Text('No groups yet.', style: GoogleFonts.inter(color: Colors.white54));
                              }
                              final groups = snapshot.data!.docs;
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
                                    child: _GlassContainer(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Icon(Icons.groups_rounded, color: isMember ? const Color(0xFF10B981) : Colors.white54),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  groupName,
                                                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                                                ),
                                                Text(
                                                  '${members.length} members',
                                                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
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
                                                  color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
                                                ),
                                                child: Text('Join', style: GoogleFonts.inter(color: const Color(0xFFA855F7), fontSize: 12, fontWeight: FontWeight.bold)),
                                              ),
                                            )
                                          else
                                            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                        const SizedBox(height: 32),

                        // Materials Section
                        Text('Materials', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        if (_materials.isEmpty)
                          Text('No materials yet.', style: GoogleFonts.inter(color: Colors.white54))
                        else
                          ..._materials.map((m) => _CardTile(
                                title: m['title'] ?? '',
                                subtitle: m['note'] ?? '',
                                icon: Icons.description_outlined,
                                iconColor: const Color(0xFFF59E0B), // Amber
                              )),
                      ],
                    ),
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

// --- WIDGET HELPERS ---

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassContainer({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _CardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: _GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3), size: 20),
          ],
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
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _GlassSmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GlassSmallButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFA855F7).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFA855F7), size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFFA855F7),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const _GlassDialog({required this.title, required this.content, required this.actions});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: const Color(0xFF0F0F1A).withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Text(title, style: GoogleFonts.inter(color: Colors.white)),
        content: content,
        actions: actions,
      ),
    );
  }
}

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
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}