import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'forest_stats_view.dart';
import 'services/forest_session_service.dart';

// Ocean Sunset Color Palette
const _deepNavy = Color(0xFF0A1929);      // Background base
const _midnightBlue = Color(0xFF122A46);  // Cards/containers
const _electricBlue = Color(0xFF2196F3);  // Primary actions
const _coralPink = Color(0xFFFF6B6B);     // Accents/alerts
const _mintGreen = Color(0xFF4ECDC4);     // Success/positive
const _softOrange = Color(0xFFFFB347);    // Warnings
const _pureWhite = Color(0xFFFFFFFF);     // Text

class ForestTimerView extends StatefulWidget {
  const ForestTimerView({super.key});

  @override
  State<ForestTimerView> createState() => _ForestTimerViewState();
}

class _ForestTimerViewState extends State<ForestTimerView> 
    with WidgetsBindingObserver, TickerProviderStateMixin {
  
  int _selectedMinutes = 25;
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isTimerActive = false;
  
  final ForestSessionService _sessionService = ForestSessionService();
  
  late AnimationController _swayController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remainingSeconds = _selectedMinutes * 60;
    
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _swayController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isRunning && (state == AppLifecycleState.paused || 
                       state == AppLifecycleState.inactive ||
                       state == AppLifecycleState.hidden)) {
      _failTimer();
    }
  }

  void _updateTime(double value) {
    if (_isRunning) return;
    setState(() {
      _selectedMinutes = value.round();
      _remainingSeconds = _selectedMinutes * 60;
    });
  }

  void _startTimer() {
    setState(() {
      _isTimerActive = true;
      _isRunning = true;
      _remainingSeconds = _selectedMinutes * 60;
    });
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeTimer();
      }
    });
  }

  void _failTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isTimerActive = false;
    });
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: _midnightBlue,
          title: Row(
            children: [
              const Icon(Icons.eco_outlined, color: _coralPink),
              const SizedBox(width: 8),
              Text('Tree Failed', style: GoogleFonts.outfit(color: _pureWhite)),
            ],
          ),
          content: Text(
            'Your tree has withered because you left the app. Stay focused next time!',
            style: GoogleFonts.outfit(color: _pureWhite.withValues(alpha: 0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('OK', style: GoogleFonts.outfit(color: _mintGreen)),
            ),
          ],
        ),
      );
    }
  }

  void _giveUpTimer() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _midnightBlue,
        title: Text('Give up?', style: GoogleFonts.outfit(color: _pureWhite)),
        content: Text(
          'Your tree will die if you give up now!',
          style: GoogleFonts.outfit(color: _pureWhite.withValues(alpha: 0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.outfit(color: _pureWhite.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _timer?.cancel();
              setState(() {
                _isRunning = false;
                _isTimerActive = false;
              });
            },
            child: Text('Give Up', style: GoogleFonts.outfit(color: _coralPink)),
          ),
        ],
      ),
    );
  }

  void _completeTimer() async {
    _timer?.cancel();
    
    print('ForestTimer: Timer completed, attempting to save $_selectedMinutes min session...');
    try {
      final result = await _sessionService.saveSession(durationMinutes: _selectedMinutes);
      print('ForestTimer: Save result = $result');
    } catch (e) {
      print('ForestTimer: Error saving session: $e');
    }
    
    setState(() {
      _isRunning = false;
      _isTimerActive = false;
    });
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: _midnightBlue,
          title: Row(
            children: [
              const Icon(Icons.park, color: _mintGreen),
              const SizedBox(width: 8),
              Text('Tree Planted! 🌲', style: GoogleFonts.outfit(color: _pureWhite)),
            ],
          ),
          content: Text(
            'Great focus session! Your tree has been added to your forest.',
            style: GoogleFonts.outfit(color: _pureWhite.withValues(alpha: 0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Awesome!', style: GoogleFonts.outfit(color: _mintGreen)),
            ),
          ],
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final total = _selectedMinutes * 60;
    if (total == 0) return 0;
    return 1.0 - (_remainingSeconds / total);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTimerActive) {
      return ForestStatsView(
        selectedMinutes: _selectedMinutes,
        onStartPlanting: _startTimer,
        onDurationChanged: _updateTime,
      );
    }

    return Container(
      color: _deepNavy,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Header Text
            Text(
              'Stay focused!',
              style: GoogleFonts.outfit(
                fontSize: 22,
                color: _pureWhite,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const Spacer(flex: 1),

            // Growing Tree Circle
            Center(
              child: SizedBox(
                width: 280,
                height: 280,
                child: AnimatedBuilder(
                  animation: _swayController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: GrowingTreeCirclePainter(
                        progress: _progress,
                        swayValue: _swayController.value,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Study Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _midnightBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: _softOrange,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Study',
                    style: GoogleFonts.outfit(
                      color: _pureWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Timer Display
            Text(
              _formatTime(_remainingSeconds),
              style: GoogleFonts.outfit(
                fontSize: 64,
                color: _pureWhite,
                fontWeight: FontWeight.w200,
                letterSpacing: 2,
              ),
            ),

            const Spacer(flex: 2),

            // Give Up Button
            GestureDetector(
              onTap: _giveUpTimer,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                decoration: BoxDecoration(
                  color: _midnightBlue,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: _coralPink.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Give Up',
                  style: GoogleFonts.outfit(
                    color: _coralPink,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// CustomPainter for the growing tree inside a circle
class GrowingTreeCirclePainter extends CustomPainter {
  final double progress;
  final double swayValue;

  GrowingTreeCirclePainter({
    required this.progress,
    required this.swayValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.9;

    // Background circle - midnight blue
    final circlePaint = Paint()
      ..color = const Color(0xFF1A3A4A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, circlePaint);

    // Progress arc - mint green
    if (progress > 0) {
      final arcPaint = Paint()
        ..color = _mintGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );

      // Progress dot at end of arc
      final angle = -math.pi / 2 + 2 * math.pi * progress;
      final dotX = center.dx + radius * math.cos(angle);
      final dotY = center.dy + radius * math.sin(angle);
      canvas.drawCircle(
        Offset(dotX, dotY),
        8,
        Paint()..color = _mintGreen,
      );
    }

    // Draw soil bowl
    _drawSoilBowl(canvas, center, radius);

    // Draw tree based on progress
    final treeBase = Offset(center.dx, center.dy + radius * 0.25);
    
    if (progress <= 0.02) {
      // Nothing yet
    } else if (progress < 0.15) {
      _drawSprout(canvas, treeBase, progress / 0.15);
    } else if (progress < 0.4) {
      _drawSapling(canvas, treeBase, (progress - 0.15) / 0.25);
    } else {
      _drawFullTree(canvas, treeBase, (progress - 0.4) / 0.6, swayValue);
    }
  }

  void _drawSoilBowl(Canvas canvas, Offset center, double radius) {
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    // Dark soil
    final soilPaint = Paint()..color = const Color(0xFF3D2817);
    
    final soilPath = Path();
    final soilTop = center.dy + radius * 0.15;
    
    soilPath.moveTo(center.dx - radius, soilTop);
    soilPath.quadraticBezierTo(
      center.dx, 
      soilTop + radius * 0.5, 
      center.dx + radius, 
      soilTop
    );
    soilPath.lineTo(center.dx + radius, center.dy + radius);
    soilPath.lineTo(center.dx - radius, center.dy + radius);
    soilPath.close();
    
    canvas.drawPath(soilPath, soilPaint);

    // Lighter soil highlight
    final highlightPaint = Paint()..color = const Color(0xFF5D4037);
    final highlightPath = Path();
    highlightPath.moveTo(center.dx - radius * 0.8, soilTop + 5);
    highlightPath.quadraticBezierTo(
      center.dx, 
      soilTop + radius * 0.35, 
      center.dx + radius * 0.8, 
      soilTop + 5
    );
    highlightPath.quadraticBezierTo(
      center.dx, 
      soilTop + radius * 0.25, 
      center.dx - radius * 0.8, 
      soilTop + 5
    );
    canvas.drawPath(highlightPath, highlightPaint);

    canvas.restore();
  }

  void _drawSprout(Canvas canvas, Offset base, double scale) {
    final stemHeight = 25 * scale;
    
    final stemPaint = Paint()
      ..color = const Color(0xFF4ECDC4)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, base.translate(0, -stemHeight), stemPaint);
    
    if (scale > 0.3) {
      final leafPaint = Paint()..color = const Color(0xFF5DDABA);
      final leafScale = (scale - 0.3) / 0.7;
      
      // Left leaf
      final leftLeaf = Path();
      leftLeaf.moveTo(base.dx, base.dy - stemHeight);
      leftLeaf.quadraticBezierTo(
        base.dx - 15 * leafScale, base.dy - stemHeight - 10 * leafScale,
        base.dx - 10 * leafScale, base.dy - stemHeight + 5 * leafScale
      );
      leftLeaf.quadraticBezierTo(
        base.dx - 5 * leafScale, base.dy - stemHeight,
        base.dx, base.dy - stemHeight
      );
      canvas.drawPath(leftLeaf, leafPaint);
      
      // Right leaf
      final rightLeaf = Path();
      rightLeaf.moveTo(base.dx, base.dy - stemHeight);
      rightLeaf.quadraticBezierTo(
        base.dx + 15 * leafScale, base.dy - stemHeight - 10 * leafScale,
        base.dx + 10 * leafScale, base.dy - stemHeight + 5 * leafScale
      );
      rightLeaf.quadraticBezierTo(
        base.dx + 5 * leafScale, base.dy - stemHeight,
        base.dx, base.dy - stemHeight
      );
      canvas.drawPath(rightLeaf, leafPaint);
    }
  }

  void _drawSapling(Canvas canvas, Offset base, double scale) {
    final height = 40 + 30 * scale;
    
    final trunkPaint = Paint()..color = const Color(0xFF8B5A2B);
    canvas.drawRect(
      Rect.fromCenter(center: base.translate(0, -height/2), width: 6, height: height),
      trunkPaint,
    );
    
    _drawFoliageLayer(canvas, base.translate(0, -height), 25 + 10 * scale, 20 + 8 * scale);
  }

  void _drawFullTree(Canvas canvas, Offset base, double scale, double sway) {
    final height = 70 + 40 * scale;
    final trunkWidth = 8 + 4 * scale;
    
    final trunkPaint = Paint()..color = const Color(0xFF8B5A2B);
    final trunkSidePaint = Paint()..color = const Color(0xFF5D3A1A);
    
    canvas.drawRect(
      Rect.fromCenter(center: base.translate(0, -height/3), width: trunkWidth, height: height * 0.5),
      trunkPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(base.dx + trunkWidth/2 - 2, base.dy - height * 0.5 - height/6, 3, height * 0.5),
      trunkSidePaint,
    );

    final numLayers = 3 + (scale * 2).toInt();
    for (int i = numLayers - 1; i >= 0; i--) {
      final layerY = base.dy - height * 0.4 - (i * 18 * (0.8 + scale * 0.2));
      final layerWidth = (35 + 25 * scale) * (1 - i * 0.15);
      final layerHeight = (25 + 15 * scale) * (1 - i * 0.1);
      
      _drawFoliageLayer(canvas, Offset(base.dx, layerY), layerWidth, layerHeight);
    }
  }

  void _drawFoliageLayer(Canvas canvas, Offset tip, double width, double height) {
    // Using mint green shades
    final leftPaint = Paint()..color = const Color(0xFF5DDABA);
    final leftPath = Path();
    leftPath.moveTo(tip.dx, tip.dy);
    leftPath.lineTo(tip.dx - width/2, tip.dy + height);
    leftPath.lineTo(tip.dx, tip.dy + height * 0.8);
    leftPath.close();
    canvas.drawPath(leftPath, leftPaint);

    final rightPaint = Paint()..color = const Color(0xFF2A9D8F);
    final rightPath = Path();
    rightPath.moveTo(tip.dx, tip.dy);
    rightPath.lineTo(tip.dx + width/2, tip.dy + height);
    rightPath.lineTo(tip.dx, tip.dy + height * 0.8);
    rightPath.close();
    canvas.drawPath(rightPath, rightPaint);

    final centerPaint = Paint()..color = _mintGreen;
    final centerPath = Path();
    centerPath.moveTo(tip.dx, tip.dy);
    centerPath.lineTo(tip.dx - width * 0.2, tip.dy + height * 0.9);
    centerPath.lineTo(tip.dx, tip.dy + height * 0.8);
    centerPath.lineTo(tip.dx + width * 0.2, tip.dy + height * 0.9);
    centerPath.close();
    canvas.drawPath(centerPath, centerPaint);
  }

  @override
  bool shouldRepaint(covariant GrowingTreeCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.swayValue != swayValue;
  }
}
