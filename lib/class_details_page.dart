import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'assignment_details_page.dart';
import 'group_details.dart';

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
  // Temporary sample data for testing
  List<Map<String, String>> get _assignments => [
        {'id': 'assignment1', 'title': 'Assignment 1', 'due': 'Due: Jan 15'},
        {'id': 'assignment2', 'title': 'Project Proposal', 'due': 'Due: Jan 25'},
      ];

  List<Map<String, String>> get _materials => [
        {'title': 'Syllabus.pdf', 'note': 'Course overview'},
        {'title': 'Week1 Slides', 'note': 'Intro lecture'},
      ];

  Future<void> _showCreateGroupDialog() async {
    final groupNameCtrl = TextEditingController();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF33264a),
        title: const Text('Create Group', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: groupNameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Group name (e.g., Group A)',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFa855f7)),
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
                          SnackBar(content: Text('Failed to create group: $e')),
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
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF33264a),
        title: const Text('Join Group', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: groupCodeCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Enter group name',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFa855f7)),
            onPressed: uid == null
                ? null
                : () async {
                    final groupName = groupCodeCtrl.text.trim();
                    if (groupName.isEmpty) return;

                    try {
                      final groupRef = FirebaseFirestore.instance
                          .collection('classes')
                          .doc(widget.classCode)
                          .collection('groups')
                          .doc(groupName);

                      final groupDoc = await groupRef.get();
                      if (!groupDoc.exists) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Group not found')),
                          );
                        }
                        return;
                      }

                      await groupRef.update({
                        'members': FieldValue.arrayUnion([uid]),
                      });

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Joined group "$groupName"')),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.className),
            Text(
              widget.classCode,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
            ),
          ],
        ),
        centerTitle: false,
        toolbarHeight: 72,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assignments', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_assignments.isEmpty)
              const Text('No assignments yet.')
            else
              ..._assignments.map((a) => InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => AssignmentDetailsPage(
                            classCode: widget.classCode,
                            assignmentId: a['id'] ?? '',
                            isLecturer: widget.isLecturer,
                          ),
                        ),
                      );
                    },
                    child: _CardTile(
                      title: a['title'] ?? '',
                      subtitle: a['due'] ?? '',
                      icon: Icons.assignment_outlined,
                      isDark: isDark,
                    ),
                  )),
            const SizedBox(height: 24),

            // Groups section (from Firebase)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Groups', style: Theme.of(context).textTheme.titleLarge),
                if (uid != null)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'create') {
                        _showCreateGroupDialog();
                      } else if (value == 'join') {
                        _showJoinGroupDialog();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'create',
                        child: Row(
                          children: [
                            Icon(Icons.add, size: 20),
                            SizedBox(width: 8),
                            Text('Create Group'),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'join',
                        child: Row(
                          children: [
                            Icon(Icons.login, size: 20),
                            SizedBox(width: 8),
                            Text('Join Group'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (uid == null)
              const Text('Sign in to view groups.')
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
                    return const Text('No groups yet.');
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
                      final members = List<String>.from(groupData['members'] ?? <dynamic>[]);
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
                              Icon(
                                Icons.groups_rounded,
                                color: isMember ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      groupName,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${members.length} members',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: isDark ? Colors.white60 : Colors.black54,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isMember)
                                Chip(
                                  label: const Text('Join'),
                                  onDeleted: () {
                                    FirebaseFirestore.instance
                                        .collection('classes')
                                        .doc(widget.classCode)
                                        .collection('groups')
                                        .doc(groupId)
                                        .update({
                                      'members': FieldValue.arrayUnion([uid]),
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Joined $groupName')),
                                    );
                                  },
                                )
                              else
                                const Icon(Icons.check_circle, color: Colors.green),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 24),

            Text('Materials', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_materials.isEmpty)
              const Text('No materials yet.')
            else
              ..._materials.map((m) => _CardTile(
                    title: m['title'] ?? '',
                    subtitle: m['note'] ?? '',
                    icon: Icons.description_outlined,
                    isDark: isDark,
                  )),
          ],
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}