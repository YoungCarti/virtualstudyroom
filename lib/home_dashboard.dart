import 'app_fonts.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'video_call_page.dart';

import 'app_theme.dart';
import 'services/notification_service.dart';
import 'widgets/animated_components.dart';
import 'widgets/brainwave_mini_player.dart';
import 'assignment_service.dart';
import 'assignment_details_page.dart';
import 'classes_page.dart';
import 'group_chats_page.dart';
import 'profile_menu_page.dart';
import 'notifications_page.dart';
import 'all_assignments_page.dart';
import 'ai_tools_page.dart';
import 'study_rooms_page.dart';
import 'todo_page.dart';

import 'auth_service.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  int _selectedIndex = 0;
  String _role = 'student'; // track current role
  
  // Notification Subscriptions
  final Map<String, StreamSubscription> _assignmentSubs = {};
  final Map<String, StreamSubscription> _messageSubs = {}; // sub-subscriptions for messages
  StreamSubscription? _userSettingsSub;
  StreamSubscription? _groupsSub; // Main subscription to find groups
  
  // Settings Cache
  bool _notifyAssignments = true;
  bool _notifyGroups = true;

  @override
  void initState() {
    super.initState();
    // Update streak when dashboard loads (app start or login)
    AuthService.instance.updateUserStreak();
    
    // Initialize Notification Service
    final ns = NotificationService();
    ns.init();
    ns.requestPermissions();
    
    // Setup Listeners
    _setupNotificationListeners();
    
    // Listen for Notification Taps
    NotificationService().onNotificationClick.listen((payload) {
      _handleNotificationClick(payload);
    });
  }
  
  void _setupNotificationListeners() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 1. Listen to Settings & Enrollments (for Assignments)
    _userSettingsSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;

      // Update Settings
      _notifyAssignments = data['settings_notify_assignments'] ?? true;
      _notifyGroups = data['settings_notify_groups'] ?? true;
      
      // Update Role
      if (mounted) {
        setState(() {
          _role = data['role'] ?? 'student';
        });
      }

      // Update Assignment Listeners based on Enrollments
      final enrolledClasses = List<String>.from(data['enrolledClasses'] ?? []);
      _updateAssignmentListeners(enrolledClasses);
    });

    // 2. Listen to Groups (via Collection Group)
    _groupsSub = FirebaseFirestore.instance
        .collectionGroup('groups')
        .where('members', arrayContains: uid)
        .snapshots()
        .listen((snapshot) {
       _syncGroupMessageListeners(snapshot.docs);
    });
  }

  void _updateAssignmentListeners(List<String> classCodes) {
    // Remove stale
    _assignmentSubs.removeWhere((code, sub) {
      if (!classCodes.contains(code)) {
        sub.cancel();
        return true;
      }
      return false;
    });

    // Add new
    for (final code in classCodes) {
      if (!_assignmentSubs.containsKey(code)) {
        _assignmentSubs[code] = FirebaseFirestore.instance
            .collection('classes')
            .doc(code)
            .collection('assignments')
            .snapshots()
            .skip(1)
            .listen((snapshot) {
          if (!_notifyAssignments) return;
          
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              final title = data?['title'] ?? 'New Assignment'; // Safe access
              
              // Simple check to avoid notifying for old assignments on init if skip(1) misses
              // (skip(1) usually works for stream start, but let's be safe)
              NotificationService().showNotification(
                id: change.doc.hashCode,
                title: 'New Assignment Posted',
                body: title,
                payload: 'assignment_${code}_${change.doc.id}',
              );
            }
          }
        });
      }
    }
  }

  void _handleNotificationClick(String? payload) {
    if (payload == null) return;
    
    // Parse Payload: assignment_{classCode}_{assignmentId}
    if (payload.startsWith('assignment_')) {
      final parts = payload.split('_');
      if (parts.length >= 3) {
        final classCode = parts[1];
        final assignmentId = parts[2];
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssignmentDetailsPage(
              classCode: classCode, 
              assignmentId: assignmentId,
              isLecturer: _role == 'lecturer',
            ),
          ),
        );
      }
    }
  }

  void _syncGroupMessageListeners(List<DocumentSnapshot> groupDocs) {
    final groupIds = groupDocs.map((d) => d.id).toSet();

    // Remove stale
    _messageSubs.removeWhere((id, sub) {
      if (!groupIds.contains(id)) {
        sub.cancel();
        return true;
      }
      return false;
    });

    // Add new
    for (final groupDoc in groupDocs) {
      final groupId = groupDoc.id;
      if (!_messageSubs.containsKey(groupId)) {
        // Use the reference from the doc to access subcollection (handles any path)
        _messageSubs[groupId] = groupDoc.reference
            .collection('messages')
            .snapshots()
            .skip(1)
            .listen((snapshot) {
          if (!_notifyGroups) return;

          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              final senderId = data?['senderId'];
              final currentUser = FirebaseAuth.instance.currentUser?.uid;
              
              if (senderId == currentUser) continue;
              
              final text = data?['text'] ?? 'New message'; // Safe access
              NotificationService().showNotification(
                id: change.doc.hashCode,
                title: 'New Group Message',
                body: text,
                payload: 'group_$groupId',
              );
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _userSettingsSub?.cancel();
    _groupsSub?.cancel();
    for (var sub in _assignmentSubs.values) sub.cancel();
    for (var sub in _messageSubs.values) sub.cancel();
    super.dispose();
  }

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshHome() async {
    // Simulate delay
    await Future.delayed(const Duration(milliseconds: 800));
    // Trigger rebuild to re-fetch futures (AssignmentsCard will rebuild)
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Pure dark background
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Clean dark background - no glassmorphism
          Container(
            color: const Color(0xFF0D1117),
          ),

          // Main Content
          IndexedStack(
            index: _selectedIndex,
            children: [
              // Home Tab
              SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  onRefresh: _refreshHome,
                  color: const Color(0xFFA855F7),
                  backgroundColor: const Color(0xFF1F1F2E),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(), // Ensure it's scrollable even if content is short
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: uid != null
                          ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .snapshots()
                          : null,
                      builder: (context, snapshot) {
                        String userName = 'User';
                        String? photoUrl;
                        if (snapshot.hasData && snapshot.data!.data() != null) {
                          final data = snapshot.data!.data()!;
                          userName = (data['fullName'] ?? data['name'] ?? 'User') as String;
                          // Use profilePictureUrl from onboarding, fallback to photoUrl
                          photoUrl = (data['profilePictureUrl'] ?? data['photoUrl']) as String?;
                          if (userName.contains(' ')) {
                            userName = userName.split(' ')[0];
                          }
                          // ... existing role logic ...
                          final role = (data['role'] ?? 'student') as String;
                          if (role != _role && mounted) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _role = role);
                            });
                          }
                        }
                        // Get additional data for stats
                        final enrolledClasses = (snapshot.data?.data()?['enrolledClasses'] as List<dynamic>?)?.length ?? 0;
                        final streak = (snapshot.data?.data()?['currentStreak'] ?? 0) as int;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with greeting
                            _CleanHeader(
                              userName: userName,
                              photoUrl: photoUrl,
                              onProfileTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileMenuPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // Stats Cards Grid (like reference)
                            _StatsGrid(
                              streak: streak,
                              classesCount: enrolledClasses,
                            ),
                            const SizedBox(height: 24),
                            
                            // Quick Action Icons Row
                            const _QuickActionsRow(),
                            const SizedBox(height: 24),

                            // Brainwave Station Mini Player
                            const BrainwaveMiniPlayer(),
                            // No need for extra SizedBox here as MiniPlayer has bottom margin
                            
                            // Schedule Calendar
                            // Schedule Calendar
                            Text(
                              'Schedule',
                              style: AppFonts.clashGrotesk(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Week Calendar Widget
                            const _WeekScheduleCalendar(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Classes Tab
              ClassesPage(role: _role),
              // Group Chats Tab
              const GroupChatsPage(),
            ],
          ),

          // 4. Bottom Navigation (attached to bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomNav(
              selectedIndex: _selectedIndex,
              onTap: _onBottomNavTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.onProfileTap,
    required this.userName,
    this.photoUrl,
  });

  final VoidCallback onProfileTap;
  final String userName;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 2,
                  ),
                  color: photoUrl == null || photoUrl!.isEmpty ? const Color(0xFF2196F3) : null,
                  image: photoUrl != null && photoUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: photoUrl == null || photoUrl!.isEmpty
                    ? Center(
                        child: Text(
                          _getInitials(userName),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName!',
                  style: AppFonts.clashGrotesk(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Let's learn something new",
                  style: AppFonts.clashGrotesk(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Notification Bell (Glass Style)
        _GlassIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsPage()),
            );
          },
        ),
      ],
    );
  }
}

// Helper function to get initials from a name
String _getInitials(String name) {
  if (name.isEmpty) return '?';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts[0][0].toUpperCase();
}

/* ----------------------------- ASSIGNMENTS CARD ----------------------------- */

class _AssignmentsCard extends StatefulWidget {
  const _AssignmentsCard();

  @override
  State<_AssignmentsCard> createState() => _AssignmentsCardState();
}

class _AssignmentsCardState extends State<_AssignmentsCard> {
  // Cache: ClassCode -> List of Assignments
  final Map<String, List<Assignment>> _assignmentsByClass = {};
  
  // Subscriptions
  StreamSubscription? _userSubscription;
  final Map<String, StreamSubscription> _classSubscriptions = {};
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    for (final sub in _classSubscriptions.values) sub.cancel();
    super.dispose();
  }

  void _startListening() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 1. Listen to User Enrollment
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((userSnap) {
      if (!mounted) return;
      if (!userSnap.exists) {
         if (mounted) setState(() => _isLoading = false);
         return;
      }

      final enrolled = List<String>.from(userSnap.data()?['enrolledClasses'] ?? []);
      _syncSubscriptions(enrolled);
    });
  }

  void _syncSubscriptions(List<String> enrolledClasses) {
    // A. Cleanup old subscriptions
    final toRemove = _classSubscriptions.keys.where((k) => !enrolledClasses.contains(k)).toList();
    for (final k in toRemove) {
      _classSubscriptions[k]?.cancel();
      _classSubscriptions.remove(k);
      _assignmentsByClass.remove(k);
    }

    // B. Add new subscriptions
    for (final classCode in enrolledClasses) {
      if (!_classSubscriptions.containsKey(classCode)) {
        // Fetch class name and then listen
        // We use an immediate listener that *also* fetches the class name asynchronously
        // to update the assignments with the correct name.
        
        _classSubscriptions[classCode] = FirebaseFirestore.instance
            .collection('classes')
            .doc(classCode)
            .collection('assignments')
            // Strict filter: Show only assignments due in the future
            .where('dueDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
            .snapshots()
            .listen((snap) async {
              // Fetch class name on the fly (caching could be added but this is simple)
              String className = '';
              try {
                final classDoc = await FirebaseFirestore.instance.collection('classes').doc(classCode).get();
                className = classDoc.data()?['className'] ?? '';
              } catch (e) {
                // ignore error, default to empty (shows classCode)
              }

              if (!mounted) return;

              final assignments = snap.docs.map((d) => Assignment.fromFirestore(d, classCode, className: className)).toList();
              
              if (mounted) {
                setState(() {
                  _assignmentsByClass[classCode] = assignments;
                  _isLoading = false;
                });
              }
            });
      }
    }

    if (enrolledClasses.isEmpty && mounted) {
      setState(() {
        _isLoading = false;
        _assignmentsByClass.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _assignmentsByClass.isEmpty) {
      // Show loading only if we have NO data yet
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // We can't easily get role inside this isolated widget without passing it or fetching it.
    // However, the parent passes it? No, we didn't pass it.
    // We can re-fetch or assume 'student' for the "View" aspect, but for the "Click" -> "Details", 
    // the Details page might need it. 
    // Optimization: The parent (HomeDashboard) has the role. We could pass it. 
    // But for now, let's keep it self-contained or use the one from FirebaseAuth/Firestore if needed.
    // Actually, `AssignmentItem` takes `isLecturer`.
    // Let's check `HomeDashboard`... it has `_role`.
    // Ideally we should pass `isLecturer` to this widget.
    // For now, let's infer or default to false (student view) since this is primarily a student feature "Assignments Due".
    const isLecturer = false; // Safe default for Dashboard view. 

    // Aggregate and Sort
    final now = DateTime.now();
    final allAssignments = _assignmentsByClass.values
        .expand((l) => l)
        .where((a) => a.dueDate.isAfter(now)) // Client-side filter for strict correctness
        .toList();
    allAssignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    
    final pendingCount = allAssignments.length;
    final displayAssignments = allAssignments.take(3).toList(); // Limit to 3

    return _GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Assignments Due',
                style: AppFonts.clashGrotesk(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pendingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF43F5E).withValues(alpha: 0.15), // Red tint
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFF43F5E), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$pendingCount pending',
                            style: AppFonts.clashGrotesk(
                              color: const Color(0xFFF43F5E),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (allAssignments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white.withValues(alpha: 0.3), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'All caught up!',
                    style: AppFonts.clashGrotesk(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            )
          else
            ...displayAssignments.map((a) => _AssignmentItem(
                  assignment: a,
                  isLecturer: isLecturer,
                )),
          
          if (allAssignments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AllAssignmentsPage(),
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View all assignments',
                    style: AppFonts.clashGrotesk(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssignmentItem extends StatelessWidget {
  final Assignment assignment;
  final bool isLecturer;

  const _AssignmentItem({
    required this.assignment,
    required this.isLecturer,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = assignment.dueDate.difference(now);
    
    String status;
    Color statusColor;

    if (diff.inDays == 0 && !diff.isNegative) {
      status = 'Today';
      statusColor = const Color(0xFFF43F5E); // Red
    } else if (diff.inDays == 1) {
      status = 'Tomorrow';
      statusColor = const Color(0xFFF59E0B); // Amber
    } else if (diff.isNegative) {
      status = 'Overdue';
      statusColor = Colors.grey;
    } else {
      status = DateFormat('MMM d').format(assignment.dueDate);
      statusColor = const Color(0xFF22D3EE); // Cyan
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => AssignmentDetailsPage(
                  classCode: assignment.classCode,
                  assignmentId: assignment.id,
                  isLecturer: isLecturer,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.assignment_outlined, color: statusColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: AppFonts.clashGrotesk(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignment.className.isNotEmpty ? assignment.className : assignment.classCode,
                        style: AppFonts.clashGrotesk(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    status,
                    style: AppFonts.clashGrotesk(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A).withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIcon(
                icon: Icons.home_rounded,
                isSelected: selectedIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavIcon(
                icon: Icons.class_outlined,
                isSelected: selectedIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavIcon(
                icon: Icons.forum_rounded,
                isSelected: selectedIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFF22D3EE).withValues(alpha: 0.15), // Cyan glow
                shape: BoxShape.circle,
              )
            : null,
        child: Icon(
          icon,
          color: isSelected
              ? const Color(0xFF22D3EE) // Cyan active
              : Colors.white.withValues(alpha: 0.5), // Muted inactive
          size: 24,
        ),
      ),
    );
  }
}

// --- REUSABLE GLASS COMPONENTS ---

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
            color: Colors.black.withValues(alpha: 0.3), // Darker Tint for better contrast
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

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

// ============ NEW WIDGETS ============

/// Welcome card with streak counter and daily progress
class _WelcomeCard extends StatelessWidget {
  final String userName;
  final int streak;

  const _WelcomeCard({
    required this.userName,
    required this.streak,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getMotivationalQuote() {
    final quotes = [
      '"The only way to do great work is to love what you do."',
      '"Education is the passport to the future."',
      '"Small progress is still progress."',
      '"Stay curious, keep learning."',
      '"Your potential is endless."',
    ];
    return quotes[DateTime.now().day % quotes.length];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.electricBlue.withValues(alpha: 0.2),
            AppTheme.mint.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.electricBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Left side - Greeting & Quote
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: AppFonts.clashGrotesk(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Let's make today count!",
                  style: AppFonts.clashGrotesk(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getMotivationalQuote(),
                  style: AppFonts.clashGrotesk(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Right side - Streak Counter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.coral.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.white, size: 28),
                const SizedBox(height: 4),
                Text(
                  '$streak',
                  style: AppFonts.clashGrotesk(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'day streak',
                  style: AppFonts.clashGrotesk(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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

/// Quick actions grid with 4 shortcut buttons
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Quick Actions',
            style: AppFonts.clashGrotesk(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.assignment_outlined,
                label: 'Assignments',
                color: AppTheme.electricBlue,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AllAssignmentsPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.class_outlined,
                label: 'Classes',
                color: AppTheme.mint,
                onTap: () {
                  // Tab to classes (index 1)
                  final state = context.findAncestorStateOfType<_HomeDashboardPageState>();
                  state?._onBottomNavTap(1);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.groups_outlined,
                label: 'Study Rooms',
                color: AppTheme.coral,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StudyRoomsPage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.auto_awesome,
                label: 'AI Tools',
                color: AppTheme.softOrange,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AiToolsPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppFonts.clashGrotesk(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color.withValues(alpha: 0.6),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

// ============ NEW CLEAN DESIGN WIDGETS ============

/// Clean header without glassmorphism
class _CleanHeader extends StatelessWidget {
  final String userName;
  final String? photoUrl;
  final VoidCallback onProfileTap;

  const _CleanHeader({
    required this.userName,
    required this.onProfileTap,
    this.photoUrl,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Profile avatar + Greeting text
        Row(
          children: [
            // Profile Avatar
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
                    width: 2,
                  ),
                  image: DecorationImage(
                    image: photoUrl != null && photoUrl!.isNotEmpty
                        ? NetworkImage(photoUrl!)
                        : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Greeting text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $userName',
                  style: AppFonts.clashGrotesk(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Here is your activity today.',
                  style: AppFonts.clashGrotesk(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // Right: Notification bell
        AnimatedScaleButton(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsPage()),
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C2E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}

/// Stats grid with 4 cards like reference
class _StatsGrid extends StatelessWidget {
  final int streak;
  final int classesCount;

  const _StatsGrid({
    required this.streak,
    required this.classesCount,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDashboardStats(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'assignments': 0, 'completeness': 100};
        final assignmentsCount = data['assignments'] as int;
        final completeness = data['completeness'] as int;
        
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '$streak',
                    label: 'Day Streak',
                    icon: Icons.local_fire_department,
                    color: const Color(0xFFFF6B6B), // Coral
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    value: '$classesCount',
                    label: 'Classes',
                    icon: Icons.school_outlined,
                    color: const Color(0xFF4ECDC4), // Mint
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: '$assignmentsCount',
                    label: 'Assignments',
                    icon: Icons.assignment_outlined,
                    color: const Color(0xFF2196F3), // Blue
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    value: '$completeness%',
                    label: 'Completeness',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFFFFB347), // Orange
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getDashboardStats() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return {'assignments': 0, 'completeness': 100};
      
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final enrolledClasses = List<String>.from(userDoc.data()?['enrolledClasses'] ?? []);
      
      if (enrolledClasses.isEmpty) return {'assignments': 0, 'completeness': 100};
      
      int totalAssignments = 0;
      int completedCount = 0;

      // Process classes in parallel
      await Future.wait(enrolledClasses.map((classCode) async {
        try {
          // Get Assignments for this class
          final assignmentsSnap = await FirebaseFirestore.instance
              .collection('classes')
              .doc(classCode)
              .collection('assignments')
              .get();
              
          if (assignmentsSnap.docs.isEmpty) return;
          
          // Filter: Only include assignments due in the future
          final now = DateTime.now();
          final assignments = assignmentsSnap.docs.where((doc) {
            final data = doc.data();
            if (data['dueDate'] is Timestamp) {
               return (data['dueDate'] as Timestamp).toDate().isAfter(now);
            }
            return false;
          }).toList();

          if (assignments.isEmpty) return;

          totalAssignments += assignments.length; // Dart is single-threaded, += is safe after await in this context
          
          // Check for group assignments to fetch group ID if needed
          String? groupId;
          final hasGroupAssignments = assignments.any((d) => d.data()['submissionType'] == 'group');
          
          if (hasGroupAssignments) {
            final groupInfo = await AssignmentService.instance.getStudentGroup(classCode, uid);
            groupId = groupInfo?['groupId'];
          }

          // Check submissions in parallel
          int localCompleted = 0;
          await Future.wait(assignments.map((doc) async {
            final data = doc.data();
            final type = data['submissionType'] ?? 'individual';
            final assignmentId = doc.id;
            bool isCompleted = false;

            if (type == 'group') {
               if (groupId != null) {
                  final sub = await FirebaseFirestore.instance
                       .collection('classes')
                       .doc(classCode)
                       .collection('assignments')
                       .doc(assignmentId)
                       .collection('submissions')
                       .doc(groupId)
                       .get();
                  if (sub.exists) isCompleted = true;
               }
            } else {
               final sub = await FirebaseFirestore.instance
                   .collection('classes')
                   .doc(classCode)
                   .collection('assignments')
                   .doc(assignmentId)
                   .collection('submissions')
                   .doc(uid)
                   .get();
               if (sub.exists) isCompleted = true;
            }
            
            if (isCompleted) localCompleted++;
          }));
          
          completedCount += localCompleted;

        } catch (e) {
          print('Error processing class $classCode: $e');
        }
      }));
      
      int completeness = 100;
      if (totalAssignments > 0) {
        completeness = ((completedCount / totalAssignments) * 100).toInt();
      }

      return {
        'assignments': totalAssignments - completedCount, // Show pending only
        'completeness': completeness,
      };
    } catch (e) {
      print('Error calculating stats: $e');
      return {'assignments': 0, 'completeness': 100}; // Default to 100 on error? or 0? 100 keeps UI clean.
    }
  }
}

/// Individual stat card
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: AppFonts.clashGrotesk(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppFonts.clashGrotesk(
                color: Colors.grey[500],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action icons row (like reference)
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickActionIcon(
          icon: Icons.checklist_rounded,
          label: 'To-Do',
          color: const Color(0xFF2196F3),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ToDoPage()),
            );
          },
        ),
        _QuickActionIcon(
          icon: Icons.assignment_outlined,
          label: 'Tasks',
          color: const Color(0xFF4ECDC4),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AllAssignmentsPage()),
            );
          },
        ),
        _QuickActionIcon(
          icon: Icons.groups_rounded,
          label: 'Study',
          color: const Color(0xFFFF6B6B),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StudyRoomsPage()),
            );
          },
        ),
        _QuickActionIcon(
          icon: Icons.auto_awesome,
          label: 'AI',
          color: const Color(0xFFFFB347),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AiToolsPage()),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppFonts.clashGrotesk(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============ WEEK SCHEDULE CALENDAR ============

/// A week-view schedule calendar widget
class _WeekScheduleCalendar extends StatefulWidget {
  const _WeekScheduleCalendar();

  @override
  State<_WeekScheduleCalendar> createState() => _WeekScheduleCalendarState();
}

class _WeekScheduleCalendarState extends State<_WeekScheduleCalendar> {
  late DateTime _currentWeekStart;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // Start from Monday of current week
    final now = DateTime.now();
    _currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: Column(
        children: [
          // Week Navigation Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _previousWeek,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                  ),
                ),
                Text(
                  _getWeekLabel(),
                  style: AppFonts.clashGrotesk(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: _nextWeek,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          
          // Days Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              border: Border(
                top: BorderSide(color: Colors.grey[800]!, width: 1),
                bottom: BorderSide(color: Colors.grey[800]!, width: 1),
              ),
            ),
            child: Row(
              children: List.generate(7, (index) {
                final day = _currentWeekStart.add(Duration(days: index));
                final isToday = _isToday(day);
                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        _getDayName(index),
                        style: AppFonts.clashGrotesk(
                          color: isToday ? const Color(0xFF22D3EE) : Colors.grey[500],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isToday ? const Color(0xFF22D3EE) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: AppFonts.clashGrotesk(
                              color: isToday ? Colors.black : Colors.white,
                              fontSize: 13,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          
          // Schedule Content
          if (uid == null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Sign in to view schedule',
                style: AppFonts.clashGrotesk(color: Colors.grey[500]),
              ),
            )
          else
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                
                final enrolledClasses = List<String>.from(
                  userSnap.data?.data()?['enrolledClasses'] ?? []
                );
                
                if (enrolledClasses.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.calendar_today_outlined, 
                             color: Colors.grey[700], size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'No classes enrolled',
                          style: AppFonts.clashGrotesk(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  );
                }
                
                return _LiveScheduleGrid(
                  enrolledClasses: enrolledClasses,
                  weekStart: _currentWeekStart,
                );
              }, // StreamBuilder builder
            ),

        ],
      ),
    );
  }

  String _getWeekLabel() {
    final endOfWeek = _currentWeekStart.add(const Duration(days: 6));
    final startMonth = DateFormat('MMM').format(_currentWeekStart);
    final endMonth = DateFormat('MMM').format(endOfWeek);
    
    if (startMonth == endMonth) {
      return '${DateFormat('MMM d').format(_currentWeekStart)} - ${endOfWeek.day}, ${endOfWeek.year}';
    } else {
      return '${DateFormat('MMM d').format(_currentWeekStart)} - ${DateFormat('MMM d').format(endOfWeek)}, ${endOfWeek.year}';
    }
  }

  String _getDayName(int index) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[index];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }


}

class _ScheduleEvent {
  final String className;
  final String classCode;
  final int dayOfWeek; // 0 = Monday, 6 = Sunday
  final String startTime;
  final String endTime;
  final String room;
  final Color color;

  final String? meetingCode;
  final String? groupId;
  final DateTime? validStart;
  final DateTime? validEnd;

  _ScheduleEvent({
    required this.className,
    required this.classCode,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.color,
    this.meetingCode,
    this.groupId,
    this.validStart,
    this.validEnd,
  });
}

class _ScheduleEventCard extends StatelessWidget {
  final _ScheduleEvent event;

  const _ScheduleEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: event.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: event.color, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${event.startTime} - ${event.endTime}',
            style: AppFonts.clashGrotesk(
              color: event.color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.className,
            style: AppFonts.clashGrotesk(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (event.room.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              event.room,
              style: AppFonts.clashGrotesk(
                color: Colors.grey[400],
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Event card for time grid layout
class _TimeGridEventCard extends StatelessWidget {
  final _ScheduleEvent event;

  const _TimeGridEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleJoin(context),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: event.color.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(color: event.color, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${event.startTime} - ${event.endTime}',
              style: AppFonts.clashGrotesk(
                color: event.color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                event.className,
                style: AppFonts.clashGrotesk(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (event.room.isNotEmpty) 
              Text(
                event.room,
                style: AppFonts.clashGrotesk(
                  color: Colors.grey[400],
                  fontSize: 8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  void _handleJoin(BuildContext context) async {
      if (event.meetingCode == null || event.validStart == null || event.validEnd == null) return;
      
      final now = DateTime.now();
      if (now.isBefore(event.validStart!)) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Class not yet started"), 
            backgroundColor: Colors.orange
         ));
         return;
      }
      if (now.isAfter(event.validEnd!)) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Class has ended"), 
            backgroundColor: Colors.red
         ));
         return;
      }
      
      // Permissions
      final permissions = await [Permission.camera, Permission.microphone].request();
      if (!permissions[Permission.camera]!.isGranted || !permissions[Permission.microphone]!.isGranted) {
         if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions required to join')));
         return;
      }
      
      if (context.mounted) {
         Navigator.push(
            context,
            MaterialPageRoute(
               builder: (context) => VideoCallPage(
                  channelName: event.meetingCode!,
                  classCode: event.classCode,
                  groupId: event.groupId ?? 'schedule',
                  groupName: event.className,
               ),
            ),
         );
      }
  }
}

class _LiveScheduleGrid extends StatefulWidget {
  final List<String> enrolledClasses;
  final DateTime weekStart;

  const _LiveScheduleGrid({
    super.key,
    required this.enrolledClasses,
    required this.weekStart,
  });

  @override
  State<_LiveScheduleGrid> createState() => _LiveScheduleGridState();
}

class _LiveScheduleGridState extends State<_LiveScheduleGrid> {
  final Map<String, List<_ScheduleEvent>> _eventsByClass = {};
  final List<StreamSubscription> _subscriptions = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  @override
  void didUpdateWidget(_LiveScheduleGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.weekStart != oldWidget.weekStart || 
        widget.enrolledClasses.length != oldWidget.enrolledClasses.length ||
        !_listsEqual(widget.enrolledClasses, oldWidget.enrolledClasses)) {
      _cleanupListeners();
      if (mounted) {
        setState(() {
           _eventsByClass.clear();
           _isLoading = true;
        });
      }
      _setupListeners();
    }
  }
  
  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i=0; i< a.length; i++) {
        if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _cleanupListeners();
    _scrollController.dispose();
    super.dispose();
  }

  void _cleanupListeners() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  void _setupListeners() {
    if (widget.enrolledClasses.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final weekEnd = widget.weekStart.add(const Duration(days: 7));
    
    int processedCount = 0;
    
    // Define schedule colors
    final colors = [
      const Color(0xFFFDE68A), // Amber
      const Color(0xFF86EFAC), // Green
      const Color(0xFF93C5FD), // Blue
      const Color(0xFFFCA5A5), // Red
      const Color(0xFFD8B4FE), // Purple
      const Color(0xFF67E8F9), // Cyan
    ];

    for (int i = 0; i < widget.enrolledClasses.length; i++) {
       final classCode = widget.enrolledClasses[i];
       final color = colors[i % colors.length];

       // First fetch class name (single fetch, reasonable optimization)
       FirebaseFirestore.instance.collection('classes').doc(classCode).get().then((classDoc) {
          if (!classDoc.exists) {
             _checkLoadingComplete(++processedCount);
             return;
          }
          final className = classDoc.data()?['className'] ?? classCode;
          
          // Listen to schedules
          // Note: If you have index issues, ensure composite index (startTime ASC) exists
          final sub = FirebaseFirestore.instance
              .collection('classes').doc(classCode).collection('schedules')
              .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.weekStart))
              .where('startTime', isLessThan: Timestamp.fromDate(weekEnd))
              .snapshots()
              .listen((snapshot) {
                  
                  final events = <_ScheduleEvent>[];
                  for (final doc in snapshot.docs) {
                      final data = doc.data();
                      final startTs = data['startTime'] as Timestamp?;
                      final endTs = data['endTime'] as Timestamp?;
                      if (startTs == null || endTs == null) continue;
                      
                      final dtStart = startTs.toDate();
                      final dtEnd = endTs.toDate();
                      final dayIndex = dtStart.weekday - 1; // Mon=1 -> 0

                      events.add(_ScheduleEvent(
                        className: className,
                        classCode: classCode,
                        dayOfWeek: dayIndex,
                        startTime: DateFormat('H:mm').format(dtStart),
                        endTime: DateFormat('H:mm').format(dtEnd),
                        room: 'Online',
                        color: color,
                        meetingCode: data['meetingCode'],
                        groupId: data['groupId'],
                        validStart: dtStart,
                        validEnd: dtEnd,
                      ));
                  }
                  
                  if (mounted) {
                    setState(() {
                      _eventsByClass[classCode] = events;
                      _isLoading = false; // At least one loaded/updated
                    });
                  }
              }, onError: (e) {
                 debugPrint("Error listening to schedule for $classCode: $e");
              });
              
           _subscriptions.add(sub);
           _checkLoadingComplete(++processedCount);
       });
    }
  }
  
  void _checkLoadingComplete(int count) {
     if (count == widget.enrolledClasses.length && mounted) {
        // Just ensuring spinner goes away if all fetched empty using the counter
        if (_eventsByClass.isEmpty) {
           setState(() => _isLoading = false);
        }
     }
  }

  double _parseHour(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 9.0;
    final hours = int.tryParse(parts[0]) ?? 9;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return hours + (minutes / 60.0);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _eventsByClass.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
    }
    
    // Flatten and sort
    final allEvents = _eventsByClass.values.expand((e) => e).toList();
    allEvents.sort((a, b) {
       if (a.dayOfWeek != b.dayOfWeek) return a.dayOfWeek.compareTo(b.dayOfWeek);
       return a.startTime.compareTo(b.startTime);
    });

    if (allEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.event_available, color: Colors.grey[700], size: 32),
            const SizedBox(height: 8),
            Text(
              'No scheduled classes this week',
              style: AppFonts.clashGrotesk(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    // Time labels from 8am to 6pm
    const startHour = 8;
    const endHour = 18;
    const hourHeight = 50.0;
    
    return SizedBox(
      height: 280,
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time labels column (left side)
            SizedBox(
              width: 45,
              child: Column(
                children: List.generate(endHour - startHour + 1, (index) {
                  final hour = startHour + index;
                  final label = hour < 12 ? '${hour}am' : hour == 12 ? '12pm' : '${hour - 12}pm';
                  return SizedBox(
                    height: hourHeight,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8, top: 0),
                        child: Text(
                          label,
                          style: AppFonts.clashGrotesk(
                            color: Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            // Grid with events
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 7 * 90.0, // 7 days × width per day
                  child: Stack(
                    children: [
                      // Grid lines
                      Column(
                        children: List.generate(endHour - startHour + 1, (index) {
                          return Container(
                            height: hourHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: Colors.grey[800]!.withValues(alpha: 0.5),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      
                      // Vertical day dividers
                      Row(
                        children: List.generate(7, (index) {
                          return Container(
                            width: 90,
                            height: (endHour - startHour + 1) * hourHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: Colors.grey[800]!.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      
                      // Event cards positioned by time
                      ...allEvents.map((event) {
                        final startHourEvent = _parseHour(event.startTime);
                        final endHourEvent = _parseHour(event.endTime);
                        final top = (startHourEvent - startHour) * hourHeight;
                        final height = (endHourEvent - startHourEvent) * hourHeight;
                        final left = event.dayOfWeek * 90.0 + 2;
                        
                        return Positioned(
                          top: top.clamp(0, double.infinity),
                          left: left,
                          width: 86,
                          height: height.clamp(hourHeight * 0.8, double.infinity),
                          child: _TimeGridEventCard(event: event),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
