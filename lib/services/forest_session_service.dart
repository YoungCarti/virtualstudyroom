import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForestSession {
  final String id;
  final DateTime timestamp;
  final int durationMinutes;
  final bool completed;

  ForestSession({
    required this.id,
    required this.timestamp,
    required this.durationMinutes,
    required this.completed,
  });

  factory ForestSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ForestSession(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 25,
      completed: data['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'durationMinutes': durationMinutes,
      'completed': completed,
    };
  }
}

class ForestSessionService {
  static final ForestSessionService _instance = ForestSessionService._internal();
  factory ForestSessionService() => _instance;
  ForestSessionService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _sessionsRef {
    if (_userId == null) throw Exception('User not logged in');
    return _firestore.collection('users').doc(_userId).collection('forest_sessions');
  }

  /// Save a completed focus session
  Future<bool> saveSession({required int durationMinutes}) async {
    if (_userId == null) {
      print('ForestSessionService: Cannot save - user not logged in');
      return false;
    }
    
    try {
      await _sessionsRef.add({
        'timestamp': Timestamp.now(),
        'durationMinutes': durationMinutes,
        'completed': true,
      });
      print('ForestSessionService: Session saved successfully - $durationMinutes mins');
      return true;
    } catch (e) {
      print('ForestSessionService: Error saving session - $e');
      return false;
    }
  }

  /// Get all sessions for today
  Stream<List<ForestSession>> getTodaySessions() {
    if (_userId == null) return Stream.value([]);
    
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Simplified query to avoid composite index requirement
    return _sessionsRef
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) => 
            snapshot.docs
                .map((doc) => ForestSession.fromFirestore(doc))
                .where((session) => session.completed) // Filter locally
                .toList());
  }

  /// Get total focus minutes for today
  Stream<int> getTodayFocusMinutes() {
    return getTodaySessions().map((sessions) =>
        sessions.fold(0, (total, s) => total + s.durationMinutes));
  }

  /// Get session count for today
  Stream<int> getTodayTreeCount() {
    return getTodaySessions().map((sessions) => sessions.length);
  }
}
