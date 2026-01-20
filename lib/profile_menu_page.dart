import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'widgets/animated_components.dart';
import 'settings_page.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'account_page.dart';

// Helper function to get initials from a name
String _getInitials(String name) {
  if (name.isEmpty) return '?';
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return parts[0][0].toUpperCase();
}

class ProfileMenuPage extends StatefulWidget {
  const ProfileMenuPage({super.key});

  @override
  State<ProfileMenuPage> createState() => _ProfileMenuPageState();
}

class _ProfileMenuPageState extends State<ProfileMenuPage> {
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    // Background Colors - New Ocean Sunset
    const Color topColor = AppTheme.deepNavy;
    const Color bottomColor = AppTheme.midnightBlue;

    if (_uid == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [topColor, bottomColor],
            ),
          ),
          child: Center(
            child: Text('Not signed in', style: TextStyle(color: Colors.white)),
          ),
        ),
      );
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(_uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bottomColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        
        // Default data if profile not found or empty
        final data = snap.data?.data() ?? {};
        final fullName = (data['fullName'] ?? data['name'] ?? 'User Name') as String;
        // Use profilePictureUrl from onboarding, fallback to photoUrl
        final photoUrl = data['profilePictureUrl'] ?? data['photoUrl'] as String?;
        
        return Scaffold(
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
              // 2. Ambient Glow Orbs (Optimized)
              // Top-left: Electric Blue glow
              Positioned(
                top: -100,
                left: -60,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                         const Color(0xFF2196F3).withValues(alpha: 0.25), // Electric Blue
                         Colors.transparent,
                      ],
                      stops: const [0.0, 0.7],
                    ),
                  ),
                ),
              ),
              // Top-right: Mint Green glow
              Positioned(
                top: -80,
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

              // Main Content
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // 3. Header Section
                      Stack(
                        children: [
                          // Back Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _GlassIconButton(
                              margin: const EdgeInsets.only(left: 4),
                              icon: Icons.chevron_left,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ),
                          // Title
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10), // Align vertically with button
                              child: Text(
                                "Profile / Settings",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 4. Welcome Card (Hero Section)
                      _GlassCard(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.cyan.withValues(alpha: 0.5),
                                  width: 1,
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
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            
                            // Text Section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome",
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fullName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Logout Icon
                            _GlassIconButton(
                              icon: Icons.logout_rounded,
                              iconColor: const Color(0xFFF43F5E),
                              onTap: () async {
                                await FirebaseAuth.instance.signOut();
                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(
                                        builder: (context) => const LoginPage(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 5. Menu Items Section
                      // Card 1: Profile
                      _MenuCard(
                        title: "Profile",
                        icon: Icons.person,
                        gradientColors: [
                          const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          const Color(0xFF06B6D4).withValues(alpha: 0.2),
                        ],
                        onTap: () {
                           // Navigate to the detailed Profile Page
                           Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ProfilePage(),
                                ),
                              );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Card 2: Account
                      _MenuCard(
                        title: "Account",
                        icon: Icons.person_outline, // Or letter "O" / user circle
                        gradientColors: [
                          const Color(0xFF10B981).withValues(alpha: 0.2),
                          const Color(0xFF14B8A6).withValues(alpha: 0.2),
                        ],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AccountPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),

                      // Card 3: Settings
                      _MenuCard(
                        title: "Settings",
                        icon: Icons.settings,
                        gradientColors: [
                          const Color(0xFF2196F3).withValues(alpha: 0.2), // Electric Blue
                          const Color(0xFF122A46).withValues(alpha: 0.4), // Midnight Blue
                        ],
                        onTap: () {Navigator.of(context).push(
                          MaterialPageRoute<void>(
                             builder: (_) => const SettingsPage(),
                          ),
                       );},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      onTap: onTap,
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          
          // Label
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          // Arrow
          Icon(
            Icons.chevron_right,
            color: Colors.white.withValues(alpha: 0.4),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color? iconColor;
  final EdgeInsetsGeometry? margin;

  const _GlassIconButton({
    required this.onTap,
    required this.icon,
    this.iconColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.1),
            offset: const Offset(0, 10),
            blurRadius: 15,
            spreadRadius: -13,
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
