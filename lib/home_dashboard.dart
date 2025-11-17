import 'package:flutter/material.dart';

const Color _primaryPurple = Color(0xFF6C63FF);
const Color _secondaryPurple = Color(0xFFB4A0FF);
const Color _backgroundTint = Color(0xFFF4F1FF);

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  final List<_DrawerItem> _drawerItems = const [
    _DrawerItem('Home', Icons.home_rounded),
    _DrawerItem('Study Rooms', Icons.meeting_room_outlined),
    _DrawerItem('Subjects', Icons.auto_stories_rounded),
    _DrawerItem('Files', Icons.folder_open_rounded),
    _DrawerItem('AI Tools', Icons.auto_awesome_rounded),
    _DrawerItem('Profile', Icons.person_rounded),
    _DrawerItem('Settings', Icons.settings_rounded),
    _DrawerItem('Logout', Icons.logout_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? const Color(0xFF1C1C28) : _backgroundTint,
      drawer: _SidebarDrawer(
        isDark: isDark,
        items: _drawerItems,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderRow(
                isDark: isDark,
                onProfileTap: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(height: 24),
              _QuickJoinCard(isDark: isDark),
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
              _SectionTitle(title: 'AI Tools', isDark: isDark),
              const SizedBox(height: 12),
              _AiToolsCard(isDark: isDark),
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
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.isDark, required this.onProfileTap});

  final bool isDark;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onProfileTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primaryPurple,
                  _secondaryPurple,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'M',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hey, Maya',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF2A2A40),
                    ),
              ),
              Text(
                'Ready to dive back in?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : const Color(0xFF60607A),
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.6),
          ),
          icon: Icon(
            Icons.notifications_outlined,
            color: isDark ? Colors.white : const Color(0xFF2A2A40),
            size: 24,
          ),
        ),
      ],
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

class _SidebarDrawer extends StatelessWidget {
  const _SidebarDrawer({required this.isDark, required this.items});

  final bool isDark;
  final List<_DrawerItem> items;

  @override
  Widget build(BuildContext context) {
    final background = isDark ? const Color(0xFF1B1B2A) : Colors.white;
    final accent = _primaryPurple;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              background,
              isDark
                  ? const Color(0xFF24243A)
                  : _secondaryPurple.withValues(alpha: 0.08),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 12),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            accent,
                            _secondaryPurple,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Maya Chen',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1F1F33),
                                ),
                          ),
                          Text(
                            'Premium member',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF5C5C7A),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  padding: EdgeInsets.zero,
                  separatorBuilder: (_, __) => Divider(
                    indent: 72,
                    endIndent: 20,
                    color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.15),
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isLogout = item.title == 'Logout';
                    return ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item.icon,
                          color: accent,
                        ),
                      ),
                      title: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: isLogout
                                  ? Colors.redAccent
                                  : isDark
                                      ? Colors.white
                                      : const Color(0xFF1E1E2F),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${item.title} tapped')),
                        );
                      },
                      trailing: isLogout
                          ? null
                          : Icon(
                              Icons.chevron_right_rounded,
                              color: isDark ? Colors.white54 : Colors.grey[500],
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem(this.title, this.icon);

  final String title;
  final IconData icon;
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

