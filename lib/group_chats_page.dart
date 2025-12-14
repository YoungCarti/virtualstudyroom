import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'group_chat_messages_page.dart';

const Color _primaryPurple = Color(0xFFa855f7);
const Color _secondaryPurple = Color(0xFFec4899);

class GroupChatsPage extends StatelessWidget {
  const GroupChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF7C3AED).withValues(alpha: 0.1),
              const Color(0xFFC026D3).withValues(alpha: 0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Group Chats',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  'Your Groups',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Show all groups from all enrolled classes
                if (uid != null)
                  _AllGroupsList(uid: uid)
                else
                  const _EmptyState(message: 'Sign in to see your groups.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllGroupsList extends StatelessWidget {
  const _AllGroupsList({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    // First, get all enrolled classes for the user
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        if (userSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!userSnap.hasData || !userSnap.data!.exists) {
          return const _EmptyState(message: 'User data not found.');
        }

        final enrolledClasses = List<String>.from(
          userSnap.data!.data()?['enrolledClasses'] ?? <dynamic>[],
        );

        if (enrolledClasses.isEmpty) {
          return const _EmptyState(message: 'You are not enrolled in any classes.');
        }

        // Now fetch all groups from all enrolled classes
        return StreamBuilder<List<_GroupWithClass>>(
          stream: _getGroupsFromClasses(enrolledClasses, uid),
          builder: (context, groupSnap) {
            if (groupSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final groups = groupSnap.data ?? [];

            if (groups.isEmpty) {
              return const _EmptyState(message: 'You are not in any groups yet.');
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final group = groups[index];
                return _GroupCard(
                  classCode: group.classCode,
                  groupId: group.groupId,
                  groupName: group.groupName,
                  memberCount: group.memberCount,
                );
              },
            );
          },
        );
      },
    );
  }

  Stream<List<_GroupWithClass>> _getGroupsFromClasses(
    List<String> classIds,
    String uid,
  ) async* {
    final allGroups = <_GroupWithClass>[];

    for (final classCode in classIds) {
      final groupSnap = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classCode)
          .collection('groups')
          .get();

      for (final doc in groupSnap.docs) {
        final data = doc.data();
        final members = List<String>.from(data['members'] ?? <dynamic>[]);

        // Only include groups the user is a member of
        if (members.contains(uid)) {
          allGroups.add(
            _GroupWithClass(
              classCode: classCode,
              groupId: doc.id,
              groupName: data['groupName'] ?? 'Unnamed Group',
              memberCount: members.length,
            ),
          );
        }
      }
    }

    yield allGroups;
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.classCode,
    required this.groupId,
    required this.groupName,
    required this.memberCount,
  });

  final String classCode;
  final String groupId;
  final String groupName;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF33264a),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.forum_rounded, color: _primaryPurple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$memberCount members',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      classCode,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GroupChatMessagesPage(
                      classCode: classCode,
                      groupId: groupId,
                      groupName: groupName,
                    ),
                  ),
                );
              },
              child: const Text(
                'Open Chat',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupWithClass {
  _GroupWithClass({
    required this.classCode,
    required this.groupId,
    required this.groupName,
    required this.memberCount,
  });
  final String classCode;
  final String groupId;
  final String groupName;
  final int memberCount;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}