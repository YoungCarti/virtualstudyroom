import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
              const _CreateRoomBanner(),
              const SizedBox(height: 24),
              const _SectionHeading(title: 'Public Rooms'),
              const SizedBox(height: 12),
              _RoomList(rooms: _publicRooms),
              const SizedBox(height: 24),
              const _SectionHeading(title: 'Private Rooms'),
              const SizedBox(height: 12),
              _RoomList(rooms: _privateRooms),
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Room creation coming soon!')),
                    );
                  },
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

class _RoomList extends StatelessWidget {
  const _RoomList({required this.rooms});

  final List<_RoomInfo> rooms;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, index) => _RoomCard(info: rooms[index]),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: rooms.length,
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.info});

  final _RoomInfo info;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _midnightBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _pureWhite.withOpacity(0.1),
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
                  color: _electricBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.meeting_room_rounded,
                  color: _electricBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: AppFonts.clashGrotesk(
                        fontWeight: FontWeight.bold,
                        color: _pureWhite,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_rounded,
                          size: 16,
                          color: _pureWhite.withOpacity(0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${info.userCount} online',
                          style: AppFonts.clashGrotesk(
                            color: _pureWhite.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (info.hasChat) const _IconBadge(icon: Icons.chat_bubble_outline_rounded),
                  if (info.hasVideo) const _IconBadge(icon: Icons.videocam_rounded),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _electricBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StudyRoomDetailPage(roomName: info.name),
                  ),
                );
              },
              child: Text(
                'Join Now',
                style: AppFonts.clashGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
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
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _mintGreen.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 18,
        color: _mintGreen,
      ),
    );
  }
}

class _CreateRoomBanner extends StatelessWidget {
  const _CreateRoomBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _electricBlue,
            _mintGreen,
          ],
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
                  'Spin up a session for your class or study clan in seconds.',
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create flow coming soon!')),
              );
            },
            child: Text(
              'Create Room',
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

class _RoomInfo {
  const _RoomInfo(this.name, this.userCount, this.hasChat, this.hasVideo);

  final String name;
  final int userCount;
  final bool hasChat;
  final bool hasVideo;
}
