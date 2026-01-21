import 'package:cloud_firestore/cloud_firestore.dart';
import '../canvas/canvas_model.dart'; // Ensure correct import path

class CanvasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Stroke>> getStrokes(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('strokes')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Stroke.fromMap(doc.data())).toList();
    });
  }

  Future<void> addStroke(String roomId, Stroke stroke) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('strokes')
        .doc(stroke.id)
        .set(stroke.toMap());
  }

  Future<void> clearCanvas(String roomId) async {
    final batch = _firestore.batch();
    final snapshots = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('strokes')
        .get();

    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
