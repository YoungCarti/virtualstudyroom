import 'package:flutter/material.dart';
import 'package:demoflutter/canvas/canvas_model.dart';
import 'dart:math' as math;

class TextElementWidget extends StatefulWidget {
  final TextElement element;
  final bool isSelected;
  final Function(TextElement) onUpdate;
  final Function(String) onSelect;
  final double scale;

  const TextElementWidget({
    Key? key,
    required this.element,
    required this.isSelected,
    required this.onUpdate,
    required this.onSelect,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  _TextElementWidgetState createState() => _TextElementWidgetState();
}

class _TextElementWidgetState extends State<TextElementWidget> {
  late TextEditingController _controller;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.element.text);
  }

  @override
  void didUpdateWidget(TextElementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.element.text != _controller.text && !_isEditing) {
      _controller.text = widget.element.text;
    }
    // Auto-edit when newly created or selected if empty
    if (widget.isSelected && !oldWidget.isSelected && widget.element.text.isEmpty) {
       setState(() => _isEditing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const double padding = 60.0; // Ample padding to catch handle hits
    const handleSize = 12.0;
    final borderColor = widget.isSelected ? Colors.blue : Colors.transparent;
    
    return Positioned(
      left: widget.element.x - padding,
      top: widget.element.y - padding,
      child: Transform.rotate(
        angle: widget.element.rotation,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
             // 1. The Main Text Container (with padding to expand hit area)
             Padding(
               padding: const EdgeInsets.all(padding),
               child: GestureDetector(
                  onTap: () {
                     if (widget.isSelected) {
                        setState(() => _isEditing = true);
                     } else {
                        widget.onSelect(widget.element.id);
                     }
                  },
                  child: Container(
                    width: widget.element.width,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 2.0),
                      color: _isEditing ? Colors.white : Colors.transparent,
                    ),
                    child: IntrinsicWidth(
                      child: _isEditing
                          ? TextField(
                              controller: _controller,
                              autofocus: true,
                              style: TextStyle(
                                  fontSize: widget.element.fontSize,
                                  color: widget.element.color,
                                  fontWeight: widget.element.isBold ? FontWeight.bold : FontWeight.normal,
                              ),
                              decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: 'Type something',
                                  hintStyle: TextStyle(color: Colors.grey),
                              ),
                              maxLines: null,
                              onChanged: (val) {
                                  widget.onUpdate(widget.element.copyWith(text: val));
                              },
                              onSubmitted: (_) => setState(() => _isEditing = false),
                              onTapOutside: (_) => setState(() => _isEditing = false),
                            )
                          : Text(
                              widget.element.text.isEmpty ? 'Type something' : widget.element.text,
                              style: TextStyle(
                                fontSize: widget.element.fontSize,
                                color: widget.element.text.isEmpty ? Colors.grey : widget.element.color,
                                fontWeight: widget.element.isBold ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                    ),
                  ),
               ),
             ),

             // 2. Handles (Only when selected)
             // We position them relative to the Stack edges. 
             // Since Stack = Text + 2*padding, the text is at 'padding' offset.
             // Corner handles are at 'padding - handleSize/2'.
             if (widget.isSelected) ...[
                 // --- Move Handle (Bottom Center) ---
                 Positioned(
                    bottom: padding - 35, // 35px below text bottom
                    child: GestureDetector(
                       onPanUpdate: (details) {
                          // Correct for rotation when dragging
                          final dx = details.delta.dx * math.cos(widget.element.rotation) - details.delta.dy * math.sin(widget.element.rotation);
                          final dy = details.delta.dx * math.sin(widget.element.rotation) + details.delta.dy * math.cos(widget.element.rotation);
                          
                          widget.onUpdate(widget.element.copyWith(
                              x: widget.element.x + dx,
                              y: widget.element.y + dy,
                          ));
                       },
                       child: Container(
                         width: 32, height: 32,
                         decoration: BoxDecoration(
                           color: Colors.white,
                           shape: BoxShape.circle,
                           boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                         ),
                         child: const Icon(Icons.drag_handle, size: 18, color: Colors.blue),
                       ),
                    ),
                 ),

                 // --- Rotate Handle (Top Center) ---
                 Positioned(
                    top: padding - 40, // 40px above text top
                    child: GestureDetector(
                       onPanUpdate: (details) {
                           widget.onUpdate(widget.element.copyWith(
                               rotation: widget.element.rotation + details.delta.dx * 0.01,
                           ));
                       },
                       child: Container(
                         width: 32, height: 32,
                         decoration: BoxDecoration(
                           color: Colors.white,
                           shape: BoxShape.circle,
                           boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                         ),
                         child: const Icon(Icons.refresh, size: 18, color: Colors.black87),
                       ),
                    ),
                 ),

                 // --- Resize Handles (Corners) ---
                 // Text Box Box is from [padding, padding] to [width+padding, height+padding]
                 // Need to account for that. 
                 // Actually, using 'Positioned' with top/left/right/bottom on Stack works relative to Stack edges.
                 // Left edge of Text is 'padding'. Top is 'padding'.
                 // Right edge of Text is 'padding + width'.
                 // BUT, for Positioned(right: ...), it's from right edge of Stack.
                 // Stack Width = width + 2*padding.
                 // So Right Edge of Text is 'padding' away from Stack Right Edge.
                 // So we can use `left: padding`, `top: padding`, `right: padding`, `bottom: padding` as the Text Rect base.
                 
                 // Top Left
                 _buildResizeHandle(top: padding - handleSize/2, left: padding - handleSize/2, 
                    onDrag: (dx, dy) {} 
                 ),
                 // Top Right
                 _buildResizeHandle(top: padding - handleSize/2, right: padding - handleSize/2, 
                    onDrag: (dx, dy) => _resizeWidth(dx)
                 ),
                 // Bottom Left
                 _buildResizeHandle(bottom: padding - handleSize/2, left: padding - handleSize/2, 
                    onDrag: (dx, dy) {} 
                 ),
                 // Bottom Right
                 _buildResizeHandle(bottom: padding - handleSize/2, right: padding - handleSize/2, 
                    onDrag: (dx, dy) => _resizeWidth(dx)
                 ),
             ],
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle({double? top, double? bottom, double? left, double? right, required Function(double dx, double dy) onDrag}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
        child: Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blue, width: 2),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  void _resizeWidth(double dx) {
      widget.onUpdate(widget.element.copyWith(
        width: math.max(50.0, widget.element.width + dx),
      ));
  }
}    
// Helper extension for easier updates
extension TextElementCopy on TextElement {
  TextElement copyWith({
    String? id, String? text, double? x, double? y, 
    double? fontSize, Color? color, double? width, double? rotation, bool? isBold
  }) {
    return TextElement(
      id: id ?? this.id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      width: width ?? this.width,
      rotation: rotation ?? this.rotation,
      isBold: isBold ?? this.isBold,
    );
  }
}
