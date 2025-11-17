import 'package:flutter/material.dart';

import 'study_room_detail_page.dart';

const Color _primaryPurple = Color(0xFF6C63FF);
const Color _secondaryPurple = Color(0xFFB4A0FF);
const Color _backgroundTint = Color(0xFFF4F1FF);

class StudyRoomsPage extends StatelessWidget {
  const StudyRoomsPage({super.key});

  static final List<_RoomInfo> _publicRooms = [
    const _RoomInfo('Math Focus Room', 128, true, true),
    const _RoomInfo('Night Study Room', 86, true, false),
    const _RoomInfo('Exam Power Hour', 42, false, true),
  ];

  static final List<_RoomInfo> _privateRooms = [
    const _RoomInfo('Chem 201 Lab Group', 12, true, true),
    const _RoomInfo('History Seminar Crew', 9, true, false),
    const _RoomInfo('CS Capstone Pod', 6, false, true),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF10101C) : _backgroundTint,
      appBar: AppBar(
        title: const Text('Study Rooms'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1F1F33),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CreateRoomBanner(isDark: isDark),
              const SizedBox(height: 24),
              _SectionHeading(title: 'Public Rooms'),
              const SizedBox(height: 12),
              _RoomList(rooms: _publicRooms, isDark: isDark),
              const SizedBox(height: 24),
              _SectionHeading(title: 'Private Rooms'),
              const SizedBox(height: 12),
              _RoomList(rooms: _privateRooms, isDark: isDark),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? Colors.white : const Color(0xFF1F1F33),
                    side: BorderSide(
                      color: isDark ? Colors.white24 : _primaryPurple,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Room creation coming soon!')),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Create Room',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF1E1E33),
          ),
    );
  }
}

class _RoomList extends StatelessWidget {
  const _RoomList({required this.rooms, required this.isDark});

  final List<_RoomInfo> rooms;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, index) => _RoomCard(
        info: rooms[index],
        isDark: isDark,
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: rooms.length,
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.info, required this.isDark});

  final _RoomInfo info;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, 18),
            spreadRadius: -16,
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.meeting_room_rounded,
                  color: _primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1F1F33),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 18,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${info.userCount} online',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF5C5C7A),
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (info.hasChat)
                    _IconBadge(
                      icon: Icons.chat_bubble_outline_rounded,
                      isDark: isDark,
                    ),
                  if (info.hasVideo)
                    _IconBadge(
                      icon: Icons.videocam_rounded,
                      isDark: isDark,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _primaryPurple,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StudyRoomDetailPage(roomName: info.name),
                  ),
                );
              },
              child: const Text(
                'Join Now',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
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
  const _IconBadge({required this.icon, required this.isDark});

  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white12 : _secondaryPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        size: 18,
        color: isDark ? Colors.white : _primaryPurple,
      ),
    );
  }
}

class _CreateRoomBanner extends StatelessWidget {
  const _CreateRoomBanner({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryPurple,
            _secondaryPurple,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.3),
            blurRadius: 40,
            offset: const Offset(0, 18),
            spreadRadius: -12,
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
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Spin up a session for your class or study clan in seconds.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? Colors.black : Colors.white,
              foregroundColor: isDark ? Colors.white : _primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create flow coming soon!')),
              );
            },
            child: const Text(
              'Create Room',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomInfo {
  const _RoomInfo(this.name, this.userCount, this.hasChat, this.hasVideo);

  final String name;
  final int userCount;
  final bool hasChat;
  final bool hasVideo;
}

