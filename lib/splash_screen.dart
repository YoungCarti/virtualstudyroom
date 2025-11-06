import 'package:flutter/material.dart';

// Minimal splash screen placeholder. Replace with your real splash UI if needed.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
