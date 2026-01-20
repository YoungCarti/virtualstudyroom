import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_fonts.dart';

// Ocean Sunset Color Palette
const Color _deepNavy = Color(0xFF0A1929);
const Color _midnightBlue = Color(0xFF122A46);
const Color _electricBlue = Color(0xFF2196F3);
const Color _coralPink = Color(0xFFFF6B6B);
const Color _mintGreen = Color(0xFF4ECDC4);
const Color _softOrange = Color(0xFFFFB347);
const Color _pureWhite = Color(0xFFFFFFFF);
const Color _discordBlue = Color(0xFF5865F2);

class StudyRoomDetailPage extends StatefulWidget {
  const StudyRoomDetailPage({super.key, required this.roomName});

  final String roomName;

  @override
  State<StudyRoomDetailPage> createState() => _StudyRoomDetailPageState();
}

class _StudyRoomDetailPageState extends State<StudyRoomDetailPage> {
  bool _micOn = true;
  bool _cameraOn = true;

  // Mock participants
  final List<_Participant> _participants = [
    _Participant('You', 'Studying Flutter', isYou: true, hasCamera: true, likes: 12),
    _Participant('Maya Chen', 'Deep Focus Mode', hasCamera: true, likes: 36, comments: 13),
    _Participant('Jess Patel', 'PHYSIOLOGY II diff tab~', hasCamera: true, likes: 17),
    _Participant('Marco Li', 'leave me a flower', hasCamera: true, likes: 1822, comments: 281),
    _Participant('Lena Gomez', 'Computing', hasCamera: true, likes: 63),
    _Participant('Ali Hassan', 'following classic pomodoro 50/10', hasCamera: true, likes: 70),
    _Participant('Chris Johnson', 'not in my prime today', hasCamera: true, likes: 18, comments: 3),
    _Participant('Sarah Kim', 'I have tulips and roses :3', hasCamera: true, likes: 463, comments: 65),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    
    // Responsive grid columns
    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    
    return Scaffold(
      backgroundColor: _deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(isMobile),
            
            // Video Grid
            Expanded(
              child: _buildVideoGrid(crossAxisCount, isMobile),
            ),
            
            // Bottom Controls
            _buildBottomControls(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _midnightBlue,
        border: Border(bottom: BorderSide(color: _pureWhite.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: _pureWhite),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          
          // Room Name
          Expanded(
            child: Text(
              widget.roomName,
              style: AppFonts.clashGrotesk(
                color: _pureWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Participant count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _pureWhite.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, size: 16, color: _mintGreen),
                const SizedBox(width: 6),
                Text(
                  '${_participants.length}',
                  style: AppFonts.clashGrotesk(
                    color: _pureWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(int crossAxisCount, bool isMobile) {
    return GridView.builder(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isMobile ? 8 : 12,
        mainAxisSpacing: isMobile ? 8 : 12,
        childAspectRatio: isMobile ? 4 / 3 : 16 / 10,
      ),
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        return _buildVideoTile(_participants[index], isMobile);
      },
    );
  }

  Widget _buildVideoTile(_Participant participant, bool isMobile) {
    // Generate a random gradient for the video placeholder
    final colors = [
      [const Color(0xFF2D4059), const Color(0xFF1A1A2E)],
      [const Color(0xFF3D2C8D), const Color(0xFF1A1A2E)],
      [const Color(0xFF1A4D2E), const Color(0xFF1A1A2E)],
      [const Color(0xFF4A1942), const Color(0xFF1A1A2E)],
      [const Color(0xFF2C3333), const Color(0xFF1A1A2E)],
    ];
    final colorPair = colors[participant.name.length % colors.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colorPair,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: participant.isYou 
            ? Border.all(color: _mintGreen, width: 2)
            : null,
      ),
      child: Stack(
        children: [
          // Video placeholder - simulated camera view
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: participant.hasCamera
                    ? _buildCameraPlaceholder(participant)
                    : Icon(
                        Icons.videocam_off,
                        size: 40,
                        color: _pureWhite.withOpacity(0.3),
                      ),
              ),
            ),
          ),

          // Viewer count badge (top left)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.remove_red_eye, size: 12, color: _pureWhite.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text(
                    '${math.Random().nextInt(100) + 10}',
                    style: AppFonts.clashGrotesk(
                      color: _pureWhite,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status badges (top right)
          if (participant.isYou)
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  _buildStatusBadge(Icons.emoji_events, _softOrange),
                  const SizedBox(width: 4),
                  _buildStatusBadge(Icons.local_fire_department, _coralPink),
                ],
              ),
            ),

          // Bottom info bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name and status
                  Row(
                    children: [
                      Text(
                        participant.name,
                        style: AppFonts.clashGrotesk(
                          color: _pureWhite,
                          fontSize: isMobile ? 12 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (participant.isYou) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: _mintGreen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '✓',
                            style: AppFonts.clashGrotesk(
                              color: _deepNavy,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      Icon(Icons.circle, size: 6, color: _mintGreen),
                    ],
                  ),
                  const SizedBox(height: 2),
                  
                  // Status text
                  Text(
                    participant.status,
                    style: AppFonts.clashGrotesk(
                      color: _pureWhite.withOpacity(0.7),
                      fontSize: isMobile ? 10 : 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 6),
                  
                  // Likes and comments
                  Row(
                    children: [
                      Icon(Icons.thumb_up, size: 12, color: _electricBlue),
                      const SizedBox(width: 4),
                      Text(
                        '${participant.likes}',
                        style: AppFonts.clashGrotesk(
                          color: _electricBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (participant.comments > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          '+${participant.comments}',
                          style: AppFonts.clashGrotesk(
                            color: _mintGreen,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPlaceholder(_Participant participant) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: _discordBlue.withOpacity(0.3),
          child: Text(
            participant.name[0].toUpperCase(),
            style: AppFonts.clashGrotesk(
              color: _pureWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _buildBottomControls(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: _midnightBlue,
        border: Border(top: BorderSide(color: _pureWhite.withOpacity(0.1))),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mic
            _buildControlButton(
              icon: _micOn ? Icons.mic : Icons.mic_off,
              isActive: _micOn,
              onTap: () => setState(() => _micOn = !_micOn),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            
            // Camera
            _buildControlButton(
              icon: _cameraOn ? Icons.videocam : Icons.videocam_off,
              isActive: _cameraOn,
              onTap: () => setState(() => _cameraOn = !_cameraOn),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            
            // Screen Share (highlighted)
            _buildControlButton(
              icon: Icons.screen_share,
              isActive: false,
              isHighlight: true,
              onTap: () {},
            ),
            SizedBox(width: isMobile ? 12 : 16),
            
            // Chat
            _buildControlButton(
              icon: Icons.chat_bubble_outline,
              isActive: true,
              onTap: () {},
            ),
            
            SizedBox(width: isMobile ? 16 : 24),
            
            // Leave Button
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _coralPink,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: isMobile ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.call_end, size: 20, color: _pureWhite),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    bool isHighlight = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isHighlight 
              ? _coralPink.withOpacity(0.2) 
              : _pureWhite.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isActive 
              ? _pureWhite 
              : (isHighlight ? _coralPink : _coralPink),
        ),
      ),
    );
  }
}

class _Participant {
  final String name;
  final String status;
  final bool isYou;
  final bool hasCamera;
  final int likes;
  final int comments;

  _Participant(
    this.name,
    this.status, {
    this.isYou = false,
    this.hasCamera = false,
    this.likes = 0,
    this.comments = 0,
  });
}
