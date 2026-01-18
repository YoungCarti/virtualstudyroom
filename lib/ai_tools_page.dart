import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'forest_timer_page.dart';
import 'notes_helper_page.dart';
import 'quiz_maker_page.dart';

// Ocean Sunset Color Palette
const Color _deepNavy = Color(0xFF0A1929);
const Color _midnightBlue = Color(0xFF122A46);
const Color _electricBlue = Color(0xFF2196F3);
const Color _coralPink = Color(0xFFFF6B6B);
const Color _mintGreen = Color(0xFF4ECDC4);
const Color _softOrange = Color(0xFFFFB347);
const Color _pureWhite = Color(0xFFFFFFFF);

class AiToolsPage extends StatelessWidget {
  const AiToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        title: Text(
          'AI Tools Hub',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _pureWhite,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What would you like to do?',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: _pureWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose an AI-powered tool to boost your study session',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: _pureWhite.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              
              // Cards Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                  children: [
                    _FeatureCard(
                      icon: Icons.park_rounded,
                      title: 'Focus Timer',
                      description: 'Grow trees while you study with Pomodoro technique',
                      color: _mintGreen,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const _FullScreenWrapper(
                            title: 'Focus Timer',
                            child: ForestTimerView(),
                          ),
                        ),
                      ),
                    ),
                    _FeatureCard(
                      icon: Icons.summarize_rounded,
                      title: 'AI Summary',
                      description: 'Turn long texts into concise study notes',
                      color: _electricBlue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const _AiSummarizerPage(),
                        ),
                      ),
                    ),
                    _FeatureCard(
                      icon: Icons.quiz_rounded,
                      title: 'Quiz Maker',
                      description: 'Generate quizzes from your study materials',
                      color: _softOrange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QuizMakerPage(),
                        ),
                      ),
                    ),
                    _FeatureCard(
                      icon: Icons.note_alt_rounded,
                      title: 'Notes Helper',
                      description: 'Organize and enhance your notes with AI',
                      color: _coralPink,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotesHelperPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: _midnightBlue,
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _midnightBlue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const Spacer(),
            // Title
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _pureWhite,
              ),
            ),
            const SizedBox(height: 6),
            // Description
            Text(
              description,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: _pureWhite.withValues(alpha: 0.6),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Arrow indicator
            Row(
              children: [
                Text(
                  'Open',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: color, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper for full-screen feature pages
class _FullScreenWrapper extends StatelessWidget {
  const _FullScreenWrapper({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _pureWhite,
      ),
      body: child,
    );
  }
}

/// AI Summarizer Page
class _AiSummarizerPage extends StatefulWidget {
  const _AiSummarizerPage();

  @override
  State<_AiSummarizerPage> createState() => _AiSummarizerPageState();
}

class _AiSummarizerPageState extends State<_AiSummarizerPage> {
  final TextEditingController _controller = TextEditingController();
  String _summary = 'Upload content to get AI-generated study notes.';
  bool _uploading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _simulateSummary() async {
    if (_controller.text.trim().isEmpty) {
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
          'Key Points:\n• ${_controller.text.split('.').first.trim()}...\n• Concepts grouped and simplified.\n• Action items extracted.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        title: Text(
          'AI Summary',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _pureWhite,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _midnightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paste text or drop an image link',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _pureWhite,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Paste your lecture notes, article, or image URL...',
                      hintStyle: TextStyle(color: _pureWhite.withValues(alpha: 0.4)),
                      filled: true,
                      fillColor: _deepNavy,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: _pureWhite),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _uploading ? null : _simulateSummary,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _electricBlue,
                        foregroundColor: _pureWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _uploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _pureWhite,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        _uploading ? 'Analyzing...' : 'Summarize with AI',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _midnightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: _softOrange, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'AI Summary',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _pureWhite,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _summary,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: _pureWhite.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
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
