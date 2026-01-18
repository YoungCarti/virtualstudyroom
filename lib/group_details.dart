import 'app_fonts.dart';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupDetailsPage extends StatelessWidget {
  const GroupDetailsPage({
    super.key,
    required this.classCode,
    required this.groupId,
    required this.groupName,
  });

  final String classCode;
  final String groupId;
  final String groupName;

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
            top: -100,
            right: -50,
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
            left: -80,
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
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GlassIconButton(
                        icon: Icons.chevron_left,
                        onTap: () => Navigator.pop(context),
                      ),
                      Text(
                        groupName,
                        style: AppFonts.clashGrotesk(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 44), // Placeholder for alignment
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Members',
                          style: AppFonts.clashGrotesk(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('classes')
                              .doc(classCode)
                              .collection('groups')
                              .doc(groupId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return Text(
                                'Group not found.',
                                style: AppFonts.clashGrotesk(color: Colors.white54),
                              );
                            }

                            final groupData = snapshot.data!.data()!;
                            final memberIds = List<String>.from(groupData['members'] ?? <dynamic>[]);

                            if (memberIds.isEmpty) {
                              return Text(
                                'No members in this group yet.',
                                style: AppFonts.clashGrotesk(color: Colors.white54),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: memberIds.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (_, i) {
                                final memberId = memberIds[i];

                                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                  future: FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(memberId)
                                      .get(),
                                  builder: (context, userSnap) {
                                    if (!userSnap.hasData) {
                                      return const SizedBox.shrink();
                                    }

                                    final userData = userSnap.data?.data() ?? {};
                                    final name = userData['fullName'] ?? userData['name'] ?? 'Unknown';
                                    final email = userData['email'] ?? 'No email';

                                    return _MemberItem(name: name, email: email);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
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

// --- WIDGET HELPERS ---

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
                color: Colors.white.withValues(alpha: 0.1),
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

class _MemberItem extends StatelessWidget {
  final String name;
  final String email;

  const _MemberItem({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFA855F7).withValues(alpha: 0.2), // Purple tint
                  border: Border.all(
                    color: const Color(0xFFA855F7).withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: AppFonts.clashGrotesk(
                    color: const Color(0xFFA855F7),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppFonts.clashGrotesk(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: AppFonts.clashGrotesk(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}