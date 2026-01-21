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

  Stream<List<TextElement>> getTextElements(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('texts')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TextElement.fromMap(doc.data())).toList();
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

  Future<void> addTextElement(String roomId, TextElement element) async {
     await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('texts')
        .doc(element.id)
        .set(element.toMap());
  }

  Future<void> updateTextElement(String roomId, TextElement element) async {
     await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('texts')
        .doc(element.id)
        .update(element.toMap());
  }

  Future<void> deleteTextElement(String roomId, String elementId) async {
      await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('texts')
        .doc(elementId)
        .delete();
  }

  Stream<List<StickyNoteElement>> getStickyNotes(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('sticky_notes')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StickyNoteElement.fromMap(doc.data())).toList();
    });
  }

  Future<void> addStickyNote(String roomId, StickyNoteElement element) async {
     await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('sticky_notes')
        .doc(element.id)
        .set(element.toMap());
  }

  Future<void> updateStickyNote(String roomId, StickyNoteElement element) async {
     await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('sticky_notes')
        .doc(element.id)
        .update(element.toMap());
  }

  Future<void> deleteStickyNote(String roomId, String elementId) async {
      await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('sticky_notes')
        .doc(elementId)
        .delete();
  }

  Future<void> clearCanvas(String roomId) async {
    final batch = _firestore.batch();
    
    // Clear strokes
    final strokeSnapshots = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('strokes')
        .get();

    for (var doc in strokeSnapshots.docs) {
      batch.delete(doc.reference);
    }
    
    // Clear texts
    final textSnapshots = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('texts')
        .get();

    for (var doc in textSnapshots.docs) {
      batch.delete(doc.reference);
    }

    // Clear sticky notes
    final noteSnapshots = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('sticky_notes')
        .get();

    for (var doc in noteSnapshots.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
