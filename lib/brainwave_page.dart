
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/brainwave_service.dart';
import 'widgets/wave_visualizer.dart';

class BrainwavePage extends StatefulWidget {
  const BrainwavePage({super.key});

  @override
  State<BrainwavePage> createState() => _BrainwavePageState();
}

class _BrainwavePageState extends State<BrainwavePage> {
  final BrainwaveService _service = BrainwaveService();

  // Color Palette
  final Color _deepNavy = const Color(0xFF0A1929);
  final Color _pureWhite = const Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _service.addListener(_onStateChange);
  }

  @override
  void dispose() {
    _service.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Color _getModeColor(BrainwaveMode mode) {
    switch (mode) {
      case BrainwaveMode.deepFocus: return const Color(0xFF2196F3);
      case BrainwaveMode.creative: return const Color(0xFF9B59B6);
      case BrainwaveMode.cram: return const Color(0xFFFF6B6B);
    }
  }

  String _getModeTitle(BrainwaveMode mode) {
    switch (mode) {
      case BrainwaveMode.deepFocus: return 'Deep Focus';
      case BrainwaveMode.creative: return 'Creative';
      case BrainwaveMode.cram: return 'Cram Mode';
    }
  }



  IconData _getModeIcon(BrainwaveMode mode) {
    switch (mode) {
      case BrainwaveMode.deepFocus: return Icons.waves;
      case BrainwaveMode.creative: return Icons.brush;
      case BrainwaveMode.cram: return Icons.flash_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _service.state;
    final primaryColor = _getModeColor(state.mode);

    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _pureWhite,
        title: Text(
          'Brainwave Station',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            
            // Visualizer Area
            Center(
              child: Container(
                height: 200,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: WaveVisualizer(
                  isPlaying: state.isPlaying,
                  color: primaryColor,
                  barCount: 20,
                ),
              ),
            ),
            
            const Spacer(flex: 1),

            // Current Mode Info
            // Current Mode Info
            Text(
              state.currentTitle,
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _pureWhite,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.currentArtist,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: _pureWhite.withValues(alpha: 0.6),
              ),
            ),

            const SizedBox(height: 40),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ControlCircle(
                  icon: Icons.skip_previous_rounded,
                  size: 50,
                  onTap: () => _service.previous(), 
                ),
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () => _service.togglePlay(),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: Icon(
                      state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                _ControlCircle(
                  icon: Icons.skip_next_rounded,
                  size: 50,
                  onTap: () => _service.next(), 
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Volume Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Icon(Icons.volume_mute_rounded, color: Colors.white54, size: 20),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: primaryColor,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                        thumbColor: primaryColor,
                        overlayColor: primaryColor.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: state.volume,
                        onChanged: (value) => _service.setVolume(value),
                      ),
                    ),
                  ),
                  Icon(Icons.volume_up_rounded, color: Colors.white54, size: 20),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Mode Selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: BrainwaveMode.values.map((mode) {
                  final isSelected = state.mode == mode;
                  return GestureDetector(
                    onTap: () => _service.setMode(mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? _getModeColor(mode).withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _getModeColor(mode) : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getModeIcon(mode),
                            color: isSelected ? _getModeColor(mode) : Colors.white54,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getModeTitle(mode),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.white54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlCircle extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _ControlCircle({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
