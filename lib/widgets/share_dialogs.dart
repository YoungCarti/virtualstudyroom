import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

// Helper class to manage sharing
class ShareHelper {
  static Future<void> shareContent({
    required BuildContext context,
    required String title,
    required String content,
    String? type, // 'flashcards', 'quiz', 'notes'
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to share.')),
      );
      return;
    }

    // 1. Select Group
    final selectedGroup = await showDialog<_GroupInfo>(
      context: context,
      builder: (context) => const GroupSelectionDialog(),
    );

    if (selectedGroup == null) return; // Users cancelled

    // 2. Send Message
    try {
      // Create a readable message (fallback)
      final String messageText = "📄 Shared ${type ?? 'Study Material'}: $title";
      
      // Send to Firestore
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(selectedGroup.classCode)
          .collection('groups')
          .doc(selectedGroup.groupId)
          .collection('messages')
          .add({
        'text': messageText,
        'senderId': user.uid,
        'senderName': user.displayName ?? 'Unknown',
        'type': 'text', // We use 'text' type but with 'isSharedContent' flag
        'createdAt': FieldValue.serverTimestamp(),
        'isSharedContent': true,
        'contentTitle': title,
        'contentType': type,
        'sharedData': content, // Store the raw content here
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shared to ${selectedGroup.groupName}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing: $e')),
        );
      }
    }
  }
}

class _GroupInfo {
  final String classCode;
  final String groupId;
  final String groupName;

  _GroupInfo(this.classCode, this.groupId, this.groupName);
}

class GroupSelectionDialog extends StatefulWidget {
  const GroupSelectionDialog({super.key});

  @override
  State<GroupSelectionDialog> createState() => _GroupSelectionDialogState();
}

class _GroupSelectionDialogState extends State<GroupSelectionDialog> {
  bool _isLoading = true;
  final List<_GroupInfo> _groups = [];
  StreamSubscription? _userSubscription;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  void _fetchGroups() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Listen to user's enrolled classes
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((userSnap) async {
      if (!mounted) return;
      
      final enrolled = List<String>.from(userSnap.data()?['enrolledClasses'] ?? []);
      
      final loadedGroups = <_GroupInfo>[];
      
      // For each class, fetch groups where user is a member
      for (final classCode in enrolled) {
        final groupsSnap = await FirebaseFirestore.instance
            .collection('classes')
            .doc(classCode)
            .collection('groups')
            .get();

        for (final doc in groupsSnap.docs) {
          final members = List<String>.from(doc.data()['members'] ?? []);
          if (members.contains(uid)) {
            loadedGroups.add(_GroupInfo(
              classCode,
              doc.id,
              doc.data()['groupName'] ?? 'Unnamed Group',
            ));
          }
        }
      }

      if (mounted) {
        setState(() {
          _groups.clear();
          _groups.addAll(loadedGroups);
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0D1117),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Share to Group',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          SizedBox(
            height: 300,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _groups.isEmpty
                    ? Center(
                        child: Text(
                          'No groups found.',
                          style: GoogleFonts.outfit(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _groups.length,
                        itemBuilder: (context, index) {
                          final group = _groups[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent.withOpacity(0.2),
                              child: Text(
                                group.groupName[0].toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              group.groupName,
                              style: GoogleFonts.outfit(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Class: ${group.classCode}',
                              style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                            ),
                            onTap: () => Navigator.pop(context, group),
                          );
                        },
                      ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }
}
