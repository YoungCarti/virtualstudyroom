import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/forest_session_service.dart';

// Ocean Sunset Color Palette
const _deepNavy = Color(0xFF0A1929);      // Background base
const _midnightBlue = Color(0xFF122A46);  // Cards/containers
const _electricBlue = Color(0xFF2196F3);  // Primary actions
const _coralPink = Color(0xFFFF6B6B);     // Accents/alerts
const _mintGreen = Color(0xFF4ECDC4);     // Success/positive
const _softOrange = Color(0xFFFFB347);    // Warnings
const _pureWhite = Color(0xFFFFFFFF);     // Text

class ForestStatsView extends StatelessWidget {
  final VoidCallback? onStartPlanting;
  final ValueChanged<double>? onDurationChanged;
  final int selectedMinutes;

  const ForestStatsView({
    super.key,
    this.onStartPlanting,
    this.onDurationChanged,
    this.selectedMinutes = 25,
  });

  @override
  Widget build(BuildContext context) {
    final sessionService = ForestSessionService();
    
    return Container(
      color: _deepNavy,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                   const SizedBox(width: 48),
                   Expanded(
                     child: Text(
                       _getDateHeader(),
                       textAlign: TextAlign.center,
                       style: GoogleFonts.outfit(
                         color: _pureWhite,
                         fontSize: 16,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                   ),
                   const SizedBox(width: 48),
                ],
              ),
            ),
            
            // Tabs Pill
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _midnightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTab('Day', true),
                  _buildTab('Week', false),
                  _buildTab('Month', false),
                  _buildTab('Year', false),
                ],
              ),
            ),
            
            Expanded(
              child: Stack(
                children: [
                  // Isometric Map with Trees from Firestore
                  Positioned.fill(
                    top: 30,
                    bottom: 280, 
                    child: Center(
                      child: StreamBuilder<List<ForestSession>>(
                        stream: sessionService.getTodaySessions(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            print('ForestStats: Stream error - ${snapshot.error}');
                          }
                          if (snapshot.hasData) {
                            print('ForestStats: Got ${snapshot.data!.length} sessions');
                          }
                          
                          final treeCount = snapshot.data?.length ?? 0;
                          return SizedBox(
                            width: 320,
                            height: 200,
                            child: CustomPaint(
                              painter: IsometricForestGridPainter(treeCount: treeCount),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                  // Tree Counts Legend (Dynamic)
                  Positioned(
                    right: 20,
                    bottom: 310,
                    child: StreamBuilder<int>(
                      stream: sessionService.getTodayTreeCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _buildLegendItem(Icons.park, '$count', _mintGreen),
                            const SizedBox(height: 8),
                            _buildLegendItem(Icons.local_florist, '0', _coralPink),
                          ],
                        );
                      },
                    ),
                  ),

                  // Bottom Sheet with Controls
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _midnightBlue,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        boxShadow: [
                           BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, -4))
                        ]
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Focus time stats
                          StreamBuilder<int>(
                            stream: sessionService.getTodayFocusMinutes(),
                            builder: (context, snapshot) {
                              final minutes = snapshot.data ?? 0;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Focused Time Distribution',
                                    style: GoogleFonts.outfit(
                                      color: _pureWhite,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.outfit(color: _pureWhite.withValues(alpha: 0.7), fontSize: 14),
                                      children: [
                                        const TextSpan(text: 'Total focused time: '),
                                        TextSpan(
                                          text: '$minutes mins',
                                          style: const TextStyle(
                                            color: _mintGreen,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Duration selector
                          Text(
                            '$selectedMinutes min',
                            style: GoogleFonts.outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _pureWhite,
                            ),
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _mintGreen,
                              inactiveTrackColor: _deepNavy,
                              thumbColor: _mintGreen,
                              overlayColor: _mintGreen.withValues(alpha: 0.2),
                            ),
                            child: Slider(
                              value: selectedMinutes.toDouble(),
                              min: 5,
                              max: 120,
                              divisions: 23,
                              label: '$selectedMinutes min',
                              onChanged: onDurationChanged,
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Plant Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: onStartPlanting,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _mintGreen,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                elevation: 0,
                              ),
                              child: Text(
                                'Plant',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _deepNavy,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
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

  String _getDateHeader() {
    final now = DateTime.now();
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[now.month - 1]} ${now.day}, ${now.year}(Today)';
  }

  Widget _buildTab(String text, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: _electricBlue,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: isSelected ? _pureWhite : _pureWhite.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          count,
          style: GoogleFonts.outfit(
            color: _pureWhite,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Isometric Forest Grid with dynamic tree count
class IsometricForestGridPainter extends CustomPainter {
  final int treeCount;
  
  IsometricForestGridPainter({required this.treeCount});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    const rows = 5;
    const cols = 5;
    const tileW = 50.0;
    const tileH = 25.0;
    
    // Updated colors - more muted blue-green tones
    final paintTop = Paint()..color = const Color(0xFF2D5A5A);
    final paintRight = Paint()..color = const Color(0xFF1E3D3D);
    final paintLeft = Paint()..color = const Color(0xFF152B2B);
    
    final treePositions = _getTreePositions(treeCount);
    
    // Draw tiles from back to front
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = centerX + (c - r) * (tileW / 2);
        final y = centerY - 20 + (c + r) * (tileH / 2);
        
        _drawTile(canvas, x, y, tileW, tileH, paintTop, paintRight, paintLeft);
        
        // Draw tree if this position has one
        if (treePositions.contains(r * cols + c)) {
          _draw3DTree(canvas, x, y - 8);
        }
      }
    }
  }
  
  List<int> _getTreePositions(int count) {
    if (count <= 0) return [];
    
    const spiralOrder = [
      12, 7, 13, 17, 11, 6, 8, 16, 18, 2, 22,
      10, 14, 1, 3, 21, 23, 0, 4, 20, 24, 5, 9, 15, 19,
    ];
    
    return spiralOrder.take(count).toList();
  }
  
  void _drawTile(Canvas canvas, double x, double y, double w, double h, Paint top, Paint right, Paint left) {
    final pathTop = Path();
    pathTop.moveTo(x, y);
    pathTop.lineTo(x + w/2, y + h/2);
    pathTop.lineTo(x, y + h);
    pathTop.lineTo(x - w/2, y + h/2);
    pathTop.close();
    canvas.drawPath(pathTop, top);
    
    const d = 10.0;
    
    final pathRight = Path();
    pathRight.moveTo(x + w/2, y + h/2);
    pathRight.lineTo(x + w/2, y + h/2 + d);
    pathRight.lineTo(x, y + h + d);
    pathRight.lineTo(x, y + h);
    pathRight.close();
    canvas.drawPath(pathRight, right);
    
    final pathLeft = Path();
    pathLeft.moveTo(x - w/2, y + h/2);
    pathLeft.lineTo(x - w/2, y + h/2 + d);
    pathLeft.lineTo(x, y + h + d);
    pathLeft.lineTo(x, y + h);
    pathLeft.close();
    canvas.drawPath(pathLeft, left);
  }
  
  void _draw3DTree(Canvas canvas, double cx, double cy) {
    // Trunk - using warm brown
    final trunkPaint = Paint()..color = const Color(0xFF8B5A2B);
    final trunkSide = Paint()..color = const Color(0xFF5D3A1A);
    
    canvas.drawRect(
      Rect.fromCenter(center: Offset(cx, cy - 6), width: 6, height: 14),
      trunkPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(cx + 1, cy - 13, 2, 14),
      trunkSide,
    );
    
    // 3 layers of foliage - using mint green tones
    for (int i = 2; i >= 0; i--) {
      final layerY = cy - 20 - (i * 14);
      final layerW = 22.0 - (i * 4);
      final layerH = 16.0 - (i * 2);
      
      _drawFoliageLayer(canvas, cx, layerY, layerW, layerH);
    }
  }
  
  void _drawFoliageLayer(Canvas canvas, double cx, double cy, double w, double h) {
    // Using mint green shades
    final leftPath = Path();
    leftPath.moveTo(cx, cy);
    leftPath.lineTo(cx - w/2, cy + h);
    leftPath.lineTo(cx, cy + h * 0.7);
    leftPath.close();
    canvas.drawPath(leftPath, Paint()..color = const Color(0xFF5DDABA));
    
    final rightPath = Path();
    rightPath.moveTo(cx, cy);
    rightPath.lineTo(cx + w/2, cy + h);
    rightPath.lineTo(cx, cy + h * 0.7);
    rightPath.close();
    canvas.drawPath(rightPath, Paint()..color = const Color(0xFF2A9D8F));
    
    final centerPath = Path();
    centerPath.moveTo(cx, cy);
    centerPath.lineTo(cx - w * 0.25, cy + h * 0.85);
    centerPath.lineTo(cx, cy + h * 0.7);
    centerPath.lineTo(cx + w * 0.25, cy + h * 0.85);
    centerPath.close();
    canvas.drawPath(centerPath, Paint()..color = const Color(0xFF4ECDC4));
  }

  @override
  bool shouldRepaint(covariant IsometricForestGridPainter oldDelegate) {
    return oldDelegate.treeCount != treeCount;
  }
}
