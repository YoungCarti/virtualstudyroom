import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:demoflutter/canvas/canvas_model.dart';
import 'package:demoflutter/services/canvas_service.dart';
import 'package:demoflutter/widgets/canvas_painter.dart';
import 'package:demoflutter/widgets/grid_painter.dart';
import 'package:demoflutter/widgets/text_element_widget.dart';
import 'package:demoflutter/widgets/sticky_note_widget.dart';

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
  bool _isTextMode = false;
  bool _isStickyNoteMode = false;
  
  String? _selectedTextElementId;
  String? _selectedStickyNoteId;

  late Stream<List<Stroke>> _strokesStream;
  late Stream<List<TextElement>> _textElementsStream;
  late Stream<List<StickyNoteElement>> _stickyNotesStream;

  @override
  void initState() {
    super.initState();
    _strokesStream = _canvasService.getStrokes(widget.roomId);
    _textElementsStream = _canvasService.getTextElements(widget.roomId);
    _stickyNotesStream = _canvasService.getStickyNotes(widget.roomId);
  }

  void _startStroke(Offset localPosition) {
    if (_isPanMode || _isTextMode || _isStickyNoteMode) return; 

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
    if (_isPanMode || _isTextMode || _isStickyNoteMode || _currentStroke == null) return;

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

  void _addTextElement(Offset localPosition) {
    final newText = TextElement(
      id: const Uuid().v4(),
      text: '', // Start with empty text, widget shows placeholder
      x: localPosition.dx,
      y: localPosition.dy,
      fontSize: 14,
      color: Colors.black,
      width: 150,
    );
    _canvasService.addTextElement(widget.roomId, newText);
    setState(() {
      _selectedTextElementId = newText.id;
      _isTextMode = false; // Initial creation done, switch to edit mode
    });
  }

  void _addStickyNote(Offset localPosition) {
    final newNote = StickyNoteElement(
      id: const Uuid().v4(),
      text: '',
      x: localPosition.dx - 75,
      y: localPosition.dy - 75,
      width: 150,
      height: 150,
      color: const Color(0xFFFFF59D), // Light yellow
      fontSize: 16,
    );
    _canvasService.addStickyNote(widget.roomId, newNote);
    setState(() {
      _selectedStickyNoteId = newNote.id;
      _isStickyNoteMode = false;
    });
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
                    content: const Text('This will delete all drawings and text for everyone.'),
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
          // Main Canvas Stack (Strokes + Text)
          InteractiveViewer(
            transformationController: _transformationController,
            panEnabled: _isPanMode,
            scaleEnabled: _isPanMode,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 5.0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                  if (_isTextMode) {
                      _addTextElement(details.localPosition);
                  } else if (_isStickyNoteMode) {
                      _addStickyNote(details.localPosition);
                  } else {
                     setState(() {
                        _selectedTextElementId = null; // Deselect text
                        _selectedStickyNoteId = null; // Deselect sticky note
                     });
                  }
              },
              onScaleStart: (details) {
                  if (!_isPanMode && !_isTextMode && details.pointerCount == 1 && _selectedTextElementId == null) {
                      _startStroke(details.localFocalPoint);
                  }
              },
              onScaleUpdate: (details) {
                  if (!_isPanMode && !_isTextMode && details.pointerCount == 1 && _selectedTextElementId == null) {
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
                    size: const Size(5000, 5000), 
                    painter: GridPainter(),
                  ),
                  
                  // Strokes Layer
                  StreamBuilder<List<Stroke>>(
                      stream: _strokesStream,
                      builder: (context, snapshot) {
                        final remoteStrokes = snapshot.data ?? [];
                        return CustomPaint(
                             size: const Size(5000, 5000),
                             painter: CanvasPainter([...remoteStrokes, if (_currentStroke != null) _currentStroke!]),
                        );
                      }
                  ),
                  
                  // Sticky Notes Layer (Below Text)
                  StreamBuilder<List<StickyNoteElement>>(
                    stream: _stickyNotesStream,
                    builder: (context, snapshot) {
                      final notes = snapshot.data ?? [];
                      return Stack(
                        children: notes.map((note) {
                          return StickyNoteWidget(
                            element: note,
                            isSelected: _selectedStickyNoteId == note.id,
                            onSelect: (id) => setState(() {
                              _selectedStickyNoteId = id;
                              _selectedTextElementId = null; // Deselect text
                              _isPanMode = false;
                            }),
                            onUpdate: (updatedNote) {
                              _canvasService.updateStickyNote(widget.roomId, updatedNote);
                            },
                          );
                        }).toList(),
                      );
                    }
                  ),

                  // Text Elements Layer
                  StreamBuilder<List<TextElement>>(
                    stream: _textElementsStream,
                    builder: (context, snapshot) {
                      final textElements = snapshot.data ?? [];
                      return Stack(
                        children: textElements.map((element) {
                          return TextElementWidget(
                            element: element,
                            isSelected: _selectedTextElementId == element.id,
                            onSelect: (id) => setState(() {
                              _selectedTextElementId = id;
                              _selectedStickyNoteId = null; // Deselect sticky note
                              _isPanMode = false; // Disable pan when text selected
                            }),
                            onUpdate: (updatedElement) {
                              _canvasService.updateTextElement(widget.roomId, updatedElement);
                            },
                          );
                        }).toList(),
                      );
                    }
                  ),
                  
                  // Transparent overlay to enforce size for InteractiveViewer
                  const SizedBox(width: 5000, height: 5000),
                ],
              ),
            ),
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
                    IconButton(icon: const Icon(Icons.redo, color: Colors.black87), onPressed: _undo), 
                  ],
                ),
             ),
          ),

          // Tools Menu
          if (_selectedTextElementId == null && _selectedStickyNoteId == null)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E), 
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
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Apps menu not implemented')));
                       },
                     ),
                     Container(width: 1, height: 24, color: Colors.white24),
                     IconButton(
                       icon: Icon(_isTextMode 
                           ? Icons.text_fields 
                           : (_isStickyNoteMode ? Icons.note_alt : Icons.add), 
                           color: (_isTextMode || _isStickyNoteMode) ? Colors.blueAccent : Colors.white),
                       onPressed: () {
                           if (_isTextMode) setState(() => _isTextMode = false);
                           else if (_isStickyNoteMode) setState(() => _isStickyNoteMode = false);
                           else _showToolsMenu(context);
                       },
                     ),
                  ],
                ),
              ),
            ),
          ),
          
          // Contextual Text Toolbar
          if (_selectedTextElementId != null)
             _buildTextToolbar(),

          // Contextual Sticky Note Toolbar
          if (_selectedStickyNoteId != null)
             _buildStickyNoteToolbar(),
             
          // Contextual Drawing Toolbar (only if not text mode and not selecting text)
          // Vertical Drawing Toolbar (Visible when Pen/Eraser is active)
          // Vertical Drawing Toolbar (Visible when Pen/Eraser is active)
          if (!_isPanMode && !_isTextMode && !_isStickyNoteMode)
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      // Pen Icon
                      Icon(Icons.edit, color: !_isEraser ? Colors.black : Colors.grey, size: 24),
                      const SizedBox(height: 12),
                      
                      // Divider
                      Container(height: 1, width: 20, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      
                      // Colors
                      ...[Colors.black, const Color(0xFFF44336), const Color(0xFF2196F3), const Color(0xFF4CAF50)].map((color) {
                          final isSelected = _selectedColor == color && !_isEraser;
                          return GestureDetector(
                             onTap: () => setState(() {
                                 _selectedColor = color;
                                 _isEraser = false;
                             }),
                             child: Padding(
                               padding: const EdgeInsets.symmetric(vertical: 6),
                               child: Container(
                                 width: 24, height: 24,
                                 decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                                 ),
                                 child: isSelected ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null,
                               ),
                             ),
                          );
                      }),
                      
                      const SizedBox(height: 12),
                      
                      // Eraser
                      GestureDetector(
                        onTap: () => setState(() => _isEraser = !_isEraser),
                        child: Icon(Icons.cleaning_services, color: _isEraser ? Colors.blue : Colors.grey, size: 24),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Close
                      GestureDetector(
                        onTap: () => setState(() => _isPanMode = true),
                        child: const Icon(Icons.close, color: Colors.grey, size: 24),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextToolbar() {
      return StreamBuilder<List<TextElement>>(
        stream: _textElementsStream,
        builder: (context, snapshot) {
            final elements = snapshot.data ?? [];
            TextElement? selectedElement;
            try {
              selectedElement = elements.firstWhere((e) => e.id == _selectedTextElementId);
            } catch (e) {
              return const SizedBox.shrink();
            }

            return Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                    height: 56,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(28), // Pill shape
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            // Text Icon
                            const Icon(Icons.title, color: Colors.white, size: 24),
                            
                            const SizedBox(width: 16),
                            Container(width: 1, height: 24, color: Colors.white24),
                            const SizedBox(width: 16),
                            
                            // Font Size Controls
                            IconButton(
                                icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                    _canvasService.updateTextElement(widget.roomId, TextElement(
                                        id: selectedElement!.id,
                                        text: selectedElement.text,
                                        x: selectedElement.x,
                                        y: selectedElement.y,
                                        fontSize: (selectedElement.fontSize - 2).clamp(8.0, 72.0),
                                        color: selectedElement.color,
                                        width: selectedElement.width,
                                        rotation: selectedElement.rotation,
                                        isBold: selectedElement.isBold,
                                    ));
                                },
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedElement!.fontSize.round().toString(), 
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                    _canvasService.updateTextElement(widget.roomId, TextElement(
                                        id: selectedElement!.id,
                                        text: selectedElement.text,
                                        x: selectedElement.x,
                                        y: selectedElement.y,
                                        fontSize: (selectedElement.fontSize + 2).clamp(8.0, 72.0),
                                        color: selectedElement.color,
                                        width: selectedElement.width,
                                        rotation: selectedElement.rotation,
                                        isBold: selectedElement.isBold,
                                    ));
                                },
                            ),
                            
                            const SizedBox(width: 16),
                            Container(width: 1, height: 24, color: Colors.white24),
                            const SizedBox(width: 16),

                            // Delete
                               IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                                  onPressed: () {
                                       _canvasService.deleteTextElement(widget.roomId, selectedElement!.id);
                                       setState(() => _selectedTextElementId = null);
                                  },
                              ),

                              // Duplicate
                               IconButton(
                                  icon: const Icon(Icons.copy_all_outlined, color: Colors.white), // Use outlined/square style
                                  onPressed: () {
                                       final newId = const Uuid().v4();
                                       _canvasService.addTextElement(widget.roomId, TextElement(
                                           id: newId,
                                           text: selectedElement!.text,
                                           x: selectedElement.x + 20,
                                           y: selectedElement.y + 20,
                                           fontSize: selectedElement.fontSize,
                                           color: selectedElement.color,
                                           width: selectedElement.width,
                                           rotation: selectedElement.rotation,
                                           isBold: selectedElement.isBold,
                                       ));
                                       setState(() => _selectedTextElementId = newId);
                                  },
                              ),
                              
                              // More
                              IconButton(
                                icon: const Icon(Icons.more_vert, color: Colors.white),
                                onPressed: () {
                                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('More options: Bold, Color, Align...')));
                                },
                              ),
                          ],
                      ),
                    ),
                ),
              ),
            );
        }
      );
  }

  Widget _buildStickyNoteToolbar() {
      return StreamBuilder<List<StickyNoteElement>>(
        stream: _stickyNotesStream,
        builder: (context, snapshot) {
            final elements = snapshot.data ?? [];
            StickyNoteElement? selectedElement;
            try {
              selectedElement = elements.firstWhere((e) => e.id == _selectedStickyNoteId);
            } catch (e) {
              return const SizedBox.shrink();
            }

            return Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                    height: 56,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            // Sticky Note Icon
                            const Icon(Icons.note_alt, color: Colors.white, size: 24),
                            
                            const SizedBox(width: 16),
                            Container(width: 1, height: 24, color: Colors.white24),
                            const SizedBox(width: 16),
                            
                            // Size Controls (Content Size / Font Size)
                            IconButton(
                                icon: const Icon(Icons.remove, color: Colors.white, size: 20),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                     _canvasService.updateStickyNote(widget.roomId, selectedElement!.copyWith(
                                         fontSize: (selectedElement.fontSize - 2).clamp(8.0, 72.0)
                                     ));
                                },
                            ),
                            const SizedBox(width: 12),
                            Text(
                              selectedElement!.fontSize.round().toString(), 
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                     _canvasService.updateStickyNote(widget.roomId, selectedElement!.copyWith(
                                         fontSize: (selectedElement.fontSize + 2).clamp(8.0, 72.0)
                                     ));
                                },
                            ),
                            
                            const SizedBox(width: 16),
                            Container(width: 1, height: 24, color: Colors.white24),
                            const SizedBox(width: 16),

                            // Delete
                               IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                                  onPressed: () {
                                       _canvasService.deleteStickyNote(widget.roomId, selectedElement!.id);
                                       setState(() => _selectedStickyNoteId = null);
                                  },
                              ),

                              // Duplicate
                               IconButton(
                                  icon: const Icon(Icons.copy_all_outlined, color: Colors.white), 
                                  onPressed: () {
                                       final newId = const Uuid().v4();
                                       _canvasService.addStickyNote(widget.roomId, selectedElement!.copyWith(
                                            id: newId,
                                            x: selectedElement.x + 20,
                                            y: selectedElement.y + 20,
                                       ));
                                       setState(() => _selectedStickyNoteId = newId);
                                  },
                              ),
                              
                              // More
                              IconButton(
                                icon: const Icon(Icons.more_vert, color: Colors.white),
                                onPressed: () {
                                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('More options: Color, Layering...')));
                                },
                              ),
                          ],
                      ),
                    ),
                ),
              ),
            );
        }
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
                    setState(() {
                        _isTextMode = true;
                        _isPanMode = false;
                        _isEraser = false;
                        _isStickyNoteMode = false;
                    });
                  }),
                  _buildToolItem(Icons.note_alt_outlined, 'Sticky note', onTap: () {
                    Navigator.pop(context);
                    setState(() {
                        _isStickyNoteMode = true;
                        _isPanMode = false;
                        _isEraser = false;
                        _isTextMode = false;
                    });
                  }),
                  _buildToolItem(Icons.comment_outlined, 'Comment', onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment tool not implemented')));
                  }),
                  _buildToolItem(Icons.edit_outlined, 'Pen', onTap: () {
                     Navigator.pop(context);
                     setState(() {
                       _isPanMode = false;
                       _isEraser = false;
                       _isTextMode = false;
                       _isStickyNoteMode = false;
                     });
                  }),
                  _buildToolItem(Icons.category_outlined, 'Shapes and lines', onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shapes and lines tool not implemented')));
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
