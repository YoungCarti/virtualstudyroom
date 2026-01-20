import 'app_fonts.dart';
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
    final Color topColor = const Color(0xFF0A1929); // Deep Navy
    final Color bottomColor = const Color(0xFF122A46); // Midnight Blue

    return Scaffold(
      backgroundColor: const Color(0xFF0A1929), // Deep Navy Base
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

          // 2. Ambient Glow Orbs (Optimized with RadialGradient)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2196F3).withValues(alpha: 0.3), // Electric Blue
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4ECDC4).withValues(alpha: 0.2), // Mint Green
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
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
                      final program = (data['program'] ?? '') as String; // Empty if not set
                      final campus = (data['campus'] ?? '') as String; // Empty if not set
                      final favGroup = (data['favGroup'] ?? 'Study Group A') as String;
                      final bio = (data['bio'] ?? '') as String; // Empty by default
                      final interests = List<String>.from(data['interests'] ?? []);
                      final joinedDate = _formatCreatedAt(data['createdAt']);
                      
                      final currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;
                      final longestStreak = (data['longestStreak'] as num?)?.toInt() ?? 0;
                      // Use profilePictureUrl from onboarding, fallback to photoUrl
                      final photoUrl = (data['profilePictureUrl'] ?? data['photoUrl']) as String?;

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
                                color: photoUrl == null ? const Color(0xFF2196F3) : null,
                                image: photoUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(photoUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: photoUrl == null
                                  ? Center(
                                      child: Text(
                                        _getInitials(fullName),
                                        style: AppFonts.clashGrotesk(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              fullName,
                              style: AppFonts.clashGrotesk(
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
                                color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.school, color: Color(0xFF2196F3), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Active Student",
                                    style: AppFonts.clashGrotesk(
                                      color: const Color(0xFF2196F3),
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
                                            const Color(0xFF122A46).withValues(alpha: 0.8),
                                            const Color(0xFF2196F3).withValues(alpha: 0.4),
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
                                            style: AppFonts.clashGrotesk(
                                              color: Colors.white.withValues(alpha: 0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            program,
                                            style: AppFonts.clashGrotesk(
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
                                              const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                                              const Color(0xFF2196F3).withValues(alpha: 0.1),
                                            ],
                                            icon: Icons.location_on_outlined,
                                            iconColor: const Color(0xFF4ECDC4),
                                            label: "Campus",
                                            title: campus,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _InfoCard(
                                            colors: [
                                              const Color(0xFF2196F3).withValues(alpha: 0.1),
                                              const Color(0xFF122A46).withValues(alpha: 0.3),
                                            ],
                                            icon: Icons.group_outlined,
                                            iconColor: const Color(0xFF2196F3),
                                            label: "Fav Group",
                                            title: favGroup,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Page 2: Streak (Real Data)
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
                                            title: "$currentStreak days",
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
                                            title: "$longestStreak days",
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

                            // Bio Section - Only show if bio is not empty
                            if (bio.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _GlassContainer(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.person_outline, color: Color(0xFF2196F3), size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Bio",
                                            style: AppFonts.clashGrotesk(
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
                                        style: AppFonts.clashGrotesk(
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
                            ],

                            // Interests Section - Only show if interests are not empty
                            if (interests.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: _GlassContainer(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.favorite_outline, color: Color(0xFF2196F3), size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            "Interests",
                                            style: AppFonts.clashGrotesk(
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

                            const SizedBox(height: 16),

                            // Badges Section
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _GlassContainer(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.emoji_events_outlined, color: Color(0xFF2196F3), size: 16),
                                        const SizedBox(width: 8),
                                        Text(
                                          "Earned Badges",
                                          style: AppFonts.clashGrotesk(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _BadgeItem(
                                          id: 'perfect_score', 
                                          hasBadge: (data['badges'] as List?)?.contains('perfect_score') ?? false,
                                          label: 'Perfect Score',
                                          icon: Icons.star_rounded,
                                          color: const Color(0xFFFFD700), // Gold
                                        ),
                                        _BadgeItem(
                                          id: 'night_owl', 
                                          hasBadge: (data['badges'] as List?)?.contains('night_owl') ?? false,
                                          label: 'Night Owl',
                                          icon: Icons.nightlight_round,
                                          color: const Color(0xFF90CAF9), // Light Blue
                                        ),
                                        _BadgeItem(
                                          id: 'flashcard_master', 
                                          hasBadge: (data['badges'] as List?)?.contains('flashcard_master') ?? false,
                                          label: 'Flashcard Master',
                                          icon: Icons.style,
                                          color: const Color(0xFFAB47BC), // Purple
                                        ),
                                      ],
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

  static String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
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
          style: AppFonts.clashGrotesk(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppFonts.clashGrotesk(
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF122A46).withValues(alpha: 0.5), // Midnight Blue semi-transparent
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: child,
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
                      style: AppFonts.clashGrotesk(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: AppFonts.clashGrotesk(
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
        style: AppFonts.clashGrotesk(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final String id;
  final bool hasBadge;
  final String label;
  final IconData icon;
  final Color color;

  const _BadgeItem({
    required this.id,
    required this.hasBadge,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: hasBadge ? 1.0 : 0.3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: hasBadge ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ] : [],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppFonts.clashGrotesk(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}