import 'package:flutter/material.dart';

import 'study_rooms_page.dart';

const Color _primaryPurple = Color(0xFF6C63FF);
const Color _secondaryPurple = Color(0xFFB4A0FF);
const Color _backgroundTint = Color(0xFFF4F1FF);
const Color _lightBlueBackground = Color(0xFFE5EDF7);

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
    if (index == _selectedIndex) return;
    
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to respective pages based on index
    switch (index) {
      case 1: // Calendar/Schedule
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule coming soon!')),
        );
        break;
      case 2: // Documents/Files
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documents coming soon!')),
        );
        break;
      case 3: // Profile
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile coming soon!')),
        );
        break;
      default:
        break;
    }
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
      backgroundColor: isDark ? const Color(0xFF12121E) : _lightBlueBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeader(
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              _StatsGrid(metrics: _metrics, isDark: isDark),
              const SizedBox(height: 24),
              _QuickActionsRow(
                onStudyRooms: () => _handleQuickAction('study_rooms'),
                onSubjects: () => _handleQuickAction('subjects'),
                onClasses: () => _handleQuickAction('classes'),
                onPresence: () => _handleQuickAction('presence'),
              ),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Schedule', isDark: isDark),
              const SizedBox(height: 12),
              _ScheduleStrip(items: _schedule),
              const SizedBox(height: 24),
              _QuickJoinCard(isDark: isDark),
              const SizedBox(height: 24),
              _SectionTitle(title: 'AI Tools', isDark: isDark),
              const SizedBox(height: 12),
              _AiToolsCard(isDark: isDark),
              const SizedBox(height: 24),
              _SectionTitle(title: 'Your Subjects', isDark: isDark),
              const SizedBox(height: 12),
              SizedBox(
                height: 165,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: _subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, index) {
                    final subject = _subjects[index];
                    return _SubjectCard(
                      subject: subject,
                      isDark: isDark,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(title: 'Upcoming Tasks', isDark: isDark),
                        const SizedBox(height: 12),
                        _TaskList(isDark: isDark, tasks: _tasks),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(title: 'Recent Files', isDark: isDark),
                        const SizedBox(height: 12),
                        _RecentFilesList(isDark: isDark, files: _files),
                      ],
                    ),
                  ),
                ],
              ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.apps_rounded,
                  label: 'Home',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _onBottomNavTap(0),
                  isDark: isDark,
                ),
                _BottomNavItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Schedule',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _onBottomNavTap(1),
                  isDark: isDark,
                ),
                _BottomNavItem(
                  icon: Icons.description_rounded,
                  label: 'Documents',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _onBottomNavTap(2),
                  isDark: isDark,
                ),
                _BottomNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: _selectedIndex == 3,
                  onTap: () => _onBottomNavTap(3),
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
        ? _primaryPurple 
        : (isDark ? Colors.white54 : Colors.grey[600]);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
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

