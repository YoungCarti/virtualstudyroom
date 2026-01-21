import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:demoflutter/canvas/canvas_model.dart';
import 'package:demoflutter/services/canvas_service.dart';
import 'package:demoflutter/widgets/canvas_painter.dart';
import 'package:demoflutter/widgets/grid_painter.dart';

class CollaborativeCanvasPage extends StatefulWidget {
  final String roomId;
  const CollaborativeCanvasPage({super.key, this.roomId = 'default_room'});

  @override
  State<CollaborativeCanvasPage> createState() =>
      _CollaborativeCanvasPageState();
}

class _CollaborativeCanvasPageState extends State<CollaborativeCanvasPage> {
  final CanvasService _canvasService = CanvasService();
  final TransformationController _transformationController =
      TransformationController();
  
  List<Stroke> _strokes = [];
  Stroke? _currentStroke;
  Color _selectedColor = Colors.black;
  double _selectedStrokeWidth = 4.0;
  bool _isEraser = false;
  bool _isPanMode = false;
  late Stream<List<Stroke>> _strokesStream;

  @override
  void initState() {
    super.initState();
    _strokesStream = _canvasService.getStrokes(widget.roomId);
  }

  void _startStroke(Offset localPosition) {
    if (_isPanMode) return; 

    final newStroke = Stroke(
      id: const Uuid().v4(),
      points: [CanvasPoint(x: localPosition.dx, y: localPosition.dy)],
      color: _isEraser ? Colors.white : _selectedColor,
      strokeWidth: _selectedStrokeWidth, 
    );

    setState(() {
      _currentStroke = newStroke;
      _strokes.add(newStroke);
    });
  }

  void _updateStroke(Offset localPosition) {
    if (_isPanMode || _currentStroke == null) return;

    setState(() {
      final updatedPoints = List<CanvasPoint>.from(_currentStroke!.points)
        ..add(CanvasPoint(x: localPosition.dx, y: localPosition.dy));
      
      _currentStroke = Stroke(
        id: _currentStroke!.id,
        points: updatedPoints,
        color: _currentStroke!.color,
        strokeWidth: _currentStroke!.strokeWidth,
      );
      _strokes.removeLast();
      _strokes.add(_currentStroke!);
    });
  }

  void _endStroke() {
    if (_currentStroke != null) {
      _canvasService.addStroke(widget.roomId, _currentStroke!);
      _currentStroke = null;
    }
  }

  void _clearCanvas() {
    _canvasService.clearCanvas(widget.roomId);
    setState(() {
        _strokes.clear();
    });
  }

  void _undo() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Undo not implemented yet')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light gray/white background
      appBar: AppBar(
        title: const Text('Collaborative Board', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Board?'),
                    content: const Text('This will delete all drawings for everyone.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      TextButton(onPressed: () {
                        _clearCanvas();
                        Navigator.pop(context);
                      }, child: const Text('Clear')),
                    ],
                  ),
                );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Stroke>>(
            stream: _strokesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error loading canvas: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final remoteStrokes = snapshot.data ?? [];

              return InteractiveViewer(
                transformationController: _transformationController,
                panEnabled: _isPanMode,
                scaleEnabled: _isPanMode,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 5.0,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (details) {
                      if (!_isPanMode && details.pointerCount == 1) {
                          _startStroke(details.localFocalPoint);
                      }
                  },
                  onScaleUpdate: (details) {
                      if (!_isPanMode && details.pointerCount == 1) {
                           _updateStroke(details.localFocalPoint);
                      }
                  },
                  onScaleEnd: (details) {
                       if (_currentStroke != null) {
                           _endStroke();
                       }
                  },
                  child: Stack(
                    children: [
                      // Grid Background
                      CustomPaint(
                        size: const Size(5000, 5000), // Large fixed size for grid
                        painter: GridPainter(),
                      ),
                      // Drawings
                      CustomPaint(
                        size: const Size(5000, 5000),
                        painter: CanvasPainter([...remoteStrokes, if (_currentStroke != null) _currentStroke!]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Floating Top Left Menu (Undo/Redo)
          Positioned(
             top: 20,
             left: 20,
             child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                    IconButton(icon: const Icon(Icons.undo, color: Colors.black87), onPressed: _undo),
                    const Divider(height: 1, indent: 8, endIndent: 8),
                    IconButton(icon: const Icon(Icons.redo, color: Colors.black87), onPressed: _undo), // Placeholder redo
                  ],
                ),
             ),
          ),

          // Miro-style Bottom Floating Toolbar
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E), // Dark gray/black
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     IconButton(
                       icon: const Icon(Icons.grid_view_rounded, color: Colors.white70),
                       onPressed: () {
                          // Placeholder for "Apps"
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Apps menu not implemented')));
                       },
                     ),
                     Container(width: 1, height: 24, color: Colors.white24),
                     IconButton(
                       icon: const Icon(Icons.add, color: Colors.white),
                       onPressed: () => _showToolsMenu(context),
                     ),
                  ],
                ),
              ),
            ),
          ),
          
          // Contextual Color Palette (Visible when Pen/Eraser is active)
          if (!_isPanMode)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.15,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  children: [
                      // Active Tool Indicator
                      Icon(_isEraser ? Icons.cleaning_services : Icons.edit, color: Colors.black54),
                      const SizedBox(height: 12),
                      Container(height: 1, width: 20, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      
                      // Colors
                      ...[Colors.black, Colors.red, Colors.blue, Colors.green].map((color) => 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: GestureDetector(
                            onTap: () => setState(() {
                                _selectedColor = color;
                                _isEraser = false;
                            }),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _selectedColor == color && !_isEraser ? Colors.blueAccent : Colors.transparent, 
                                  width: 2
                                ),
                              ),
                            ),
                          ),
                        )
                      ),
                      const SizedBox(height: 12),
                      IconButton(
                        icon: Icon(Icons.cleaning_services, color: _isEraser ? Colors.blue : Colors.grey),
                        onPressed: () => setState(() => _isEraser = true),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _isPanMode = true), // Return to pan mode
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showToolsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 0.8, // Fix for bottom overflow
                children: [
                  _buildToolItem(Icons.text_fields, 'Text', onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Text tool not implemented')));
                  }),
                  _buildToolItem(Icons.note_alt_outlined, 'Sticky note', onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sticky note tool not implemented')));
                  }),
                  _buildToolItem(Icons.crop_free, 'Stickies capture', onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stickies capture tool not implemented')));
                  }), // Using crop_free as approx
                  _buildToolItem(Icons.comment_outlined, 'Comment', onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment tool not implemented')));
                  }),
                  _buildToolItem(Icons.edit_outlined, 'Pen', onTap: () {
                     Navigator.pop(context);
                     setState(() {
                       _isPanMode = false;
                       _isEraser = false;
                     });
                  }),
                  _buildToolItem(Icons.category_outlined, 'Shapes and lines', onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shapes and lines tool not implemented')));
                  }),
                  _buildToolItem(Icons.description_outlined, 'Doc', onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doc tool not implemented')));
                  }),
                  _buildToolItem(Icons.grid_3x3, 'Frame', onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Frame tool not implemented')));
                  }),
                   _buildToolItem(Icons.upload_file, 'Upload', onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload tool not implemented')));
                   }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolItem(IconData icon, String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            label, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
