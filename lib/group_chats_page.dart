import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'group_chat_messages_page.dart';

class GroupChatsPage extends StatefulWidget {
  const GroupChatsPage({super.key});

  @override
  State<GroupChatsPage> createState() => _GroupChatsPageState();
}

class _GroupChatsPageState extends State<GroupChatsPage> {
  // Key to force StreamBuilder rebuild
  int _refreshKey = 0;

  Future<void> _refresh() async {
    // Simulate a small delay for better UX
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _refreshKey++;
      });
    }
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
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: const Color(0xFFA855F7),
              backgroundColor: const Color(0xFF1F1F2E),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Group Chats',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: Text(
                        'Your Groups',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    uid != null
                        ? _AllGroupsList(uid: uid, key: ValueKey(_refreshKey))
                        : const _EmptyState(message: 'Sign in to see your groups.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- GROUP LIST ----------------------------- */

class _AllGroupsList extends StatefulWidget {
  const _AllGroupsList({super.key, required this.uid});

  final String uid;

  @override
  State<_AllGroupsList> createState() => _AllGroupsListState();
}

class _AllGroupsListState extends State<_AllGroupsList> {
  // Map of ClassCode -> List of Groups in that class
  final Map<String, List<_GroupWithClass>> _groupsByClass = {};
  
  StreamSubscription? _userSubscription;
  final Map<String, StreamSubscription> _classSubscriptions = {};
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    for (final sub in _classSubscriptions.values) sub.cancel();
    super.dispose();
  }

  void _init() {
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .snapshots()
        .listen((userSnap) {
      if (!mounted) return;
      
      final enrolled = List<String>.from(userSnap.data()?['enrolledClasses'] ?? []);
      _syncSubscriptions(enrolled);
    });
  }

  void _syncSubscriptions(List<String> enrolledClasses) {
    // Remove old
    final toRemove = _classSubscriptions.keys.where((k) => !enrolledClasses.contains(k)).toList();
    for (final k in toRemove) {
      _classSubscriptions[k]?.cancel();
      _classSubscriptions.remove(k);
      _groupsByClass.remove(k);
    }

    // Add new
    for (final classCode in enrolledClasses) {
      if (!_classSubscriptions.containsKey(classCode)) {
        _classSubscriptions[classCode] = FirebaseFirestore.instance
            .collection('classes')
            .doc(classCode)
            .collection('groups')
            .snapshots()
            .listen((snap) {
              final groups = snap.docs
                  .where((d) => List.from(d.data()['members'] ?? []).contains(widget.uid))
                  .map((d) => _GroupWithClass(
                        classCode: classCode,
                        groupId: d.id,
                        groupName: d.data()['groupName'] ?? 'Unnamed',
                        memberCount: List.from(d.data()['members'] ?? []).length,
                      ))
                  .toList();
              
              if (mounted) {
                setState(() {
                  _groupsByClass[classCode] = groups;
                  _isLoading = false;
                });
              }
            });
      }
    }
    
    // If no classes, we are done loading
    if (enrolledClasses.isEmpty && mounted) {
      setState(() {
        _isLoading = false;
        _groupsByClass.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allGroups = _groupsByClass.values.expand((l) => l).toList();

    if (allGroups.isEmpty) {
      return const _EmptyState(message: 'You are not in any groups yet.');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allGroups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (_, index) {
        return _GroupCard(group: allGroups[index]);
      },
    );
  }
}


/* ----------------------------- GROUP CARD ----------------------------- */

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final _GroupWithClass group;

  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.forum_rounded, color: Color(0xFFA855F7), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.groupName,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${group.memberCount} members',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Class Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Text(
              "Class: ${group.classCode}",
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA855F7), // Primary Purple
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- MODELS & HELPERS ----------------------------- */

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

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassContainer({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, color: Colors.white.withValues(alpha: 0.2), size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
