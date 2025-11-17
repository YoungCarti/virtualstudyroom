import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    required this.isReadyToProceed,
  });

  final VoidCallback onFinished;
  final bool isReadyToProceed;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _showReadyHint = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentPage == 2) {
      if (widget.isReadyToProceed) {
        widget.onFinished();
      } else {
        setState(() => _showReadyHint = true);
      }
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildDots(Color active, Color inactive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? active : inactive,
            borderRadius: const BorderRadius.all(Radius.circular(999)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  children: [
                    _WelcomePage(colorScheme: colorScheme, textTheme: textTheme),
                    _FeaturesPage(
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    _MotivationPage(
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildDots(
                colorScheme.onPrimary,
                colorScheme.onPrimary.withValues(alpha: 0.4),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        if (widget.isReadyToProceed) {
                          widget.onFinished();
                        } else {
                          setState(() => _showReadyHint = true);
                        }
                      },
                      child: Text(
                        widget.isReadyToProceed ? 'Skip' : 'Loading...',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.onPrimary,
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: _handleNext,
                      child: Text(_currentPage == 2 ? 'Get Started' : 'Next'),
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _showReadyHint && !widget.isReadyToProceed
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Almost ready... just a sec.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                      )
                    : const SizedBox(height: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.colorScheme,
    required this.textTheme,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 64,
            backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.1),
            child: Icon(
              Icons.school_rounded,
              size: 64,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to StudySpace',
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Focus better. Study together.',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage({
    required this.colorScheme,
    required this.textTheme,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  Widget _feature(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.1),
          child: Icon(icon, color: colorScheme.onPrimary, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Everything you need to stay productive',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 24,
            children: [
              _feature(Icons.meeting_room_outlined, 'Virtual Study Rooms'),
              _feature(Icons.auto_awesome, 'AI Tools for Productivity'),
              _feature(Icons.video_chat, 'Chat & Video Study Sessions'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MotivationPage extends StatelessWidget {
  const _MotivationPage({
    required this.colorScheme,
    required this.textTheme,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bolt_rounded,
            color: colorScheme.onPrimary,
            size: 96,
          ),
          const SizedBox(height: 24),
          Text(
            'Stay focused. Stay motivated.',
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Create the study habit you’ve always wanted with StudySpace.',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}