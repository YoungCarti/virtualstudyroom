import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_fonts.dart';

import 'study_room_detail_page.dart';

// Ocean Sunset Color Palette
const Color _deepNavy = Color(0xFF0A1929);      // Background base
const Color _midnightBlue = Color(0xFF122A46);  // Cards/containers
const Color _electricBlue = Color(0xFF2196F3);  // Primary actions
const Color _coralPink = Color(0xFFFF6B6B);     // Accents/alerts
const Color _mintGreen = Color(0xFF4ECDC4);     // Success/positive
const Color _softOrange = Color(0xFFFFB347);    // Warnings/attention
const Color _pureWhite = Color(0xFFFFFFFF);     // Text

class StudyRoomsPage extends StatefulWidget {
  const StudyRoomsPage({super.key});

  @override
  State<StudyRoomsPage> createState() => _StudyRoomsPageState();
}

class _StudyRoomsPageState extends State<StudyRoomsPage> {
  
  void _showCreateRoomDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    int maxCapacity = 10;
    bool isPrivate = false;
    bool hasChat = true;
    bool hasVideo = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: _midnightBlue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _electricBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_home_rounded, color: _electricBlue),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Create Study Room',
                      style: AppFonts.clashGrotesk(
                        color: _pureWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Room Name
                Text('Room Name', style: _labelStyle()),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: _pureWhite),
                  decoration: _inputDecoration('e.g., Math Focus Room'),
                ),
                const SizedBox(height: 16),

                // Description
                Text('Description (optional)', style: _labelStyle()),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: _pureWhite),
                  maxLines: 2,
                  decoration: _inputDecoration('What will you study?'),
                ),
                const SizedBox(height: 20),

                // Capacity Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Max Capacity', style: _labelStyle()),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _electricBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$maxCapacity people',
                        style: AppFonts.clashGrotesk(
                          color: _electricBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: maxCapacity.toDouble(),
                  min: 2,
                  max: 50,
                  divisions: 48,
                  activeColor: _electricBlue,
                  inactiveColor: _pureWhite.withOpacity(0.2),
                  onChanged: (value) {
                    setModalState(() => maxCapacity = value.round());
                  },
                ),
                const SizedBox(height: 16),

                // Private Toggle
                _ToggleOption(
                  icon: Icons.lock_outline,
                  title: 'Private Room',
                  subtitle: 'Only people with link can join',
                  value: isPrivate,
                  onChanged: (val) => setModalState(() => isPrivate = val),
                ),
                const SizedBox(height: 12),

                // Features
                Text('Room Features', style: _labelStyle()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _FeatureChip(
                      icon: Icons.chat_bubble_outline,
                      label: 'Chat',
                      selected: hasChat,
                      onTap: () => setModalState(() => hasChat = !hasChat),
                    ),
                    const SizedBox(width: 12),
                    _FeatureChip(
                      icon: Icons.videocam_outlined,
                      label: 'Video',
                      selected: hasVideo,
                      onTap: () => setModalState(() => hasVideo = !hasVideo),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _electricBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a room name')),
                        );
                        return;
                      }
                      await _createRoom(
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        maxCapacity: maxCapacity,
                        isPrivate: isPrivate,
                        hasChat: hasChat,
                        hasVideo: hasVideo,
                      );
                      if (mounted) Navigator.pop(context);
                    },
                    child: Text(
                      'Create Room',
                      style: AppFonts.clashGrotesk(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _pureWhite,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createRoom({
    required String name,
    required String description,
    required int maxCapacity,
    required bool isPrivate,
    required bool hasChat,
    required bool hasVideo,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('study_rooms').add({
        'name': name,
        'description': description,
        'maxCapacity': maxCapacity,
        'isPrivate': isPrivate,
        'hasChat': hasChat,
        'hasVideo': hasVideo,
        'createdBy': user.uid,
        'createdByName': user.displayName ?? 'Anonymous',
        'createdAt': FieldValue.serverTimestamp(),
        'activeUsers': 1,
        'members': [user.uid],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room "$name" created!'),
            backgroundColor: _mintGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating room: $e'), backgroundColor: _coralPink),
        );
      }
    }
  }

  TextStyle _labelStyle() => AppFonts.clashGrotesk(
    color: _pureWhite.withOpacity(0.7),
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: _pureWhite.withOpacity(0.4)),
    filled: true,
    fillColor: _deepNavy,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _pureWhite.withOpacity(0.1)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _pureWhite.withOpacity(0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _electricBlue),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        title: Text(
          'Study Rooms',
          style: AppFonts.clashGrotesk(
            fontWeight: FontWeight.bold,
            color: _pureWhite,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: _pureWhite,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CreateRoomBanner(onCreatePressed: _showCreateRoomDialog),
              const SizedBox(height: 24),
              
              // Public Rooms
              const _SectionHeading(title: 'Public Rooms'),
              const SizedBox(height: 12),
              _RoomListFromFirestore(isPrivate: false),
              
              const SizedBox(height: 24),
              
              // Private Rooms (My Rooms)
              const _SectionHeading(title: 'My Private Rooms'),
              const SizedBox(height: 12),
              _RoomListFromFirestore(isPrivate: true, showOnlyUserRooms: true),
              
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _pureWhite,
                    side: const BorderSide(color: _electricBlue),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _showCreateRoomDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Create Room',
                    style: AppFonts.clashGrotesk(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Toggle Option Widget
class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _deepNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _pureWhite.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _softOrange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.clashGrotesk(color: _pureWhite, fontWeight: FontWeight.w600)),
                Text(subtitle, style: AppFonts.clashGrotesk(color: _pureWhite.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _mintGreen,
          ),
        ],
      ),
    );
  }
}

// Feature Chip Widget
class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _mintGreen.withOpacity(0.2) : _deepNavy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? _mintGreen : _pureWhite.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? _mintGreen : _pureWhite.withOpacity(0.6), size: 18),
            const SizedBox(width: 8),
            Text(label, style: AppFonts.clashGrotesk(color: selected ? _mintGreen : _pureWhite.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }
}

// Firestore Room List
class _RoomListFromFirestore extends StatelessWidget {
  const _RoomListFromFirestore({required this.isPrivate, this.showOnlyUserRooms = false});

  final bool isPrivate;
  final bool showOnlyUserRooms;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    Query query = FirebaseFirestore.instance
        .collection('study_rooms')
        .where('isPrivate', isEqualTo: isPrivate)
        .orderBy('createdAt', descending: true)
        .limit(10);

    if (showOnlyUserRooms && userId != null) {
      query = FirebaseFirestore.instance
          .collection('study_rooms')
          .where('isPrivate', isEqualTo: true)
          .where('createdBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(10);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _electricBlue));
        }

        if (snapshot.hasError) {
          print('Study Rooms Error: ${snapshot.error}');
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _coralPink.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _coralPink.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: _coralPink),
                const SizedBox(height: 8),
                Text(
                  'Index building... Please wait 2-3 minutes',
                  style: AppFonts.clashGrotesk(color: _coralPink, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Firestore is preparing the database',
                  style: AppFonts.clashGrotesk(color: _pureWhite.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _midnightBlue,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _pureWhite.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(Icons.meeting_room_outlined, color: _pureWhite.withOpacity(0.3), size: 40),
                const SizedBox(height: 8),
                Text(
                  isPrivate ? 'No private rooms yet' : 'No public rooms yet',
                  style: AppFonts.clashGrotesk(color: _pureWhite.withOpacity(0.5)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first to create one!',
                  style: AppFonts.clashGrotesk(color: _pureWhite.withOpacity(0.3), fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _RoomCard(
              roomId: docs[index].id,
              name: data['name'] ?? 'Untitled Room',
              activeUsers: data['activeUsers'] ?? 0,
              maxCapacity: data['maxCapacity'] ?? 10,
              hasChat: data['hasChat'] ?? true,
              hasVideo: data['hasVideo'] ?? true,
              createdByName: data['createdByName'] ?? 'Anonymous',
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: docs.length,
        );
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppFonts.clashGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _pureWhite,
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.roomId,
    required this.name,
    required this.activeUsers,
    required this.maxCapacity,
    required this.hasChat,
    required this.hasVideo,
    required this.createdByName,
  });

  final String roomId;
  final String name;
  final int activeUsers;
  final int maxCapacity;
  final bool hasChat;
  final bool hasVideo;
  final String createdByName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _midnightBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _pureWhite.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room Name
          Text(
            name,
            style: AppFonts.clashGrotesk(
              fontWeight: FontWeight.bold,
              color: _pureWhite,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          
          // Online count with green dot
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _mintGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$activeUsers online',
                style: AppFonts.clashGrotesk(
                  color: _pureWhite.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Capacity: $activeUsers/$maxCapacity')),
                  );
                },
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: _pureWhite.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Full-width Join button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF5865F2), // Discord blue
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: activeUsers >= maxCapacity ? null : () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StudyRoomDetailPage(roomName: name),
                  ),
                );
              },
              child: Text(
                activeUsers >= maxCapacity ? 'Full' : 'Join',
                style: AppFonts.clashGrotesk(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: _pureWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _mintGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: _mintGreen),
    );
  }
}

class _CreateRoomBanner extends StatelessWidget {
  const _CreateRoomBanner({required this.onCreatePressed});

  final VoidCallback onCreatePressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_electricBlue, _mintGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _electricBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need a private focus room?',
                  style: AppFonts.clashGrotesk(
                    color: _pureWhite,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create a room for your study group in seconds.',
                  style: AppFonts.clashGrotesk(
                    color: _pureWhite.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _pureWhite,
              foregroundColor: _deepNavy,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onCreatePressed,
            child: Text(
              'Create',
              style: AppFonts.clashGrotesk(
                fontWeight: FontWeight.w700,
                color: _deepNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
