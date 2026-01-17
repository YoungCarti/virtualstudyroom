import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A reusable animated button that scales on tap
class AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleAmount;
  final Duration duration;

  const AnimatedScaleButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleAmount = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleAmount : 1.0,
        duration: widget.duration,
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

/// Animated list item with stagger effect
class StaggeredListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final int delayMs;

  const StaggeredListItem({
    super.key,
    required this.child,
    required this.index,
    this.delayMs = 50,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: Duration(milliseconds: index * delayMs))
        .fadeIn(duration: const Duration(milliseconds: 300))
        .slideX(
          begin: 0.1,
          end: 0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
  }
}

/// Page route with custom slide transition
class SlidePageRoute extends PageRouteBuilder {
  final Widget page;
  final AxisDirection direction;

  SlidePageRoute({
    required this.page,
    this.direction = AxisDirection.left,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            Offset begin;
            switch (direction) {
              case AxisDirection.up:
                begin = const Offset(0, 1);
                break;
              case AxisDirection.down:
                begin = const Offset(0, -1);
                break;
              case AxisDirection.left:
                begin = const Offset(1, 0);
                break;
              case AxisDirection.right:
                begin = const Offset(-1, 0);
                break;
            }

            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        );
}
