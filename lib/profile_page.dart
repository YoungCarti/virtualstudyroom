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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Background
    // Base Color: Deep dark purple (#1A1625 to #231B2E gradient)
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1625),
                  Color(0xFF231B2E),
                ],
              ),
            ),
          ),
          // Ambient Glow: Radial gradient with violet/purple glow emanating from top-center
          Positioned(
            top: -100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C3AED).withValues(alpha: 0.3), // Violet
                      Colors.transparent,
                    ],
                    radius: 0.8,
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          // Subtle noise/grain texture (Optional - skipped for simplicity/performance or use an image asset if available)

          // Content
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
                      final fullName = (data['fullName'] ?? data['name'] ?? 'Saabiresh Letchumanan') as String;
                      final program = (data['program'] ?? 'Bachelor of Computer Science (Hons.)') as String;
                      // final role = (data['role'] ?? 'Student') as String;
                      final joinedDate = _formatCreatedAt(data['createdAt']);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            // 2. Top Navigation Bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _GlassNavButton(
                                    icon: Icons.chevron_left,
                                    onTap: () => Navigator.of(context).pop(),
                                  ),
                                  _GlassNavButton(
                                    icon: Icons.settings, // Or search
                                    onTap: () {
                                      // Navigate to Edit Profile or Settings
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

                            const SizedBox(height: 30), // ~60dp from top including nav bar height

                            // 3. Profile Section (Top)
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
                                  image: NetworkImage('https://i.pravatar.cc/150?img=11'), // Placeholder
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
                                color: const Color(0xFF22D3EE).withValues(alpha: 0.12),
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

                            // 4. Stats Row
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

                            // 5. Program Card (Glassmorphism)
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
                                            Color(0xFFA855F7).withValues(alpha: 0.2),
                                            Color(0xFF8B5CF6).withValues(alpha: 0.2),
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
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // 6. Campus/Streak Cards (Swipeable PageView)
                            SizedBox(
                              height: 140, // Height for cards + shadow
                              child: PageView(
                                controller: _pageController,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  // Frame 1: Campus Cards
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _InfoCard(
                                            overlayGradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                const Color(0xFF06B6D4).withValues(alpha: 0.1),
                                                const Color(0xFF06B6D4).withValues(alpha: 0.1),
                                                const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                              ],
                                            ),
                                            icon: Icons.location_on_outlined,
                                            iconColor: const Color(0xFF22D3EE),
                                            label: "Campus",
                                            title: "Management & Science University (MSU)",
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _InfoCard(
                                            overlayGradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                const Color(0xFF10B981).withValues(alpha: 0.1),
                                                const Color(0xFF14B8A6).withValues(alpha: 0.1),
                                              ],
                                            ),
                                            icon: Icons.group_outlined,
                                            iconColor: const Color(0xFF22D3EE),
                                            label: "Fav Group",
                                            title: "Machine Learning Room",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Frame 2: Streak Cards
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: _InfoCard(
                                            overlayGradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                const Color(0xFFF97316).withValues(alpha: 0.1),
                                                const Color(0xFFF97316).withValues(alpha: 0.1),
                                                const Color(0xFFEF4444).withValues(alpha: 0.1),
                                              ],
                                            ),
                                            iconWidget: Container(
                                              width: 40, height: 40,
                                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                                              child: const Icon(Icons.local_fire_department, color: Color(0xFFF97316), size: 24),
                                            ),
                                            label: "Current Streak",
                                            title: "47 days",
                                            isLargeValue: true,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _InfoCard(
                                            overlayGradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                const Color(0xFFF59E0B).withValues(alpha: 0.1),
                                                const Color(0xFFEAB308).withValues(alpha: 0.1),
                                              ],
                                            ),
                                            iconWidget: Container(
                                              width: 40, height: 40,
                                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.transparent),
                                              child: const Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 24),
                                            ),
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
                              count: 2, // 2 pages
                              effect: const ScrollingDotsEffect(
                                activeDotColor: Colors.white, // 0.8 opacity handled by color or effect
                                dotColor: Colors.white30,
                                dotHeight: 6,
                                dotWidth: 6,
                                activeDotScale: 1.3, // To make active dot ~8px
                                spacing: 6,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 7. Bio Section
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
                                      "Passionate computer science student with a love for problem-solving and algorithms. Always eager to learn new technologies and collaborate on exciting projects.🔬",
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

                            // 8. Interests Section
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
                                      children: const [
                                        _InterestTag(label: "Machine Learning", color: Color(0xFF7C3AED)),
                                        _InterestTag(label: "Web Development", color: Color(0xFF0D9488)),
                                        _InterestTag(label: "Data Science", color: Color(0xFF0D9488)), // Reusing teal
                                        _InterestTag(label: "Cybersecurity", color: Color(0xFFEA580C)),
                                        _InterestTag(label: "Mobile Apps", color: Color(0xFFDC2626)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
        return '${dt.year}'; // Just year for "Joined"
      }
      return '2025';
    } catch (_) {
      return '2025';
    }
  }
}

class _GlassNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                offset: const Offset(0, 1), // Subtle top glow simulation
                blurRadius: 0,
                spreadRadius: 0,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Gradient overlayGradient;
  final IconData? icon;
  final Color? iconColor;
  final Widget? iconWidget;
  final String label;
  final String title;
  final bool isLargeValue;

  const _InfoCard({
    required this.overlayGradient,
    this.icon,
    this.iconColor,
    this.iconWidget,
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
            color: const Color(0xFF000000).withValues(alpha: 0.4),
            offset: const Offset(0, 25),
            blurRadius: 50,
            spreadRadius: -12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFFFFF).withValues(alpha: 0.08),
                  const Color(0xFFFFFFFF).withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFFFFF).withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: overlayGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  iconWidget ?? Icon(icon, color: iconColor, size: 24),
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
        color: color,
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
