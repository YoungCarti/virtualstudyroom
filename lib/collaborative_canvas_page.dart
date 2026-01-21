import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:demoflutter/canvas/canvas_model.dart';
import 'package:demoflutter/services/canvas_service.dart';
import 'package:demoflutter/widgets/canvas_painter.dart';

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

  @override
  void initState() {
    super.initState();
  }

  void _startStroke(Offset localPosition) {
    // Transform the local position to canvas coordinates
    final Matrix4 matrix = _transformationController.value;
    final double scale = matrix.getMaxScaleOnAxis();    final Offset transformedPoint = _transformPoint(localPosition);

    final newStroke = Stroke(
      id: const Uuid().v4(),
      points: [CanvasPoint(x: transformedPoint.dx, y: transformedPoint.dy)],
      color: _isEraser ? Colors.white : _selectedColor,
      strokeWidth: _selectedStrokeWidth / scale, // Adjust width based on zoom? Or keep constant on screen? Keeping constant on canvas for now.
    );

    setState(() {
      _currentStroke = newStroke;
      _strokes.add(newStroke); // Optimistically add local stroke
    });
  }

  void _updateStroke(Offset localPosition) {
    if (_currentStroke == null) return;

    final Offset transformedPoint = _transformPoint(localPosition);

    setState(() {
      final updatedPoints = List<CanvasPoint>.from(_currentStroke!.points)
        ..add(CanvasPoint(x: transformedPoint.dx, y: transformedPoint.dy));
      
      _currentStroke = Stroke(
        id: _currentStroke!.id,
        points: updatedPoints,
        color: _currentStroke!.color,
        strokeWidth: _currentStroke!.strokeWidth,
      );
       // Update the last stroke in the list
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
  
  Offset _transformPoint(Offset localPosition) {
     final Matrix4 matrix = _transformationController.value;
     final double scale = matrix.getMaxScaleOnAxis();
     final double offsetX = matrix.getTranslation().x;
     final double offsetY = matrix.getTranslation().y;
     
     // Inverse transform: (screen - translate) / scale
     return Offset(
       (localPosition.dx - offsetX) / scale,
       (localPosition.dy - offsetY) / scale,
     );
  }

  void _clearCanvas() {
    _canvasService.clearCanvas(widget.roomId);
    setState(() {
        _strokes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaborative Canvas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
               // Confirm dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Canvas?'),
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
            stream: _canvasService.getStrokes(widget.roomId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error loading canvas: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // If we have data or if the stream is active but data is null (should be empty list usually)
              final remoteStrokes = snapshot.data ?? [];

              return GestureDetector(
                    onScaleStart: (details) {
                        if (details.pointerCount == 1) {
                            _startStroke(details.localFocalPoint);
                        }
                    },
                    onScaleUpdate: (details) {
                        if (details.pointerCount == 1) {
                             _updateStroke(details.localFocalPoint);
                        }
                    },
                    onScaleEnd: (details) {
                         if (_currentStroke != null) {
                             _endStroke();
                         }
                    },
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      panEnabled: true,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      minScale: 0.1,
                      maxScale: 5.0,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: CanvasPainter([...remoteStrokes, if (_currentStroke != null) _currentStroke!]),
                         child: const SizedBox(
                             width: 5000, 
                             height: 5000,
                         ),
                      ),
                    ),
                  );
            },
          ),
          
          // Floating Toolbar
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                   IconButton(
                    icon: Icon(Icons.brush, color: !_isEraser ? _selectedColor : Colors.grey),
                    onPressed: () {
                         setState(() {
                             _isEraser = false;
                         });
                    },
                   ),
                   IconButton(
                     icon: const Icon(Icons.cleaning_services), // Eraser icon
                     color: _isEraser ? Colors.blue : Colors.grey,
                     onPressed: () {
                         setState(() {
                             _isEraser = true;
                         });
                     },
                   ),
                   // Color Picker (Simple)
                   ...[Colors.black, Colors.red, Colors.blue, Colors.green].map((color) => GestureDetector(
                       onTap: () {
                           setState(() {
                               _selectedColor = color;
                               _isEraser = false;
                           });
                       },
                       child: Container(
                           width: 24,
                           height: 24,
                           decoration: BoxDecoration(
                               color: color,
                               shape: BoxShape.circle,
                               border: Border.all(color: _selectedColor == color && !_isEraser ? Colors.grey : Colors.transparent, width: 2),
                           ),
                       ),
                   )),
                   DropdownButton<double>(
                       value: _selectedStrokeWidth,
                       items: const [2.0, 4.0, 8.0, 12.0].map((w) => DropdownMenuItem(value: w, child: Text(w.toString()))).toList(),
                       onChanged: (val) {
                           if (val != null) setState(() => _selectedStrokeWidth = val);
                       },
                       underline: const SizedBox(), 
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
