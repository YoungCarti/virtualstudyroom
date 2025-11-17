import 'package:flutter/material.dart';

const Color _primaryPurple = Color(0xFF6C63FF);
const Color _secondaryPurple = Color(0xFFB4A0FF);
const Color _backgroundTint = Color(0xFFF4F1FF);

class AiToolsPage extends StatefulWidget {
  const AiToolsPage({super.key});

  @override
  State<AiToolsPage> createState() => _AiToolsPageState();
}

class _AiToolsPageState extends State<AiToolsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 4, vsync: this);

  double _studyMinutes = 25;
  double _breakMinutes = 5;
  bool _smartBreaks = true;
  String _summary = 'Upload content to get AI-generated study notes.';
  bool _uploading = false;

  final TextEditingController _summarizerInput = TextEditingController();

  @override
  void dispose() {
    _tabController.dispose();
    _summarizerInput.dispose();
    super.dispose();
  }

  String get _timerSuggestion {
    if (_studyMinutes >= 45) {
      return 'AI Suggestion: Consider shorter sprints for better retention.';
    }
    if (_breakMinutes <= 3 && _smartBreaks) {
      return 'AI Suggestion: Micro-breaks detected. Try 5 mins for brain recovery.';
    }
    if (_smartBreaks && _studyMinutes >= 25) {
      return 'AI Suggestion: Balanced Pomodoro detected. Great for focus!';
    }
    return 'AI Suggestion: Enable Smart Breaks for adaptive pacing.';
  }

  Future<void> _simulateSummary() async {
    if (_summarizerInput.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please paste some text first.')),
      );
      return;
    }
    setState(() => _uploading = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _uploading = false;
      _summary =
          'Key Points:\n• ${_summarizerInput.text.split('.').first.trim()}...\n• Concepts grouped and simplified.\n• Action items extracted.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121121) : _backgroundTint,
      appBar: AppBar(
        title: const Text('AI Tools Hub'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1F1F33),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _primaryPurple,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      isDark ? Colors.white70 : const Color(0xFF6A6A84),
                  tabs: const [
                    Tab(text: 'AI Timer'),
                    Tab(text: 'AI Summarizer'),
                    Tab(text: 'AI Quiz Maker'),
                    Tab(text: 'AI Notes Helper'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AiTimerTab(
                    isDark: isDark,
                    studyMinutes: _studyMinutes,
                    breakMinutes: _breakMinutes,
                    smartBreaks: _smartBreaks,
                    suggestion: _timerSuggestion,
                    onStudyChanged: (value) =>
                        setState(() => _studyMinutes = value),
                    onBreakChanged: (value) =>
                        setState(() => _breakMinutes = value),
                    onSmartBreaksChanged: (value) =>
                        setState(() => _smartBreaks = value),
                  ),
                  _AiSummarizerTab(
                    controller: _summarizerInput,
                    summary: _summary,
                    uploading: _uploading,
                    onUpload: _simulateSummary,
                    isDark: isDark,
                  ),
                  const _PlaceholderTab(
                    title: 'AI Quiz Maker',
                    description:
                        'Generate quick recall quizzes from your study resources. Supports MCQs, flash cards, and spaced repetition scheduling.',
                  ),
                  const _PlaceholderTab(
                    title: 'AI Notes Helper',
                    description:
                        'Highlight messy notes, auto-organize bullet points, and sync with your subjects.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiTimerTab extends StatelessWidget {
  const _AiTimerTab({
    required this.isDark,
    required this.studyMinutes,
    required this.breakMinutes,
    required this.smartBreaks,
    required this.suggestion,
    required this.onStudyChanged,
    required this.onBreakChanged,
    required this.onSmartBreaksChanged,
  });

  final bool isDark;
  final double studyMinutes;
  final double breakMinutes;
  final bool smartBreaks;
  final String suggestion;
  final ValueChanged<double> onStudyChanged;
  final ValueChanged<double> onBreakChanged;
  final ValueChanged<bool> onSmartBreaksChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Study Duration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${studyMinutes.round()} minutes',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _primaryPurple,
                      ),
                ),
                Slider(
                  min: 15,
                  max: 90,
                  divisions: 15,
                  value: studyMinutes,
                  activeColor: _primaryPurple,
                  onChanged: onStudyChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Break Duration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${breakMinutes.round()} minutes',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _secondaryPurple,
                      ),
                ),
                Slider(
                  min: 3,
                  max: 20,
                  divisions: 17,
                  value: breakMinutes,
                  activeColor: _secondaryPurple,
                  onChanged: onBreakChanged,
                ),
                SwitchListTile.adaptive(
                  title: const Text('Enable Smart Break Scheduling'),
                  subtitle: const Text('AI adjusts breaks based on fatigue.'),
                  value: smartBreaks,
                  activeTrackColor: _primaryPurple,
                  onChanged: onSmartBreaksChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            highlight: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: _primaryPurple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPurple,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI Timer started (demo).')),
              );
            },
            child: const Text(
              'Start Timer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSummarizerTab extends StatelessWidget {
  const _AiSummarizerTab({
    required this.controller,
    required this.summary,
    required this.uploading,
    required this.onUpload,
    required this.isDark,
  });

  final TextEditingController controller;
  final String summary;
  final bool uploading;
  final Future<void> Function() onUpload;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF1F1F33);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paste text or drop an image link',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Paste your lecture notes, article, or image URL...',
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: TextStyle(color: textColor),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          uploading ? null : () => onUpload.call(),
                      icon: uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_rounded),
                      label: Text(uploading ? 'Analyzing...' : 'Upload & Summarize'),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image OCR coming soon.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.image_rounded),
                      label: const Text('Add Image'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: textColor,
                        height: 1.4,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _SummaryTag(
                      icon: Icons.checklist_rounded,
                      label: 'Action Items',
                    ),
                    _SummaryTag(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'Key Insights',
                    ),
                    _SummaryTag(
                      icon: Icons.link_rounded,
                      label: 'References',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTag extends StatelessWidget {
  const _SummaryTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: _primaryPurple, size: 18),
      label: Text(label),
      backgroundColor: _primaryPurple.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _GlassCard(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: _primaryPurple, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF5A5A74),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stay tuned!')),
                );
              },
              child: const Text('Join waitlist'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.width,
    this.highlight = false,
  });

  final Widget child;
  final double? width;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white.withValues( alpha: highlight ? 0.08 : 0.06)
        : Colors.white.withValues(alpha: highlight ? 0.45 : 0.95);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width ?? double.infinity,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.08),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
          border: highlight
              ? Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : _primaryPurple.withValues(alpha: 0.4),
                )
              : null,
        ),
        child: child,
      ),
    );
  }
}

