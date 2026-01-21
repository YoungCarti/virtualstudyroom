import 'package:flutter/material.dart';
import '../canvas/canvas_model.dart';
import 'dart:math' as math;

class StickyNoteWidget extends StatefulWidget {
  final StickyNoteElement element;
  final bool isSelected;
  final Function(StickyNoteElement) onUpdate;
  final Function(String) onSelect;
  final double scale;

  const StickyNoteWidget({
    Key? key,
    required this.element,
    required this.isSelected,
    required this.onUpdate,
    required this.onSelect,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  State<StickyNoteWidget> createState() => _StickyNoteWidgetState();
}

class _StickyNoteWidgetState extends State<StickyNoteWidget> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.element.text);
  }

  @override
  void didUpdateWidget(StickyNoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.element.text != _controller.text && !_isEditing) {
      _controller.text = widget.element.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double padding = 40.0; // Padding for handles
    const double handleSize = 12.0;

    return Positioned(
      left: widget.element.x - padding,
      top: widget.element.y - padding,
      child: GestureDetector(
        onTap: () {
          widget.onSelect(widget.element.id);
        },
        onDoubleTap: () {
           setState(() => _isEditing = true);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. The Sticky Note Visual
            Padding(
              padding: const EdgeInsets.all(padding),
              child: Container(
                width: widget.element.width,
                height: widget.element.height,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.element.color,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(4, 4)),
                  ],
                ),
                child: _isEditing
                    ? TextField(
                        controller: _controller,
                        autofocus: true,
                        maxLines: null,
                        expands: true,
                        textAlign: TextAlign.center, // Usually sticky notes are centered? Let's default to start for now
                        style: TextStyle(fontSize: widget.element.fontSize, color: Colors.black87),
                        decoration: const InputDecoration(border: InputBorder.none),
                        onChanged: (val) {
                          widget.onUpdate(widget.element.copyWith(text: val));
                        },
                        onTapOutside: (_) => setState(() => _isEditing = false),
                      )
                    : Text(
                        widget.element.text,
                        style: TextStyle(fontSize: widget.element.fontSize, color: Colors.black87),
                      ),
              ),
            ),

            // 2. Selection Border and Handles
            if (widget.isSelected) ...[
              // Selection Border (Visual Only)
              Positioned(
                left: padding - 4,
                top: padding - 4,
                width: widget.element.width + 8,
                height: widget.element.height + 8,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blueAccent, width: 1.5),
                  ),
                ),
              ),

              // --- Move Handle (Bottom Center) ---
              Positioned(
                bottom: padding - 40,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      widget.onUpdate(widget.element.copyWith(
                        x: widget.element.x + details.delta.dx,
                        y: widget.element.y + details.delta.dy,
                      ));
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.blue, // Blue dot as per description/screenshot "blue circular move handle"
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      // child: const Icon(Icons.open_with, size: 16, color: Colors.white), // Dot might be solid blue? Screenshot shows solid blue dot.
                    ),
                  ),
                ),
              ),

              // --- Resize Handles (8 points) ---
              // Corners
              _buildResizeHandle(top: padding - 4 - handleSize/2, left: padding - 4 - handleSize/2, onDrag: (dx, dy) => _resize(-dx, -dy, true, true)),
              _buildResizeHandle(top: padding - 4 - handleSize/2, right: padding - 4 - handleSize/2, onDrag: (dx, dy) => _resize(dx, -dy, false, true)),
              _buildResizeHandle(bottom: padding - 4 - handleSize/2, left: padding - 4 - handleSize/2, onDrag: (dx, dy) => _resize(-dx, dy, true, false)),
              _buildResizeHandle(bottom: padding - 4 - handleSize/2, right: padding - 4 - handleSize/2, onDrag: (dx, dy) => _resize(dx, dy, false, false)),

              // Sides
              _buildResizeHandle(top: padding - 4 - handleSize/2, left: 0, right: 0, isSide: true, onDrag: (dx, dy) => _resize(0, -dy, false, true)), // Top
              _buildResizeHandle(bottom: padding - 4 - handleSize/2, left: 0, right: 0, isSide: true, onDrag: (dx, dy) => _resize(0, dy, false, false)), // Bottom
              _buildResizeHandle(top: 0, bottom: 0, left: padding - 4 - handleSize/2, isSide: true, onDrag: (dx, dy) => _resize(-dx, 0, true, false)), // Left
              _buildResizeHandle(top: 0, bottom: 0, right: padding - 4 - handleSize/2, isSide: true, onDrag: (dx, dy) => _resize(dx, 0, false, false)), // Right
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResizeHandle({double? top, double? bottom, double? left, double? right, bool isSide = false, required Function(double dx, double dy) onDrag}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Center(
        child: GestureDetector(
          onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey, width: 2), // Grey border as per screenshot usually
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  void _resize(double dx, double dy, bool left, bool top) {
    double newX = widget.element.x;
    double newY = widget.element.y;
    double newWidth = widget.element.width;
    double newHeight = widget.element.height;

    if (left) {
       newX += dx;
       newWidth -= dx;
    } else {
       newWidth += dx;
    }

    if (top) {
       newY += dy;
       newHeight -= dy;
    } else {
       newHeight += dy;
    }

    if (newWidth < 50) newWidth = 50;
    if (newHeight < 50) newHeight = 50;

    widget.onUpdate(widget.element.copyWith(
      x: newX,
      y: newY,
      width: newWidth,
      height: newHeight,
    ));
  }
}
