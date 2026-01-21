import 'package:flutter/material.dart';
import '../canvas/canvas_model.dart';
import 'shape_painter.dart';

class ShapeWidget extends StatelessWidget {
  final ShapeElement element;
  final bool isSelected;
  final Function(String) onSelect;
  final Function(ShapeElement) onUpdate;

  const ShapeWidget({
    super.key,
    required this.element,
    required this.isSelected,
    required this.onSelect,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: element.x,
      top: element.y,
      child: GestureDetector(
        onTap: () => onSelect(element.id),
        onPanUpdate: isSelected ? (details) {
            onUpdate(element.copyWith(
                x: element.x + details.delta.dx,
                y: element.y + details.delta.dy,
            ));
        } : null,
        child: Container(
             width: element.width + 40, // Padding for handles
             height: element.height + 40,
             child: Stack(
                 clipBehavior: Clip.none,
                 children: [
                     // The Shape
                     Positioned(
                         left: 20, top: 20,
                         child: Container(
                             width: element.width,
                             height: element.height,
                             padding: const EdgeInsets.all(4), // Selection padding
                             decoration: isSelected ? BoxDecoration(
                                 border: Border.all(color: Colors.blueAccent, width: 2),
                             ) : null,
                             child: CustomPaint(
                                 size: Size(element.width, element.height),
                                 painter: ShapePainter(element: element),
                             ),
                         ),
                     ),

                     // Resize Handles (Only when selected)
                     if (isSelected && element.type != ShapeType.line && element.type != ShapeType.arrow)
                        ..._buildResizeHandles(),
                 ],
             ),
        ),
      ),
    );
  }

  List<Widget> _buildResizeHandles() {
      return [
          // Bottom Right handle for simple resizing
          Positioned(
              right: 10,
              bottom: 10,
              child: GestureDetector(
                  onPanUpdate: (details) {
                       onUpdate(element.copyWith(
                           width: (element.width + details.delta.dx).clamp(20.0, 1000.0),
                           height: (element.height + details.delta.dy).clamp(20.0, 1000.0),
                       ));
                  },
                  child: Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.open_in_full, size: 12, color: Colors.white),
                  ),
              ),
          )
      ];
  }
}
