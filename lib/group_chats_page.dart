import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'group_chat_messages_page.dart';
import 'widgets/gradient_background.dart';

const Color _primaryPurple = Color(0xFFa855f7);
const Color _secondaryPurple = Color(0xFFec4899);

class GroupChatsPage extends StatelessWidget {
  const GroupChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Material(
      type: MaterialType.transparency,
      child: GradientBackground(
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _PageTitle(),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Your Groups'),
                const SizedBox(height: 16),
                uid != null
                    ? _AllGroupsList(uid: uid)
                    : const _EmptyState(message: 'Sign in to see your groups.'),
              ],
            ),
          ),
        ),
      ),
    );
  }


}

/* ----------------------------- GROUP LIST ----------------------------- */

class _AllGroupsList extends StatelessWidget {
  const _AllGroupsList({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
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
          userSnap.data!.data()?['enrolledClasses'] ?? [],
        );

        if (enrolledClasses.isEmpty) {
          return const _EmptyState(message: 'You are not enrolled in any classes.');
        }

        return StreamBuilder<List<_GroupWithClass>>(
          stream: _loadUserGroups(enrolledClasses, uid),
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
                return _GroupCard(group: group);
              },
            );
          },
        );
      },
    );
  }

  Stream<List<_GroupWithClass>> _loadUserGroups(
    List<String> classCodes,
    String uid,
  ) async* {
    final result = <_GroupWithClass>[];

    for (final classCode in classCodes) {
      final snapshot = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classCode)
          .collection('groups')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final members = List<String>.from(data['members'] ?? []);

        if (members.contains(uid)) {
          result.add(
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

    yield result;
  }
}

/* ----------------------------- GROUP CARD ----------------------------- */

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final _GroupWithClass group;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GroupHeader(group: group),
          const SizedBox(height: 18),
          _OpenChatButton(group: group),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF33264a),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final _GroupWithClass group;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconContainer(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.groupName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              _MemberCount(count: group.memberCount),
              const SizedBox(height: 4),
              Text(
                group.classCode,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpenChatButton extends StatelessWidget {
  const _OpenChatButton({required this.group});

  final _GroupWithClass group;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryPurple,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupChatMessagesPage(
                classCode: group.classCode,
                groupId: group.groupId,
                groupName: group.groupName,
              ),
            ),
          );
        },
        child: const Text(
          'Open Chat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- UI PARTS ----------------------------- */

class _IconContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _primaryPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.forum_rounded, color: _primaryPurple),
    );
  }
}

class _MemberCount extends StatelessWidget {
  const _MemberCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.people_alt_rounded,
          size: 18,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Text(
          '$count members',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/* ----------------------------- MODELS ----------------------------- */

class _GroupWithClass {
  const _GroupWithClass({
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

/* ----------------------------- COMMON ----------------------------- */

class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Group Chats',
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
