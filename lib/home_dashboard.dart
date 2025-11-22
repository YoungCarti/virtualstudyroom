import 'package:flutter/material.dart';

import 'profile_page.dart';
import 'study_rooms_page.dart';

const Color _darkBackground = Color(0xFF1C1C28);
const Color _cardBackground = Color(0xFF2A2A3E);
const Color _accentPurple = Color(0xFF8B7BFF);
const Color _limeGreen = Color(0xFFB8E986);
// Legacy colors for old widgets
const Color _primaryPurple = Color(0xFF6C63FF);
const Color _secondaryPurple = Color(0xFFB4A0FF);
const Color _backgroundTint = Color(0xFFF4F1FF);

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  int _selectedIndex = 0;

  static final List<_SubjectProgress> _subjects = [
    const _SubjectProgress('Biology', 0.72),
    const _SubjectProgress('Calculus', 0.45),
    const _SubjectProgress('World History', 0.86),
    const _SubjectProgress('Chemistry', 0.33),
  ];

  static final List<_TaskItem> _tasks = [
    const _TaskItem('Finish lab report', 'Due today · 5 PM'),
    const _TaskItem('Group study session', 'Tomorrow · 7 PM'),
    const _TaskItem('Revise chapter 6', 'Friday · 3 PM'),
  ];

  static final List<_FileItem> _files = [
    const _FileItem('Biology_notes.pdf', 'PDF · 2 MB'),
    const _FileItem('Calc_problem_set.docx', 'DOCX · 650 KB'),
    const _FileItem('History-slides.ppt', 'PPT · 4 MB'),
  ];

  static final List<_MetricCardData> _metrics = [
    const _MetricCardData(title: 'Presence', value: '89%', accent: Color(0xFFFF8A3D)),
    const _MetricCardData(title: 'Completeness', value: '100%', accent: Color(0xFF4185FF)),
    const _MetricCardData(title: 'Assignments', value: '18', accent: Color(0xFF4CB5FF)),
    const _MetricCardData(title: 'Subjects', value: '12', accent: Color(0xFFFFC24C)),
  ];

  static final List<_ScheduleItem> _schedule = [
    const _ScheduleItem(day: '7', subject: 'Economy', color: Color(0xFFFFE1B2)),
    const _ScheduleItem(day: '9', subject: 'Geography', color: Color(0xFFD0E8FF)),
    const _ScheduleItem(day: '11', subject: 'English', color: Color(0xFFE4E2FF)),
  ];

  void _onBottomNavTap(int index) {
    if (index == _selectedIndex && index == 0) return;
    
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to respective pages based on index
    switch (index) {
      case 0: // Home - already on this page
        break;
      case 1: // Calendar/Schedule
        setState(() {
          _selectedIndex = 0; // Reset to home
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule coming soon!')),
        );
        break;
      case 2: // Documents/Files
        setState(() {
          _selectedIndex = 0; // Reset to home
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documents coming soon!')),
        );
        break;
      default:
        break;
    }
  }

  void _showProfileMenu(BuildContext context, Offset position) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + 50, // Below the avatar
        position.dx + 200,
        0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 20,
                color: isDark ? Colors.white70 : const Color(0xFF6A6A84),
              ),
              const SizedBox(width: 12),
              Text(
                'Profile',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF2A2A40),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ProfilePage(),
                ),
              );
            });
          },
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                size: 20,
                color: isDark ? Colors.white70 : const Color(0xFF6A6A84),
              ),
              const SizedBox(width: 12),
              Text(
                'Settings',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF2A2A40),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          onTap: () {
            Future.delayed(Duration.zero, () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            });
          },
        ),
      ],
    );
  }

  void _handleQuickAction(String id) {
    switch (id) {
      case 'study_rooms':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const StudyRoomsPage(),
          ),
        );
        break;
      case 'subjects':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subjects overview coming soon!')),
        );
        break;
      case 'classes':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class schedule coming soon!')),
        );
        break;
      case 'presence':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Presence analytics coming soon!')),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _darkBackground : const Color(0xFFE5EDF7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ModernHeader(
                isDark: isDark,
                onProfileMenuTap: (offset) => _showProfileMenu(context, offset),
              ),
              const SizedBox(height: 24),
              _GreetingSection(isDark: isDark),
              const SizedBox(height: 24),
              _FocusRoomCard(isDark: isDark),
              const SizedBox(height: 20),
              _ActionTilesGrid(isDark: isDark),
              const SizedBox(height: 24),
              _TasksSection(isDark: isDark),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F1F2F) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _BottomNavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Home',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onBottomNavTap(0),
                  isDark: isDark,
                ),
                _BottomNavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Schedule',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onBottomNavTap(1),
                  isDark: isDark,
                ),
                _BottomNavItem(
                  icon: Icons.receipt_long_rounded,
                  label: 'Documents',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onBottomNavTap(2),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, Maya Chen',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1F1F33),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here is your activity today.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color:
                              isDark ? Colors.white70 : const Color(0xFF6A6A84),
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.notifications_none_rounded,
                color: isDark ? Colors.white : const Color(0xFF1F1F33),
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: isDark ? 0.1 : 0.9),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.metrics, required this.isDark});

  final List<_MetricCardData> metrics;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      itemBuilder: (_, index) {
        final metric = metrics[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F2F) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: metric.accent,
                    ),
              ),
              const Spacer(),
              Text(
                metric.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark ? Colors.white70 : const Color(0xFF5A5A74),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.onStudyRooms,
    required this.onSubjects,
    required this.onClasses,
    required this.onPresence,
  });

  final VoidCallback onStudyRooms;
  final VoidCallback onSubjects;
  final VoidCallback onClasses;
  final VoidCallback onPresence;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        label: 'Course',
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF0FADCF),
        onTap: onStudyRooms,
      ),
      _QuickActionData(
        label: 'Subjects',
        icon: Icons.school_rounded,
        color: const Color(0xFF132F82),
        onTap: onSubjects,
      ),
      _QuickActionData(
        label: 'Class',
        icon: Icons.class_rounded,
        color: const Color(0xFFF3A329),
        onTap: onClasses,
      ),
      _QuickActionData(
        label: 'Presence',
        icon: Icons.verified_user_rounded,
        color: const Color(0xFF2BB673),
        onTap: onPresence,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions
          .map(
            (action) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _QuickActionButton(data: action),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(height: 8),
          Text(
            data.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF59627A),
                ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleStrip extends StatelessWidget {
  const _ScheduleStrip({required this.items});

  final List<_ScheduleItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Text(
                        item.day,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF9BA4C2),
                            ),
                      ),
                      const SizedBox(height: 12),
                      _ScheduleCard(item: item),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.item});

  final _ScheduleItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          item.subject,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3E4A66),
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _QuickJoinCard extends StatelessWidget {
  const _QuickJoinCard({required this.isDark});

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
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _primaryPurple.withValues(alpha: 0.3),
            blurRadius: 35,
            offset: const Offset(0, 15),
            spreadRadius: -10,
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
                  'Quick Join Room',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jump back into your last focus room with one tap.',
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () {},
            child: const Text(
              'Join',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF2A2A40),
          ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.isDark});

  final _SubjectProgress subject;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2F2F4A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 25),
            spreadRadius: -20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Subject',
              style: TextStyle(
                color: _primaryPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Text(
            subject.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2A2A40),
                ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: subject.progress,
              backgroundColor: _backgroundTint,
              valueColor: const AlwaysStoppedAnimation<Color>(
                _primaryPurple,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(subject.progress * 100).round()}% complete',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white70 : const Color(0xFF5E5E74),
                ),
          ),
        ],
      ),
    );
  }
}

class _AiToolsCard extends StatelessWidget {
  const _AiToolsCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final tileColor =
        isDark ? const Color(0xFF2E2E44) : Colors.white.withValues(alpha: 0.9);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232336) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 35,
            offset: const Offset(0, 25),
            spreadRadius: -25,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Tools',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2A2A40),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AiToolTile(
                  title: 'AI Timer',
                  subtitle: 'Personalized Pomodoro',
                  icon: Icons.timer_rounded,
                  backgroundColor: tileColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _AiToolTile(
                  title: 'AI Study Coach',
                  subtitle: 'Adaptive tips & focus boosts',
                  icon: Icons.auto_awesome_rounded,
                  backgroundColor: tileColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.isDark, required this.tasks});

  final bool isDark;
  final List<_TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232336) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 25),
            spreadRadius: -25,
          ),
        ],
      ),
      child: Column(
        children: tasks
            .map(
              (task) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primaryPurple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark ? Colors.white : const Color(0xFF2A2A40),
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task.detail,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white70 : const Color(0xFF6C6C88),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isDark ? Colors.white54 : Colors.grey[400],
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RecentFilesList extends StatelessWidget {
  const _RecentFilesList({required this.isDark, required this.files});

  final bool isDark;
  final List<_FileItem> files;

  IconData _iconForFile(String name) {
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (name.endsWith('.doc') || name.endsWith('.docx')) {
      return Icons.description_rounded;
    }
    if (name.endsWith('.ppt') || name.endsWith('.pptx')) {
      return Icons.slideshow_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232336) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 25),
            spreadRadius: -25,
          ),
        ],
      ),
      child: Column(
        children: files
            .map(
              (file) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        _iconForFile(file.name),
                        color: _primaryPurple,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark ? Colors.white : const Color(0xFF2A2A40),
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            file.meta,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color:
                                      isDark ? Colors.white70 : const Color(0xFF6C6C88),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.more_horiz,
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AiToolTile extends StatelessWidget {
  const _AiToolTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: _primaryPurple,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2A2A40),
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF636381),
                ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isSelected 
        ? const Color(0xFF5BB5D9)
        : (isDark ? Colors.white54 : Colors.grey[400]);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
    );
  }
}

class _MetricCardData {
  const _MetricCardData({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;
}

class _QuickActionData {
  const _QuickActionData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _ScheduleItem {
  const _ScheduleItem({
    required this.day,
    required this.subject,
    required this.color,
  });

  final String day;
  final String subject;
  final Color color;
}

class _SubjectProgress {
  const _SubjectProgress(this.name, this.progress);

  final String name;
  final double progress;
}

class _TaskItem {
  const _TaskItem(this.title, this.detail);

  final String title;
  final String detail;
}

class _FileItem {
  const _FileItem(this.name, this.meta);

  final String name;
  final String meta;
}

// New Modern Widgets for Screenshot Design
class _ModernHeader extends StatelessWidget {
  const _ModernHeader({required this.isDark, required this.onProfileMenuTap});

  final bool isDark;
  final void Function(Offset) onProfileMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Profile Avatar with Lime Green - clickable
        GestureDetector(
          onTapDown: (TapDownDetails details) {
            onProfileMenuTap(details.globalPosition);
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _limeGreen,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'SL',
                style: TextStyle(
                  color: Color(0xFF2A2A3E),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        // Notification Icon
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF8B8B9F)),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF3A3A52),
          ),
        ),
      ],
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, Saabiresh!',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isDark ? Colors.white : const Color(0xFF1F1F33),
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'Today\'s effort, tomorrow\'s success ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? const Color(0xFF8B8B9F) : const Color(0xFF6A6A84),
                    fontSize: 15,
                  ),
            ),
            const Text(
              '💪',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}

class _FocusRoomCard extends StatelessWidget {
  const _FocusRoomCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? _cardBackground : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF3A3A52) : Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Focus Room 1',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: isDark ? Colors.white : const Color(0xFF1F1F33),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '498 online',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF8B8B9F) : const Color(0xFF6A6A84),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // User Avatars Row
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            child: _UserAvatar(
                              imageUrl: 'https://i.pravatar.cc/150?img=33',
                              borderColor: isDark ? _cardBackground : Colors.white,
                            ),
                          ),
                          Positioned(
                            left: 28,
                            child: _UserAvatar(
                              imageUrl: 'https://i.pravatar.cc/150?img=12',
                              borderColor: isDark ? _cardBackground : Colors.white,
                            ),
                          ),
                          Positioned(
                            left: 56,
                            child: _UserAvatar(
                              backgroundColor: const Color(0xFFB197FC),
                              text: 'SY',
                              borderColor: isDark ? _cardBackground : Colors.white,
                            ),
                          ),
                          Positioned(
                            left: 84,
                            child: _UserAvatar(
                              backgroundColor: const Color(0xFF74C0FC),
                              text: 'NZ',
                              borderColor: isDark ? _cardBackground : Colors.white,
                            ),
                          ),
                          Positioned(
                            left: 112,
                            child: _UserAvatar(
                              imageUrl: 'https://i.pravatar.cc/150?img=25',
                              borderColor: isDark ? _cardBackground : Colors.white,
                            ),
                          ),
                          Positioned(
                            left: 140,
                            child: _UserAvatar(
                              imageUrl: 'https://i.pravatar.cc/150?img=47',
                              borderColor: isDark ? _cardBackground : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accentPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: _accentPurple,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: Text(
              'See more',
              style: TextStyle(
                color: isDark ? const Color(0xFF8B8B9F) : const Color(0xFF6A6A84),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    this.imageUrl,
    this.backgroundColor,
    this.text,
    required this.borderColor,
  });

  final String? imageUrl;
  final Color? backgroundColor;
  final String? text;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipOval(
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: backgroundColor ?? const Color(0xFF8B7BFF),
                    child: Center(
                      child: Text(
                        text ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              )
            : Container(
                color: backgroundColor ?? const Color(0xFF8B7BFF),
                child: Center(
                  child: Text(
                    text ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ActionTilesGrid extends StatelessWidget {
  const _ActionTilesGrid({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _ActionTile(
          icon: Icons.alarm_rounded,
          label: 'Set daily\nreminder',
          backgroundColor: const Color(0xFFC4B5FD),
          isDark: isDark,
        ),
        _ActionTile(
          icon: Icons.bar_chart_rounded,
          label: 'Session\nsummary',
          backgroundColor: const Color(0xFFFCD34D),
          isDark: isDark,
        ),
        _ActionTile(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Send\nfeedback',
          backgroundColor: const Color(0xFFD1D5DB),
          isDark: isDark,
        ),
        _ActionTile(
          icon: Icons.push_pin_outlined,
          label: 'See who\npinned you',
          backgroundColor: const Color(0xFF6EE7B7),
          isDark: isDark,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF2A2A3E),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF2A2A3E),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.3,
                ),
          ),
        ],
      ),
    );
  }
}

class _TasksSection extends StatelessWidget {
  const _TasksSection({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? _cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A52) : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF3A3A52) : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              color: isDark ? const Color(0xFF8B8B9F) : const Color(0xFF6A6A84),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks for today',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark ? const Color(0xFF8B8B9F) : const Color(0xFF6A6A84),
                  fontSize: 16,
                ),
          ),
        ],
      ),
    );
  }
}

