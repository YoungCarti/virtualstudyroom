// Simple stubbed auth service for local testing.
// Replace with FirebaseAuth implementation later.
import 'dart:async';

class AuthService {
  // Simulate sign-in. Returns true on success, false on failure.
  // If email contains 'fail' we treat it as failure for testing.
  Future<bool> signIn(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email.contains('fail')) return false;
    return true;
  }

  // Simulate registration.
  Future<bool> register(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email.contains('fail')) return false;
    return true;
  }
}
