import 'dart:math' as math;

import 'package:flutter/material.dart';

const Color _primaryPurple = Color(0xFF6C63FF);
const Color _secondaryPurple = Color(0xFFB4A0FF);
const Color _backgroundTint = Color(0xFFF4F1FF);

class StudyRoomDetailPage extends StatefulWidget {
  const StudyRoomDetailPage({super.key, required this.roomName});

  final String roomName;

  @override
  State<StudyRoomDetailPage> createState() => _StudyRoomDetailPageState();
}

class _StudyRoomDetailPageState extends State<StudyRoomDetailPage>
    with SingleTickerProviderStateMixin {
  bool _micOn = true;
  bool _cameraOn = false;
  bool _screenSharing = false;
  bool _aiAssistant = false;

  late final TabController _tabController =
      TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0E0E18) : _backgroundTint,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.roomName),
        foregroundColor: isDark ? Colors.white : const Color(0xFF1F1F33),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: isDark ? Colors.red[300] : Colors.redAccent,
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Exit'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1100;
            final isMedium = constraints.maxWidth >= 800;

            final leftPanel = _SidePanel(
              controller: _tabController,
              isDark: isDark,
            );
            final centerPanel = _SessionPanel(isDark: isDark);
            final rightPanel = _VideoPanel(isDark: isDark);

            Widget content;
            if (isWide) {
              content = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: leftPanel),
                  const SizedBox(width: 20),
                  Expanded(flex: 4, child: centerPanel),
                  const SizedBox(width: 20),
                  Expanded(flex: 3, child: rightPanel),
                ],
              );
            } else if (isMedium) {
              content = Column(
                children: [
                  SizedBox(height: 340, child: centerPanel),
                  const SizedBox(height: 20),
                  SizedBox(height: 320, child: rightPanel),
                  const SizedBox(height: 20),
                  leftPanel,
                ],
              );
            } else {
              content = Column(
                children: [
                  centerPanel,
                  const SizedBox(height: 16),
                  SizedBox(height: 240, child: rightPanel),
                  const SizedBox(height: 16),
                  SizedBox(height: 320, child: leftPanel),
                ],
              );
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: content,
                  ),
                ),
                _BottomToolbar(
                  micOn: _micOn,
                  cameraOn: _cameraOn,
                  screenSharing: _screenSharing,
                  aiAssistant: _aiAssistant,
                  onMicToggle: () => setState(() => _micOn = !_micOn),
                  onCameraToggle: () =>
                      setState(() => _cameraOn = !_cameraOn),
                  onScreenToggle: () =>
                      setState(() => _screenSharing = !_screenSharing),
                  onAiToggle: () => setState(() => _aiAssistant = !_aiAssistant),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.controller, required this.isDark});

  final TabController controller;
  final bool isDark;

  static final List<String> _messages = [
    'Jess: Finishing the practice set, need help?',
    'Marco: I can walk you through Q4!',
    'Lena: Timer at 10 mins, break soon?',
  ];

  static final List<String> _participants = [
    'Maya Chen (Host)',
    'Jess Patel',
    'Marco Li',
    'Lena Gomez',
    'Ali Hassan',
    'Chris Johnson',
  ];

  static final List<String> _tasks = [
    'Finish Calc Problem Set',
    'Outline History Essay',
    'Upload lab notes',
  ];

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? const Color(0xFF1A1A28) : Colors.white.withValues(alpha: 0.95);

    final tabBar = Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: _primaryPurple,
          borderRadius: BorderRadius.circular(18),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor:
            isDark ? Colors.white70 : const Color(0xFF5A5A74),
        tabs: const [
          Tab(text: 'Chat'),
          Tab(text: 'Participants'),
          Tab(text: 'Tasks'),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double tabHeight;
        if (constraints.maxHeight.isFinite) {
          tabHeight = (constraints.maxHeight - 72).clamp(220, 520);
        } else {
          tabHeight = 320;
        }

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 40,
                offset: const Offset(0, 24),
                spreadRadius: -20,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              tabBar,
              const SizedBox(height: 16),
              SizedBox(
                height: tabHeight,
                child: TabBarView(
                  controller: controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ListView.separated(
                      itemCount: _messages.length,
                      itemBuilder: (_, index) => _ChatBubble(
                        message: _messages[index],
                        isDark: isDark,
                        isSelf: index == 0,
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                    ),
                    ListView.separated(
                      itemCount: _participants.length,
                      itemBuilder: (_, index) => _ParticipantRow(
                        name: _participants[index],
                        isDark: isDark,
                        isHost: index == 0,
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                    ),
                    ListView.separated(
                      itemCount: _tasks.length,
                      itemBuilder: (_, index) => _TaskRow(
                        label: _tasks[index],
                        isDark: isDark,
                      ),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionPanel extends StatelessWidget {
  const _SessionPanel({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF202035), const Color(0xFF17172A)]
              : [Colors.white, _backgroundTint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 40,
            offset: const Offset(0, 28),
            spreadRadius: -25,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Focus Session',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF1F1F33),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _AnimatedTimerDial(isDark: isDark),
          const SizedBox(height: 16),
          Text(
            '25:00',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1F1F33),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current session progress',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.white70 : const Color(0xFF6A6A88),
                ),
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: 0.62,
            backgroundColor:
                isDark ? Colors.white12 : _secondaryPurple.withValues(alpha: 0.2),
            minHeight: 10,
            borderRadius: BorderRadius.circular(999),
            valueColor: const AlwaysStoppedAnimation<Color>(_primaryPurple),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: _primaryPurple,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ambient focus waves playing · Tap to change',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : const Color(0xFF4A4A66),
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ambient picker coming soon')),
                    );
                  },
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedTimerDial extends StatefulWidget {
  const _AnimatedTimerDial({required this.isDark});

  final bool isDark;

  @override
  State<_AnimatedTimerDial> createState() => _AnimatedTimerDialState();
}

class _AnimatedTimerDialState extends State<_AnimatedTimerDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _DialPainter(
              progress: 0.62,
              rotation: _controller.value,
              isDark: widget.isDark,
            ),
          );
        },
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.progress,
    required this.rotation,
    required this.isDark,
  });

  final double progress;
  final double rotation;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final basePaint = Paint()
      ..color = (isDark ? Colors.white12 : _secondaryPurple.withValues(alpha: 0.3))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 12, basePaint);

    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [_primaryPurple, _secondaryPurple, _primaryPurple],
        stops: const [0.0, 0.6, 1.0],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        transform: GradientRotation(rotation * 2 * math.pi),
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 12),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    final glowPaint = Paint()
      ..color = _primaryPurple.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawCircle(center, radius - 40, glowPaint);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.rotation != rotation ||
      oldDelegate.isDark != isDark;
}

class _VideoPanel extends StatelessWidget {
  const _VideoPanel({required this.isDark});

  final bool isDark;

  static final List<String> _videoUsers = [
    'Maya',
    'Jess',
    'Marco',
    'Lena',
  ];

  @override
  Widget build(BuildContext context) {
    final tileColor =
        isDark ? const Color(0xFF1D1D2F) : Colors.white.withValues(alpha: 0.95);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 40,
            offset: const Offset(0, 26),
            spreadRadius: -20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Live Video',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F1F33),
                    ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Silent Mode',
                  style: TextStyle(
                    color: _primaryPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              itemCount: _videoUsers.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (_, index) => _VideoTile(
                label: _videoUsers[index],
                isCameraOn: index.isOdd,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({
    required this.label,
    required this.isCameraOn,
    required this.isDark,
  });

  final String label;
  final bool isCameraOn;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color =
        isDark ? const Color(0xFF151523) : _secondaryPurple.withValues(alpha: 0.3);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCameraOn ? _primaryPurple : Colors.white24,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          if (isCameraOn)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _secondaryPurple.withValues(alpha: 0.3),
                      _primaryPurple.withValues(alpha: 0.25),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            )
          else
            const _SilentWave(),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isDark ? Colors.white24 : Colors.white,
                    child: Text(
                      label.characters.first,
                      style: TextStyle(
                        color: isDark ? Colors.white : _primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SilentWave extends StatefulWidget {
  const _SilentWave();

  @override
  State<_SilentWave> createState() => _SilentWaveState();
}

class _SilentWaveState extends State<_SilentWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WavePainter(progress: _controller.value),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    paint.color = Colors.white.withValues(alpha: 0.6);

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final phase = progress + i * 0.2;
      for (double x = 0; x <= size.width; x += 4) {
        final y = size.height / 2 +
            math.sin((x / size.width * 2 * math.pi) + phase * 2 * math.pi) *
                (20 + i * 10);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint..color = paint.color.withValues(alpha: 0.6 - i * 0.2));
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _BottomToolbar extends StatelessWidget {
  const _BottomToolbar({
    required this.micOn,
    required this.cameraOn,
    required this.screenSharing,
    required this.aiAssistant,
    required this.onMicToggle,
    required this.onCameraToggle,
    required this.onScreenToggle,
    required this.onAiToggle,
  });

  final bool micOn;
  final bool cameraOn;
  final bool screenSharing;
  final bool aiAssistant;
  final VoidCallback onMicToggle;
  final VoidCallback onCameraToggle;
  final VoidCallback onScreenToggle;
  final VoidCallback onAiToggle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131322) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          children: [
            _ToolbarButton(
              icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              label: micOn ? 'Mic On' : 'Mic Off',
              active: micOn,
              onTap: onMicToggle,
            ),
            const SizedBox(width: 12),
            _ToolbarButton(
              icon: cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
              label: cameraOn ? 'Camera On' : 'Camera Off',
              active: cameraOn,
              onTap: onCameraToggle,
            ),
            const SizedBox(width: 12),
            _ToolbarButton(
              icon: Icons.screen_share_rounded,
              label: screenSharing ? 'Sharing' : 'Share Screen',
              active: screenSharing,
              onTap: onScreenToggle,
            ),
            const Spacer(),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: aiAssistant ? _primaryPurple : Colors.white12,
                foregroundColor: aiAssistant ? Colors.white : _primaryPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: onAiToggle,
              icon: const Icon(Icons.smart_toy_rounded),
              label: const Text(
                'AI Assistant',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? _primaryPurple : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: active ? Colors.white : _primaryPurple,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : _primaryPurple,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isDark,
    required this.isSelf,
  });

  final String message;
  final bool isDark;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelf
              ? _primaryPurple
              : (isDark ? Colors.white12 : const Color(0xFFF0F0FF)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isSelf
                ? Colors.white
                : (isDark ? Colors.white : const Color(0xFF1F1F33)),
          ),
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.name,
    required this.isDark,
    required this.isHost,
  });

  final String name;
  final bool isDark;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isDark ? Colors.white24 : _secondaryPurple,
          child: Text(
            name.characters.first,
            style: TextStyle(
              color: isDark ? Colors.white : _primaryPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF1F1F33),
                ),
          ),
        ),
        if (isHost)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _primaryPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Host',
              style: TextStyle(
                color: _primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : const Color(0xFFF7F5FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: _primaryPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isDark ? Colors.white : const Color(0xFF1F1F33),
                  ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz),
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
        ],
      ),
    );
  }
}

