import 'dart:ui';
import 'package:flutter/material.dart';
import 'widgets/gradient_background.dart';
// --- Models ---

enum NotificationType {
  follower,
  assignment,
  update,
  news,
  group,
  achievement,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime timestamp;
  bool isRead;
  final String? userId;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
    this.userId,
    this.actionUrl,
    this.metadata,
  });
}

// --- Mock Data ---

final List<NotificationModel> _mockNotifications = [
  NotificationModel(
    id: '1',
    type: NotificationType.follower,
    title: 'Sarah Chen started following you',
    description: 'You have a new follower interested in Machine Learning',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    isRead: false,
    userId: 'user123',
  ),
  NotificationModel(
    id: '2',
    type: NotificationType.assignment,
    title: 'New Assignment: Data Structures Project',
    description: 'Due date: Dec 15, 2025. Complete the binary tree implementation',
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    isRead: false,
  ),
  NotificationModel(
    id: '3',
    type: NotificationType.update,
    title: 'App Update Available',
    description: 'Version 2.5.0 is now available with new features',
    timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    isRead: true,
  ),
  NotificationModel(
    id: '4',
    type: NotificationType.news,
    title: 'Campus News: Winter Break Schedule',
    description: 'Check the updated schedule for winter break 2025',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    isRead: false,
  ),
  NotificationModel(
    id: '5',
    type: NotificationType.group,
    title: 'New message in Machine Learning Room',
    description: "Alex posted: 'Anyone want to collaborate on the final project?'",
    timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    isRead: false,
  ),
  NotificationModel(
    id: '6',
    type: NotificationType.achievement,
    title: '7-Day Streak Achievement!',
    description: "You've studied 7 days in a row. Keep it up!",
    timestamp: DateTime.now(),
    isRead: false,
  ),
];

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
    'Followers',
    'Assignments',
    'Updates',
    'News',
    'Groups',
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _notifications = List.from(_mockNotifications);
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() => _isLoading = true);
    await _loadNotifications();
  }

  List<NotificationModel> get _filteredNotifications {
    if (_selectedFilter == 'All') return _notifications;
    return _notifications.where((n) {
      switch (_selectedFilter) {
        case 'Followers':
          return n.type == NotificationType.follower;
        case 'Assignments':
          return n.type == NotificationType.assignment;
        case 'Updates':
          return n.type == NotificationType.update;
        case 'News':
          return n.type == NotificationType.news;
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
        content: const Text('All notifications marked as read'),
        backgroundColor: const Color(0xFF2d1b4e),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
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
            icon: Icons.chevron_left,
            onTap: () => Navigator.pop(context),
          ),
          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'ClashGrotesk', // Assuming Inter is available or falls back
            ),
          ),
          _buildCircularButton(
            icon: Icons.done_all,
            onTap: _markAllAsRead,
            iconSize: 18,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.12),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: iconSize,
            ),
          ),
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
                gradient: isActive ? _getGradientForFilter(filter) : null,
                color: isActive ? null : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: isActive
                    ? null
                    : Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: _getColorForFilter(filter).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
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

  LinearGradient _getGradientForFilter(String filter) {
    switch (filter) {
      case 'Followers':
        return const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFD946EF)]);
      case 'Assignments':
        return const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]);
      case 'Updates':
        return const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]);
      case 'News':
        return const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF0D9488)]);
      case 'Groups':
        return const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]);
      default: // All
        return const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF7C3AED)]);
    }
  }

  Color _getColorForFilter(String filter) {
    switch (filter) {
      case 'Followers': return const Color(0xFFEC4899);
      case 'Assignments': return const Color(0xFFF97316);
      case 'Updates': return const Color(0xFF3B82F6);
      case 'News': return const Color(0xFF14B8A6);
      case 'Groups': return const Color(0xFF10B981);
      default: return const Color(0xFF9333EA);
    }
  }

  Widget _buildNotificationList() {
    return RefreshIndicator(
      onRefresh: _refreshNotifications,
      color: const Color(0xFF9333EA),
      backgroundColor: const Color(0xFF2B2540),
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
                // Mark as read
                _markAsRead(notification.id);
                return false; // Don't dismiss
              } else {
                // Delete
                _deleteNotification(notification.id);
                return true;
              }
            },
            child: _NotificationCard(notification: notification),
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
        color: const Color(0xFF22D3EE).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.check, color: Color(0xFF22D3EE)),
    );
  }

  Widget _buildSwipeActionRight() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
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
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notifications Yet',
            style: TextStyle(
              color: Colors.white,
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
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white.withOpacity(0.06)
                : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
              right: BorderSide(color: Colors.white.withOpacity(0.1)),
              left: notification.isRead
                  ? BorderSide(color: Colors.white.withOpacity(0.1))
                  : BorderSide(
                      color: _getTypeColor(notification.type),
                      width: 4,
                    ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconContainer(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getTypeColor(notification.type),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconContainer() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: _getTypeGradient(notification.type),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Icon(
          _getTypeIcon(notification.type),
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  LinearGradient _getTypeGradient(NotificationType type) {
    switch (type) {
      case NotificationType.follower:
        return const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFD946EF)]);
      case NotificationType.assignment:
        return const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]);
      case NotificationType.update:
        return const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]);
      case NotificationType.news:
        return const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF0D9488)]);
      case NotificationType.group:
        return const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]);
      case NotificationType.achievement:
        return const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFFA855F7)]);
    }
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.follower: return const Color(0xFFEC4899);
      case NotificationType.assignment: return const Color(0xFFF97316);
      case NotificationType.update: return const Color(0xFF3B82F6);
      case NotificationType.news: return const Color(0xFF14B8A6);
      case NotificationType.group: return const Color(0xFF10B981);
      case NotificationType.achievement: return const Color(0xFF9333EA);
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.follower: return Icons.person_add_rounded;
      case NotificationType.assignment: return Icons.assignment_rounded;
      case NotificationType.update: return Icons.system_update_rounded;
      case NotificationType.news: return Icons.article_rounded;
      case NotificationType.group: return Icons.group_rounded;
      case NotificationType.achievement: return Icons.emoji_events_rounded;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${difference.inDays ~/ 7} weeks ago';
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
    )..repeat();
    _animation = Tween<double>(begin: 0.03, end: 0.08).animate(
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
            color: Colors.white.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
        );
      },
    );
  }
}
