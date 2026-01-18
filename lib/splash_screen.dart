import 'app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:video_player/video_player.dart'; // Option 2: Uncomment for video background

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.onFinished,
    required this.isReadyToProceed,
  });

  final void Function(bool isRegister) onFinished;
  final bool isReadyToProceed;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Option 2: Looping Video Background (Commented out by default)
  /*
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  */

  @override
  void initState() {
    super.initState();
    // Option 2: Initialize Video
    /*
    // PASTE YOUR VIDEO URL HERE OR ASSET PATH
    // Example: _controller = VideoPlayerController.networkUrl(Uri.parse('https://example.com/video.mp4'));
    // Example: _controller = VideoPlayerController.asset('assets/videos/background.mp4');
    
    _controller = VideoPlayerController.asset('assets/videos/splash_bg.mp4')
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.setVolume(0.0); // Muted
        _controller.play();
        setState(() {
          _isVideoInitialized = true;
        });
      });
    */
  }

  @override
  void dispose() {
    // Option 2: Dispose Video Controller
    // _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // -----------------------------------------------------------
          // LAYER 1: Background
          // -----------------------------------------------------------
          
          // Option 1: Static Background (Default)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D1B4E), // Deep Purple
                  Color(0xFF1A0E33), // Darker Purple
                ],
              ),
            ),
          ),
          
          // Static Image Layer
          Image.asset(
            'assets/images/splashscreen.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if image is missing
              return Container(color: const Color(0xFF2D1B4E));
            },
          ),

          // Option 2: Looping Video (Commented)
          /*
          if (_isVideoInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
          */

          // -----------------------------------------------------------
          // LAYER 2: Overlay (For Text Readability)
          // -----------------------------------------------------------
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromRGBO(45, 27, 78, 0.4), // Top
                  Color.fromRGBO(26, 14, 51, 0.7), // Bottom
                ],
              ),
            ),
          ),

          // -----------------------------------------------------------
          // LAYER 3: Content
          // -----------------------------------------------------------
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // Welcome Text Section
                  Text(
                    "Welcome to StudyLink",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      "Join a growing community of students and enjoy a more focused and connected way of studying together online",
                      style: AppFonts.clashGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Button Section
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (widget.isReadyToProceed) {
                          widget.onFinished(true); // isRegister = true
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2D1B4E),
                        elevation: 8,
                        shadowColor: Colors.black.withValues(alpha: 0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: AppFonts.clashGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ).copyWith(
                        // Add slight scale down interaction manually if needed or rely on material ripple
                        // For simple scale, we'd need a custom widget, but standard button is fine for now
                      ),
                      child: const Text("Create an account"),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Login Link
                  GestureDetector(
                    onTap: () {
                      if (widget.isReadyToProceed) {
                        widget.onFinished(false); // isRegister = false
                      }
                    },
                    child: RichText(
                      text: TextSpan(
                        style: AppFonts.clashGrotesk(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        children: [
                          TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const TextSpan(
                            text: "Log in",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
