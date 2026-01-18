import 'package:flutter/material.dart';
import 'forest_timer_page.dart';

// Ocean Sunset Color Palette
const Color _deepNavy = Color(0xFF0A1929);      // Background base
const Color _midnightBlue = Color(0xFF122A46);  // Cards/containers
const Color _electricBlue = Color(0xFF2196F3); // Primary actions
const Color _mintGreen = Color(0xFF4ECDC4);    // Success/positive
const Color _pureWhite = Color(0xFFFFFFFF);    // Text

class AiToolsPage extends StatefulWidget {
  const AiToolsPage({super.key});

  @override
  State<AiToolsPage> createState() => _AiToolsPageState();
}

class _AiToolsPageState extends State<AiToolsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 4, vsync: this);


  String _summary = 'Upload content to get AI-generated study notes.';
  bool _uploading = false;

  final TextEditingController _summarizerInput = TextEditingController();

  @override
  void dispose() {
    _tabController.dispose();
    _summarizerInput.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        title: const Text('AI Tools Hub'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _pureWhite,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: _midnightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: _electricBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: _pureWhite,
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  unselectedLabelColor: _pureWhite.withValues(alpha: 0.6),
                  tabs: const [
                    Tab(text: 'Timer'),
                    Tab(text: 'Summary'),
                    Tab(text: 'Quiz'),
                    Tab(text: 'Notes'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const ForestTimerView(),
                  _AiSummarizerTab(
                    controller: _summarizerInput,
                    summary: _summary,
                    uploading: _uploading,
                    onUpload: _simulateSummary,
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

// _AiTimerTab removed - replaced by ForestTimerPage

class _AiSummarizerTab extends StatelessWidget {
  const _AiSummarizerTab({
    required this.controller,
    required this.summary,
    required this.uploading,
    required this.onUpload,
  });

  final TextEditingController controller;
  final String summary;
  final bool uploading;
  final Future<void> Function() onUpload;

  @override
  Widget build(BuildContext context) {
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
                        color: _pureWhite,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Paste your lecture notes, article, or image URL...',
                    hintStyle: TextStyle(color: _pureWhite.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: _deepNavy,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: _pureWhite),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed:
                          uploading ? null : () => onUpload.call(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _electricBlue,
                        side: const BorderSide(color: _electricBlue),
                      ),
                      icon: uploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _electricBlue),
                            )
                          : const Icon(Icons.upload_rounded),
                      label: Text(uploading ? 'Analyzing...' : 'Upload & Summarize'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image OCR coming soon.'),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: _mintGreen),
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
                        color: _pureWhite,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _pureWhite.withValues(alpha: 0.8),
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
      avatar: Icon(icon, color: _electricBlue, size: 18),
      label: Text(label, style: const TextStyle(color: _pureWhite)),
      backgroundColor: _electricBlue.withValues(alpha: 0.15),
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
            Icon(Icons.auto_awesome, color: _electricBlue, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _pureWhite,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _pureWhite.withValues(alpha: 0.7),
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
              style: TextButton.styleFrom(foregroundColor: _mintGreen),
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
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width ?? double.infinity,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _midnightBlue,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: highlight
              ? Border.all(color: _electricBlue.withValues(alpha: 0.4))
              : null,
        ),
        child: child,
      ),
    );
  }
}
