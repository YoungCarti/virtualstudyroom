import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF7C3AED).withValues(alpha: 0.1), // Violet 10%
              Color(0xFFC026D3).withValues(alpha: 0.08), // Fuchsia 8%
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main Content
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
                          // Extract first name for "Hello, [Name]!"
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
                            const SizedBox(height: 24),
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
            // Floating Bottom Navigation
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Profile Picture
            GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2), // Subtle white glow/border
                    width: 2,
                  ),
                  image: const DecorationImage(
                    image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Notification Bell
            // Notification Bell
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsPage()),
                );
              },
              child: Stack(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white70,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2B2540), // Match background
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Hello, $userName!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600, // Semi-bold
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              "Today's effort, tomorrow's success",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), // White/60% opacity
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            const Text('💪', style: TextStyle(fontSize: 14)),
          ],
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

            return Container(
              padding: const EdgeInsets.all(20),
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Assignments Due',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (pendingCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFe63946),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '$pendingCount pending',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (assignments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No upcoming assignments!',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    ...assignments.map((a) => _AssignmentItem(
                          assignment: a,
                          isLecturer: isLecturer,
                        )),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View all assignments',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
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

    if (diff.inDays == 0 && diff.isNegative == false) {
      status = 'Today';
      statusColor = const Color(0xFFe63946);
    } else if (diff.inDays == 1) {
      status = 'Tomorrow';
      statusColor = const Color(0xFFf59e0b);
    } else if (diff.isNegative) {
      status = 'Overdue';
      statusColor = Colors.grey;
    } else {
      status = DateFormat('d MMM').format(assignment.dueDate);
      statusColor = const Color(0xFF3b82f6);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2d2140),
        borderRadius: BorderRadius.circular(16),
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
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        assignment.className.isNotEmpty ? assignment.className : assignment.classCode,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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
    return Container(
      height: 70,
      width: 280, // Constrain width for pill shape look
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2d1b4e), // Dark purple
        borderRadius: BorderRadius.circular(35),
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
          // Middle button -> Classes
          _NavIcon(
            icon: Icons.class_outlined,
            isSelected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          // Right button -> Group Chats
          _NavIcon(
            icon: Icons.forum_rounded,
            isSelected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
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
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              )
            : null,
        child: Icon(
          icon,
          color: isSelected
              ? const Color(0xFFd946ef) // Purple/Magenta filled/active
              : Colors.white.withValues(alpha: 0.6), // White/60% opacity
          size: 24,
        ),
      ),
    );
  }
}
