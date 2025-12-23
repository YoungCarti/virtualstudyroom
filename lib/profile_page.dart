import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  final PageController _pageController = PageController();

  // Interest Colors Palette
  final List<Color> _tagColors = [
    const Color(0xFF7C3AED), // Purple
    const Color(0xFF0D9488), // Teal
    const Color(0xFF3B82F6), // Blue
    const Color(0xFFDC2626), // Red
    const Color(0xFFEA580C), // Orange
    const Color(0xFFEC4899), // Pink
    const Color(0xFF10B981), // Green
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF06B6D4), // Cyan
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            top: -50,
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
            top: 100,
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
          SafeArea(
            child: _uid == null
                ? const Center(child: Text('Not signed in', style: TextStyle(color: Colors.white)))
                : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final data = snapshot.data?.data() ?? {};
                      final fullName = (data['fullName'] ?? data['name'] ?? 'Student Name') as String;
                      final program = (data['program'] ?? 'Bachelor of Computer Science') as String;
                      final campus = (data['campus'] ?? 'UNIMY') as String;
                      final favGroup = (data['favGroup'] ?? 'Study Group A') as String;
                      final bio = (data['bio'] ?? 'Computer science student passionate about coding and algorithms.') as String;
                      final interests = List<String>.from(data['interests'] ?? ['Coding', 'AI', 'Flutter']);
                      final joinedDate = _formatCreatedAt(data['createdAt']);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            
                            // Top Navigation Bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _GlassIconButton(
                                    icon: Icons.chevron_left,
                                    onTap: () => Navigator.of(context).pop(),
                                  ),
                                  _GlassIconButton(
                                    icon: Icons.edit_outlined,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => EditProfilePage(userDocId: _uid),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Profile Photo & Name
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 3,
                                ),
                                image: const DecorationImage(
                                  image: NetworkImage('https://i.pravatar.cc/150?img=11'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              fullName,
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF22D3EE).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.school, color: Color(0xFF22D3EE), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Active Student",
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF22D3EE),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _StatItem(number: "1.2K", label: "Followers"),
                                const SizedBox(width: 40),
                                _StatItem(number: "623", label: "Following"),
                                const SizedBox(width: 40),
                                _StatItem(number: joinedDate, label: "Joined"),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Program Card
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _GlassContainer(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            const Color(0xFFA855F7).withValues(alpha: 0.2),
                                            const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.school_outlined, color: Colors.white, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Program",
                                            style: GoogleFonts.inter(
                                              color: Colors.white.withValues(alpha: 0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            program,
                                            style: GoogleFonts.inter(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Horizontal Cards (PageView)
                            SizedBox(
                              height: 140,
                              child: PageView(
                                controller: _pageController,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  // Page 1: Campus & Group
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _InfoCard(
                                            colors: [
                                              const Color(0xFF06B6D4).withValues(alpha: 0.1),
                                              const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                            ],
                                            icon: Icons.location_on_outlined,
                                            iconColor: const Color(0xFF22D3EE),
                                            label: "Campus",
                                            title: campus,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _InfoCard(
                                            colors: [
                                              const Color(0xFF10B981).withValues(alpha: 0.1),
                                              const Color(0xFF14B8A6).withValues(alpha: 0.1),
                                            ],
                                            icon: Icons.group_outlined,
                                            iconColor: const Color(0xFF22D3EE),
                                            label: "Fav Group",
                                            title: favGroup,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Page 2: Streak (Example)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _InfoCard(
                                            colors: [
                                              const Color(0xFFF97316).withValues(alpha: 0.1),
                                              const Color(0xFFEF4444).withValues(alpha: 0.1),
                                            ],
                                            icon: Icons.local_fire_department,
                                            iconColor: const Color(0xFFF97316),
                                            label: "Current Streak",
                                            title: "47 days",
                                            isLargeValue: true,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _InfoCard(
                                            colors: [
                                              const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                              const Color(0xFFEAB308).withValues(alpha: 0.1),
                                            ],
                                            icon: Icons.emoji_events,
                                            iconColor: const Color(0xFFF59E0B),
                                            label: "Longest Streak",
                                            title: "89 days",
                                            isLargeValue: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            SmoothPageIndicator(
                              controller: _pageController,
                              count: 2,
                              effect: const ScrollingDotsEffect(
                                activeDotColor: Colors.white,
                                dotColor: Colors.white30,
                                dotHeight: 6,
                                dotWidth: 6,
                                activeDotScale: 1.3,
                                spacing: 6,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Bio Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _GlassContainer(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline, color: Color(0xFF22D3EE), size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Bio",
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      bio,
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Interests Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _GlassContainer(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.favorite_outline, color: Color(0xFF22D3EE), size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Interests",
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: interests.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final color = _tagColors[index % _tagColors.length];
                                        return _InterestTag(
                                          label: entry.value,
                                          color: color,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static String _formatCreatedAt(dynamic ts) {
    try {
      if (ts is Timestamp) {
        final dt = ts.toDate();
        return '${dt.year}';
      }
      return '2025';
    } catch (_) {
      return '2025';
    }
  }
}

// --- WIDGET HELPERS (Unified Style) ---

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String number;
  final String label;

  const _StatItem({required this.number, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          number,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassContainer({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2), // Darker glass
            borderRadius: BorderRadius.circular(20),
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

class _InfoCard extends StatelessWidget {
  final List<Color> colors;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String title;
  final bool isLargeValue;

  const _InfoCard({
    required this.colors,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.title,
    this.isLargeValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.2),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: iconColor, size: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: isLargeValue ? 24 : 14,
                        fontWeight: isLargeValue ? FontWeight.bold : FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InterestTag extends StatelessWidget {
  final String label;
  final Color color;

  const _InterestTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8), // Vibrant tags
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}