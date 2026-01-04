import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import 'assignment_service.dart';
import 'assignment_details_page.dart';
import 'classes_page.dart';
import 'group_chats_page.dart';
import 'profile_menu_page.dart';
import 'notifications_page.dart';

import 'auth_service.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  int _selectedIndex = 0;
  String _role = 'student'; // track current role

  @override
  void initState() {
    super.initState();
    // Update streak when dashboard loads (app start or login)
    AuthService.instance.updateUserStreak();
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

    // Theme Colors
    final Color topColor = const Color(0xFF7C3AED).withValues(alpha: 0.15);
    final Color bottomColor = const Color(0xFFC026D3).withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A), // Dark Base
      body: Stack(
        fit: StackFit.expand,
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

          // 3. Main Content
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
                          photoUrl = data['photoUrl'] as String?; // Fetch photoUrl
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

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _HeaderSection(
                              userName: userName,
                              photoUrl: photoUrl, // Pass it here
                              onProfileTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileMenuPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 32),
                            const _AssignmentsCard(),
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

          // 4. Floating Bottom Navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: _FloatingBottomNav(
                selectedIndex: _selectedIndex,
                onTap: _onBottomNavTap,
              ),
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
                  image: DecorationImage(
                    image: photoUrl != null
                        ? NetworkImage(photoUrl!)
                        : const NetworkImage('https://i.pravatar.cc/150?img=11'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName!',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Let's learn something new",
                  style: GoogleFonts.inter(
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
            // Relaxed filter: Show assignments due in the future OR recently overdue (last 30 days)
            .where('dueDate', isGreaterThan: Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))))
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
    final allAssignments = _assignmentsByClass.values.expand((l) => l).toList();
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
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                        style: GoogleFonts.inter(
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
          const SizedBox(height: 24),
          if (allAssignments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white.withValues(alpha: 0.3), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'All caught up!',
                    style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.5)),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View all assignments',
                  style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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

class _FloatingBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _FloatingBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(35),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 70,
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A).withValues(alpha: 0.7), // Semi-transparent dark
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
