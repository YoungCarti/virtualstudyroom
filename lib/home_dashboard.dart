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

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  int _selectedIndex = 0;
  String _role = 'student'; // track current role

  void _onBottomNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
                child: SingleChildScrollView(
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
                      if (snapshot.hasData && snapshot.data!.data() != null) {
                        final data = snapshot.data!.data()!;
                        userName = (data['fullName'] ?? data['name'] ?? 'User') as String;
                        if (userName.contains(' ')) {
                          userName = userName.split(' ')[0];
                        }
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
  });

  final VoidCallback onProfileTap;
  final String userName;

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
                  image: const DecorationImage(
                    image: NetworkImage('https://i.pravatar.cc/150?img=11'),
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

class _AssignmentsCard extends StatelessWidget {
  const _AssignmentsCard();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() ?? {};
        final enrolledClasses = List<String>.from(data['enrolledClasses'] ?? []);
        final role = data['role'] as String? ?? 'student';
        final isLecturer = role == 'lecturer';

        return FutureBuilder<List<Assignment>>(
          future: AssignmentService.instance.getUpcomingAssignments(enrolledClasses),
          builder: (context, assignmentSnapshot) {
            if (assignmentSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final assignments = assignmentSnapshot.data ?? [];
            final pendingCount = assignments.length;

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
                  if (assignments.isEmpty)
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
                    ...assignments.take(3).map((a) => _AssignmentItem( // Limit to 3 on dashboard
                          assignment: a,
                          isLecturer: isLecturer,
                        )),
                  
                  if (assignments.isNotEmpty) ...[
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
          },
        );
      },
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
