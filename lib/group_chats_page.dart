import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'group_chat_messages_page.dart';

class GroupChatsPage extends StatefulWidget {
  const GroupChatsPage({super.key});

  @override
  State<GroupChatsPage> createState() => _GroupChatsPageState();
}

class _GroupChatsPageState extends State<GroupChatsPage> with SingleTickerProviderStateMixin {
  // Key to force StreamBuilder rebuild
  int _refreshKey = 0;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

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

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Same as homepage
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: const Color(0xFF22D3EE),
          backgroundColor: const Color(0xFF1C1C2E),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with search icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Messages',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter Tabs
                if (_tabController != null)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[800]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController!,
                    indicatorColor: const Color(0xFF22D3EE),
                    indicatorWeight: 2,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey[500],
                    labelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'All messages'),
                      Tab(text: 'Unread'),
                      Tab(text: 'Active'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                uid != null
                    ? _AllGroupsList(uid: uid, key: ValueKey(_refreshKey))
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
            .listen((snap) async {
              final groupDocs = snap.docs
                  .where((d) => List.from(d.data()['members'] ?? []).contains(widget.uid))
                  .toList();
              
              // Fetch last message for each group
              final groups = <_GroupWithClass>[];
              for (final d in groupDocs) {
                String? lastMessage;
                DateTime? lastMessageTime;
                
                try {
                  final messagesSnap = await FirebaseFirestore.instance
                      .collection('classes')
                      .doc(classCode)
                      .collection('groups')
                      .doc(d.id)
                      .collection('messages')
                      .orderBy('createdAt', descending: true)
                      .limit(1)
                      .get();
                  
                  if (messagesSnap.docs.isNotEmpty) {
                    final msgData = messagesSnap.docs.first.data();
                    final msgType = msgData['type'] as String?;
                    final senderId = msgData['senderId'] as String?;
                    final senderName = msgData['senderName'] as String? ?? 'Unknown';
                    final fileType = msgData['fileType'] as String?;
                    
                    // Format message content based on type
                    String messageContent;
                    if (msgType == 'image' || fileType == 'image') {
                      messageContent = '📷 Photo';
                    } else if (msgType == 'file' || fileType == 'file') {
                      messageContent = '📎 File';
                    } else if (msgType == 'voice') {
                      messageContent = '🎤 Voice message';
                    } else if (msgType == 'meeting') {
                      messageContent = '📹 Meeting';
                    } else {
                      messageContent = msgData['text'] as String? ?? '';
                    }
                    
                    // Format as "You: message" or "Name: message"
                    if (senderId == widget.uid) {
                      lastMessage = 'You: $messageContent';
                    } else {
                      // Get first name only
                      final firstName = senderName.split(' ').first;
                      lastMessage = '$firstName: $messageContent';
                    }
                    
                    final ts = msgData['createdAt'];
                    if (ts != null) {
                      lastMessageTime = (ts as Timestamp).toDate();
                    }
                  } else {
                    lastMessage = 'No messages yet';
                  }
                } catch (e) {
                  lastMessage = 'Tap to start chatting';
                }
                
                groups.add(_GroupWithClass(
                  classCode: classCode,
                  groupId: d.id,
                  groupName: d.data()['groupName'] ?? 'Unnamed',
                  memberCount: List.from(d.data()['members'] ?? []).length,
                  lastMessage: lastMessage,
                  lastMessageTime: lastMessageTime,
                  // Simulate unread count (in production, track per-user last read timestamp)
                  unreadCount: lastMessageTime != null && 
                      DateTime.now().difference(lastMessageTime!).inHours < 24 
                      ? (d.id.hashCode % 5) : 0,
                  // Simulate active status based on recent message
                  isActive: lastMessageTime != null && 
                      DateTime.now().difference(lastMessageTime!).inMinutes < 30,
                ));
              }
              
              // Sort by last message time (most recent first)
              groups.sort((a, b) {
                if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
                if (a.lastMessageTime == null) return 1;
                if (b.lastMessageTime == null) return -1;
                return b.lastMessageTime!.compareTo(a.lastMessageTime!);
              });
              
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
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        return _MessageStyleGroupTile(group: allGroups[index], index: index);
      },
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
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isActive = false,
  });

  final String classCode;
  final String groupId;
  final String groupName;
  final int memberCount;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isActive;
}

/// Message-style group tile (similar to the reference image)
class _MessageStyleGroupTile extends StatelessWidget {
  final _GroupWithClass group;
  final int index;

  const _MessageStyleGroupTile({required this.group, required this.index});

  // Avatar colors
  static const List<Color> _avatarColors = [
    Color(0xFF22D3EE), // Cyan
    Color(0xFF34D399), // Green
    Color(0xFFFBBF24), // Amber
    Color(0xFFF472B6), // Pink
    Color(0xFF818CF8), // Indigo
    Color(0xFFFB7185), // Rose
    Color(0xFF2DD4BF), // Teal
    Color(0xFFA78BFA), // Purple
  ];

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inDays == 0) {
      // Today - show time
      return DateFormat('h:mm a').format(time);
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      // This week - show day name
      return DateFormat('EEE').format(time);
    } else {
      // Older - show date
      return DateFormat('M/d/yy').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = _avatarColors[index % _avatarColors.length];
    final initials = group.groupName.split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
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
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: avatarColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: avatarColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: GoogleFonts.inter(
                          color: avatarColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Green online indicator
                  if (group.isActive)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E), // Green
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0D1117),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Name & Last Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Time Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            group.groupName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (group.lastMessageTime != null)
                          Text(
                            _formatTime(group.lastMessageTime),
                            style: GoogleFonts.inter(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Last message
                    Row(
                      children: [
                        if (group.lastMessage != null && group.lastMessageTime != null) ...[
                          Icon(
                            Icons.done_all,
                            size: 16,
                            color: const Color(0xFF22D3EE),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            group.lastMessage ?? 'Tap to start chatting',
                            style: GoogleFonts.inter(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Unread badge (show for groups with recent messages and random simulation)
                        if (group.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22D3EE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${group.unreadCount}',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            Icon(Icons.forum_outlined, color: Colors.grey[700], size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.inter(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
