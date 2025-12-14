import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'dart:async';
import 'profile_menu_page.dart';
import 'notifications_page.dart';
import 'group_chats_page.dart';
import 'classes_page.dart'; // added

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
    if (index == 1) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ClassesPage(role: _role),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      );
    } else if (index == 2) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const GroupChatsPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);
            return SlideTransition(position: offsetAnimation, child: child);
          },
        ),
      );
    }
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
          children: [
            // Main Content
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
                        const SizedBox(height: 24),
                        const _FeatureGrid(),
                      ],
                    );
                  },
                ),
              ),
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
                  MaterialPageRoute(builder: (context) => const NotificationsPage()),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF33264a), // Dark purple/gray background
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFe63946), // Red background
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      '3 pending',
                      style: TextStyle(
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
          const _AssignmentItem(
            title: 'Discrete Math',
            subject: 'Mathematics 2',
            status: 'Today',
            statusColor: Color(0xFFe63946), // Red
          ),
          const SizedBox(height: 12),
          const _AssignmentItem(
            title: 'Tutorial 1',
            subject: 'Programming Technique',
            status: 'Tomorrow',
            statusColor: Color(0xFFf59e0b), // Amber/Orange
          ),
          const SizedBox(height: 12),
          const _AssignmentItem(
            title: 'Group Assignment',
            subject: 'Industrial Workshop',
            status: '27 Nov',
            statusColor: Color(0xFF3b82f6), // Blue
          ),
          const SizedBox(height: 8), // Margin top 8px
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'View all assignments',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), // White/50%
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
  }
}

class _AssignmentItem extends StatelessWidget {
  final String title;
  final String subject;
  final String status;
  final Color statusColor;

  const _AssignmentItem({
    required this.title,
    required this.subject,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2d2140), // Slightly darker than container
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3), // White/30% opacity
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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subject,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), // White/50%
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
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1, // Adjusted for height ~140px
      children: const [
        _FeatureCard(
          titlePrefix: 'My',
          titleSuffix: 'Learnings',
          icon: Icons.book_outlined,
          gradientColors: [Color(0xFFa855f7), Color(0xFFec4899)], // Purple/Magenta
        ),
        _FeatureCard(
          titlePrefix: 'My',
          titleSuffix: 'Community',
          icon: Icons.groups_outlined, // Changed to groups for community
          gradientColors: [Color(0xFFf97316), Color(0xFFfb923c)], // Orange
        ),
        _FeatureCard(
          titlePrefix: 'AI Tutor',
          titleSuffix: 'Guidance',
          icon: Icons.smart_toy_outlined,
          gradientColors: [Color(0xFF475569), Color(0xFF334155)], // Dark Slate
        ),
        _FeatureCard(
          titlePrefix: 'Study',
          titleSuffix: 'Progress',
          icon: Icons.bar_chart_outlined, // Changed to bar chart
          gradientColors: [Color(0xFF14b8a6), Color(0xFF06b6d4)], // Teal/Cyan
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String titlePrefix;
  final String titleSuffix;
  final IconData icon;
  final List<Color> gradientColors;

  const _FeatureCard({
    required this.titlePrefix,
    required this.titleSuffix,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(0), // No background for icon in new spec
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titlePrefix,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                titleSuffix,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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
