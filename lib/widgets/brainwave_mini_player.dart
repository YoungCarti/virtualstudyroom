
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/brainwave_service.dart';
import 'wave_visualizer.dart';
import '../brainwave_page.dart';

class BrainwaveMiniPlayer extends StatefulWidget {
  const BrainwaveMiniPlayer({super.key});

  @override
  State<BrainwaveMiniPlayer> createState() => _BrainwaveMiniPlayerState();
}

class _BrainwaveMiniPlayerState extends State<BrainwaveMiniPlayer> {
  final BrainwaveService _service = BrainwaveService();

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

  @override
  Widget build(BuildContext context) {
    final state = _service.state;
    final modeColor = _getModeColor(state.mode);

    // Only show if playing or if user has interacted (can be refined)
    // For now we always show it as an "AI Feature Recommender" if not playing
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BrainwavePage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
             // Icon / Visualizer
             Container(
               width: 40,
               height: 40,
               decoration: BoxDecoration(
                 color: modeColor.withValues(alpha: 0.15),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: state.isPlaying 
                  ? Center(child: WaveVisualizer(isPlaying: true, color: modeColor, barCount: 3))
                  : Icon(Icons.headphones, color: modeColor, size: 20),
             ),
             const SizedBox(width: 12),
             
             // Texts
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     state.isPlaying ? 'Now Playing' : 'Brainwave Station',
                     style: GoogleFonts.outfit(
                       color: Colors.white.withValues(alpha: 0.6),
                       fontSize: 10,
                     ),
                   ),
                   Text(
                     state.currentTitle,
                     style: GoogleFonts.outfit(
                       color: Colors.white,
                       fontSize: 14,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                 ],
               ),
             ),

             // Play/Pause Button
             IconButton(
               icon: Icon(
                 state.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                 color: modeColor,
                 size: 32,
               ),
               onPressed: () => _service.togglePlay(),
             ),
          ],
        ),
      ),
    );
  }
}
