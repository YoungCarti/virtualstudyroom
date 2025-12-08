import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCred.user;
      if (user == null) throw Exception('Registration returned no user.');

      // Set display name
      final displayName = '$firstName $lastName';
      await user.updateDisplayName(displayName);

      // Create user profile in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': email.trim(),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'name': displayName,
        'phone': phone.trim(),
        'role': 'student',
        'enrolledClasses': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      if (userCred.user != null) {
        await _ensureUserProfile(userCred.user!);
      }
      return userCred;
    } catch (e) {
      throw Exception('Google Sign In failed: $e');
    }
  }


  // Secure Storage for Remember Me
  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'password', value: password);
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    String? email = await _storage.read(key: 'email');
    String? password = await _storage.read(key: 'password');
    return {'email': email, 'password': password};
  }

  Future<void> clearSavedCredentials() async {
    await _storage.delete(key: 'email');
    await _storage.delete(key: 'password');
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
