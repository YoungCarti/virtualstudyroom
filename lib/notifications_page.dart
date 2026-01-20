import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_fonts.dart';
import 'assignment_details_page.dart';
import 'group_chat_messages_page.dart';

// --- Theme Colors (Ocean Sunset) ---
class _AppColors {
  static const background = Color(0xFF0A1929);
  static const cardBg = Color(0xFF122A46);
  static const primary = Color(0xFF2196F3); // Electric Blue
  static const accent1 = Color(0xFFFF6B6B); // Coral Pink
  static const accent2 = Color(0xFF4ECDC4); // Mint Green
  static const accent3 = Color(0xFFFFB347); // Soft Orange
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF90A4AE);
  static const divider = Color(0xFF1E3A5F);
}

// --- Models ---

enum NotificationType {
  assignment,
  update,
  group,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });
}

// --- Main Page ---

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _selectedFilter = 'All';
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  final List<String> _filters = [
    'All',
    'Assignments',
    'Updates',
    'Groups',
  ];

  // Subscriptions
  StreamSubscription? _userSub;
  final Map<String, StreamSubscription> _assignmentSubs = {};
  final Map<String, StreamSubscription> _groupMessageSubs = {};
  StreamSubscription? _updatesSub;

  List<String> _enrolledClasses = [];
  Set<String> _seenAssignmentIds = {};
  Set<String> _seenMessageIds = {};

  @override
  void initState() {
    super.initState();
    _initListeners();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    for (var sub in _assignmentSubs.values) sub.cancel();
    for (var sub in _groupMessageSubs.values) sub.cancel();
    _updatesSub?.cancel();
    super.dispose();
  }

  void _initListeners() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    // 1. Listen to user document for enrolled classes
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || !mounted) return;
      final data = snapshot.data();
      final enrolled = List<String>.from(data?['enrolledClasses'] ?? []);
      _enrolledClasses = enrolled;
      _syncAssignmentListeners(enrolled, uid);
      _syncGroupMessageListeners(enrolled, uid);
    });

    // 2. Listen to app updates
    _listenToUpdates();
  }

  void _syncAssignmentListeners(List<String> enrolledClasses, String uid) {
    // Remove old subscriptions
    final toRemove = _assignmentSubs.keys.where((k) => !enrolledClasses.contains(k)).toList();
    for (final k in toRemove) {
      _assignmentSubs[k]?.cancel();
      _assignmentSubs.remove(k);
    }

    // Add new subscriptions
    for (final classCode in enrolledClasses) {
      if (!_assignmentSubs.containsKey(classCode)) {
        _assignmentSubs[classCode] = FirebaseFirestore.instance
            .collection('classes')
            .doc(classCode)
            .collection('assignments')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .snapshots()
            .listen((snap) async {
          String className = classCode;
          try {
            final classDoc = await FirebaseFirestore.instance
                .collection('classes')
                .doc(classCode)
                .get();
            className = classDoc.data()?['className'] ?? classCode;
          } catch (_) {}

          for (final doc in snap.docs) {
            final data = doc.data();
            final id = 'assignment_${classCode}_${doc.id}';
            
            if (!_seenAssignmentIds.contains(id)) {
              _seenAssignmentIds.add(id);
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
              final title = data['title'] ?? 'New Assignment';
              final dueDate = (data['dueDate'] as Timestamp?)?.toDate();
              String description = 'Posted in $className';
              if (dueDate != null) {
                description = 'Due: ${_formatDueDate(dueDate)} • $className';
              }

              final notification = NotificationModel(
                id: id,
                type: NotificationType.assignment,
                title: title,
                description: description,
                timestamp: createdAt,
                metadata: {
                  'classCode': classCode,
                  'assignmentId': doc.id,
                },
              );

              if (mounted) {
                setState(() {
                  _notifications.removeWhere((n) => n.id == id);
                  _notifications.add(notification);
                  _sortNotifications();
                  _isLoading = false;
                });
              }
            }
          }
          if (mounted && _isLoading) {
            setState(() => _isLoading = false);
          }
        });
      }
    }

    if (enrolledClasses.isEmpty && mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _syncGroupMessageListeners(List<String> enrolledClasses, String uid) {
    // Remove old subscriptions
    final toRemove = _groupMessageSubs.keys.where((k) => !enrolledClasses.contains(k)).toList();
    for (final k in toRemove) {
      _groupMessageSubs[k]?.cancel();
      _groupMessageSubs.remove(k);
    }

    // Add new subscriptions for each class's groups
    for (final classCode in enrolledClasses) {
      if (!_groupMessageSubs.containsKey(classCode)) {
        _groupMessageSubs[classCode] = FirebaseFirestore.instance
            .collection('classes')
            .doc(classCode)
            .collection('groups')
            .where('members', arrayContains: uid)
            .snapshots()
            .listen((groupSnap) {
          for (final groupDoc in groupSnap.docs) {
            final groupId = groupDoc.id;
            final groupName = groupDoc.data()['groupName'] ?? 'Group';

            // Listen to the latest message in this group
            FirebaseFirestore.instance
                .collection('classes')
                .doc(classCode)
                .collection('groups')
                .doc(groupId)
                .collection('messages')
                .orderBy('createdAt', descending: true)
                .limit(1)
                .snapshots()
                .listen((msgSnap) {
              if (msgSnap.docs.isEmpty) return;
              final msgDoc = msgSnap.docs.first;
              final msgData = msgDoc.data();
              final msgId = 'group_${classCode}_${groupId}_${msgDoc.id}';

              // Skip if it's the user's own message
              if (msgData['senderId'] == uid) return;

              if (!_seenMessageIds.contains(msgId)) {
                _seenMessageIds.add(msgId);
                final createdAt = (msgData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                final senderName = msgData['senderName'] ?? 'Someone';
                String messageText = msgData['text'] ?? '';

                // Handle different message types
                final msgType = msgData['type'] as String?;
                final fileType = msgData['fileType'] as String?;
                if (msgType == 'image' || fileType == 'image') {
                  messageText = '📷 Photo';
                } else if (msgType == 'file' || fileType == 'file') {
                  messageText = '📎 File';
                } else if (msgType == 'meeting') {
                  messageText = '📹 Meeting invite';
                } else if (messageText.length > 50) {
                  messageText = '${messageText.substring(0, 50)}...';
                }

                final notification = NotificationModel(
                  id: msgId,
                  type: NotificationType.group,
                  title: groupName,
                  description: '$senderName: $messageText',
                  timestamp: createdAt,
                  metadata: {
                    'classCode': classCode,
                    'groupId': groupId,
                    'groupName': groupName,
                  },
                );

                if (mounted) {
                  setState(() {
                    // Remove old notifications from same group
                    _notifications.removeWhere((n) =>
                        n.type == NotificationType.group &&
                        n.metadata?['groupId'] == groupId);
                    _notifications.add(notification);
                    _sortNotifications();
                  });
                }
              }
            });
          }
        });
      }
    }
  }

  void _listenToUpdates() {
    _updatesSub = FirebaseFirestore.instance
        .collection('app_updates')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .listen((snap) {
      for (final doc in snap.docs) {
        final data = doc.data();
        final id = 'update_${doc.id}';

        final notification = NotificationModel(
          id: id,
          type: NotificationType.update,
          title: data['title'] ?? 'App Update',
          description: data['description'] ?? 'New features available',
          timestamp: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );

        if (mounted) {
          setState(() {
            _notifications.removeWhere((n) => n.id == id);
            _notifications.add(notification);
            _sortNotifications();
          });
        }
      }
    });
  }

  void _sortNotifications() {
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.isNegative) {
      return 'Overdue';
    } else if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Tomorrow';
    } else if (diff.inDays < 7) {
      return 'In ${diff.inDays} days';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  List<NotificationModel> get _filteredNotifications {
    if (_selectedFilter == 'All') return _notifications;
    return _notifications.where((n) {
      switch (_selectedFilter) {
        case 'Assignments':
          return n.type == NotificationType.assignment;
        case 'Updates':
          return n.type == NotificationType.update;
        case 'Groups':
          return n.type == NotificationType.group;
        default:
          return true;
      }
    }).toList();
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All notifications marked as read',
          style: AppFonts.clashGrotesk(color: _AppColors.textPrimary),
        ),
        backgroundColor: _AppColors.cardBg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: _AppColors.divider)),
      ),
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].isRead = true;
      }
    });
  }

  void _onNotificationTap(NotificationModel notification) {
    _markAsRead(notification.id);

    switch (notification.type) {
      case NotificationType.assignment:
        final classCode = notification.metadata?['classCode'];
        final assignmentId = notification.metadata?['assignmentId'];
        if (classCode != null && assignmentId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AssignmentDetailsPage(
                classCode: classCode,
                assignmentId: assignmentId,
                isLecturer: false,
              ),
            ),
          );
        }
        break;
      case NotificationType.group:
        final classCode = notification.metadata?['classCode'];
        final groupId = notification.metadata?['groupId'];
        final groupName = notification.metadata?['groupName'] ?? 'Group';
        if (classCode != null && groupId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupChatMessagesPage(
                classCode: classCode,
                groupId: groupId,
                groupName: groupName,
              ),
            ),
          );
        }
        break;
      case NotificationType.update:
        // Could show a dialog or navigate to an updates page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(notification.description),
            backgroundColor: _AppColors.cardBg,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            const SizedBox(height: 16),
            _buildFilterTabs(),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _filteredNotifications.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircularButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.pop(context),
            iconSize: 18,
          ),
          Text(
            'Notifications',
            style: AppFonts.clashGrotesk(
              color: _AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          _buildCircularButton(
            icon: Icons.done_all,
            onTap: _markAllAsRead,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 20,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _AppColors.divider,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: _AppColors.textPrimary,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isActive = _selectedFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? _AppColors.primary : _AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? _AppColors.primary : _AppColors.divider,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _AppColors.primary.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  filter,
                  style: AppFonts.clashGrotesk(
                    color: isActive ? Colors.white : _AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: () async {
        // Force re-fetch by clearing seen IDs and resetting
        _seenAssignmentIds.clear();
        _seenMessageIds.clear();
        _notifications.clear();
        _initListeners();
        await Future.delayed(const Duration(milliseconds: 500));
      },
      color: _AppColors.primary,
      backgroundColor: _AppColors.cardBg,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _filteredNotifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = _filteredNotifications[index];
          return Dismissible(
            key: Key(notification.id),
            background: _buildSwipeActionLeft(),
            secondaryBackground: _buildSwipeActionRight(),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                _markAsRead(notification.id);
                return false;
              } else {
                _deleteNotification(notification.id);
                return true;
              }
            },
            child: GestureDetector(
              onTap: () => _onNotificationTap(notification),
              child: _NotificationCard(notification: notification),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeActionLeft() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      decoration: BoxDecoration(
        color: _AppColors.accent2.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.check, color: _AppColors.accent2),
    );
  }

  Widget _buildSwipeActionRight() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: _AppColors.accent1.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline, color: _AppColors.accent1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 80,
            color: _AppColors.cardBg,
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications Yet',
            style: AppFonts.clashGrotesk(
              color: _AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: Text(
              "When you get notifications, they'll show up here",
              textAlign: TextAlign.center,
              style: AppFonts.clashGrotesk(
                color: _AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 4,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const _ShimmerCard(),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead
            ? _AppColors.background
            : _AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? _AppColors.divider.withOpacity(0.5)
              : _AppColors.divider,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconContainer(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.clashGrotesk(
                          color: _AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getTypeColor(notification.type),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.clashGrotesk(
                    color: _AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: AppFonts.clashGrotesk(
                    color: _AppColors.textSecondary.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getTypeColor(notification.type).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTypeColor(notification.type).withOpacity(0.3),
        ),
      ),
      child: Center(
        child: Icon(
          _getTypeIcon(notification.type),
          color: _getTypeColor(notification.type),
          size: 22,
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.assignment:
        return _AppColors.accent3; // Orange
      case NotificationType.update:
        return _AppColors.primary; // Blue
      case NotificationType.group:
        return _AppColors.accent2; // Mint
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.assignment:
        return Icons.assignment_rounded;
      case NotificationType.update:
        return Icons.system_update_rounded;
      case NotificationType.group:
        return Icons.group_rounded;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays ~/ 7}w ago';
    }
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 88,
          decoration: BoxDecoration(
            color: _AppColors.cardBg.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _AppColors.divider),
          ),
        );
      },
    );
  }
}
