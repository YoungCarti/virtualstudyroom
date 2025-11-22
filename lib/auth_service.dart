import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in and ensure a profile document exists.
  Future<void> signInWithEmail(String email, String password) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCred.user;
      if (user == null) throw Exception('Sign-in returned no user.');
      await _ensureUserProfile(user);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Register, set a display name and create profile document.
  Future<void> registerWithEmail(String email, String password) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCred.user;
      if (user == null) throw Exception('Registration returned no user.');

      // Set a default display name (local part of email) if none set.
      final defaultName = email.split('@').first;
      await user.updateDisplayName(defaultName);

      await _ensureUserProfile(user);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Ensure Firestore user doc exists. If missing, create with sensible defaults.
  Future<void> _ensureUserProfile(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await docRef.set({
        'email': user.email,
        'name': user.displayName ?? (user.email?.split('@').first ?? 'New User'),
        'role': 'student',
        'enrolledClasses': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Expose current Firebase user if needed elsewhere.
  User? get currentUser => _auth.currentUser;

  Future<void> signOut() => _auth.signOut();
}
