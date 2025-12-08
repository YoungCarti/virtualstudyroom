import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
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

  // Facebook Sign In
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final OAuthCredential credential = FacebookAuthProvider.credential(accessToken.token);
        
        final userCred = await _auth.signInWithCredential(credential);
        if (userCred.user != null) {
          await _ensureUserProfile(userCred.user!);
        }
        return userCred;
      }
      return null;
    } catch (e) {
      throw Exception('Facebook Sign In failed: $e');
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
