
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class WaveVisualizer extends StatelessWidget {
  final bool isPlaying;
  final Color color;
  final int barCount;

  const WaveVisualizer({
    super.key,
    required this.isPlaying,
    required this.color,
    this.barCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(barCount, (index) {
        // Vary animation duration for each bar to look random
        final duration = 600 + (index * 100) % 500;
        final height = 20.0 + (index * 5) % 30;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 6,
            height: isPlaying ? height : 4, // Collapse when paused
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          )
          .animate(
            target: isPlaying ? 1 : 0, 
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .scaleY(
             begin: 0.3,
             end: 1.5,
             duration: Duration(milliseconds: duration),
             curve: Curves.easeInOut,
          ),
        );
      }),
    );
  }
}
