import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  AuthService._privateConstructor();
  static final AuthService instance = AuthService._privateConstructor();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --- NEW: Reset Password via Email ---
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

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

  // Helper to determine role based on email domain
  String _getRoleFromEmail(String email) {
    final lowerEmail = email.toLowerCase().trim();
    // .edu domain = lecturer, otherwise student
    if (lowerEmail.endsWith('.edu') || lowerEmail.endsWith('.edu.my')) {
      return 'lecturer';
    }
    return 'student';
  }

  // Register, set a display name and create profile document.
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? role,
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

      // Determine role: use provided role if valid, otherwise auto-detect
      final finalRole = (role == 'student' || role == 'lecturer')
          ? role!
          : _getRoleFromEmail(email);

      // Create user profile in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': email.trim(),
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'name': displayName,
        'role': finalRole,
        'enrolledClasses': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'currentStreak': 1,
        'longestStreak': 1,
        'lastActiveAt': FieldValue.serverTimestamp(),
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
      // Determine role based on email domain
      final role = _getRoleFromEmail(user.email ?? '');
      
      await docRef.set({
        'email': user.email,
        'name': user.displayName ?? (user.email?.split('@').first ?? 'New User'),
        'role': role, // Auto-assign based on .edu domain
        'enrolledClasses': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'currentStreak': 1,
        'longestStreak': 1,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } else {
        // Doc exists, update streak
        await updateUserStreak(user);
    }
  }

  // --- NEW: Streak Logic ---
  Future<void> updateUserStreak([User? user]) async {
    final currentUser = user ?? _auth.currentUser;
    if (currentUser == null) return;
    
    final docRef = _firestore.collection('users').doc(currentUser.uid);
    
    try {
      final doc = await docRef.get();
      if (!doc.exists) return; // Should allow _ensureUserProfile to handle init if needed, but safe check
      
      final data = doc.data() ?? {};
      final lastActiveTs = data['lastActiveAt'] as Timestamp?;
      int currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;
      int longestStreak = (data['longestStreak'] as num?)?.toInt() ?? 0;
      
      final now = DateTime.now();
      
      if (lastActiveTs == null) {
        // First time active or missing data
        await docRef.update({
          'lastActiveAt': FieldValue.serverTimestamp(),
          'currentStreak': 1,
          'longestStreak': (longestStreak < 1) ? 1 : longestStreak,
        });
        return;
      }
      
      final lastActiveDate = lastActiveTs.toDate();
      
      // Calculate difference in days (ignoring time)
      final dateNow = DateTime(now.year, now.month, now.day);
      final dateLast = DateTime(lastActiveDate.year, lastActiveDate.month, lastActiveDate.day);
      
      final difference = dateNow.difference(dateLast).inDays;
      
      if (difference == 0) {
        // Same day, do nothing (or update timestamp if we want precise last active time)
         await docRef.update({'lastActiveAt': FieldValue.serverTimestamp()});
         return;
      }
      
      if (difference == 1) {
        // Consecutive day
        currentStreak++;
      } else {
        // Missed a day (or more)
        currentStreak = 1;
      }
      
      if (currentStreak > longestStreak) {
        longestStreak = currentStreak;
      }
      
      await docRef.update({
        'lastActiveAt': FieldValue.serverTimestamp(),
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
      });
      
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  // Expose current Firebase user if needed elsewhere.
  User? get currentUser => _auth.currentUser;

  Future<void> signOut() => _auth.signOut();
}