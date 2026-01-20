import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'app_fonts.dart';
import 'config/agora_config.dart';

// Ocean Sunset Color Palette
const Color _deepNavy = Color(0xFF0A1929);
const Color _midnightBlue = Color(0xFF122A46);
const Color _electricBlue = Color(0xFF2196F3);
const Color _coralPink = Color(0xFFFF6B6B);
const Color _mintGreen = Color(0xFF4ECDC4);
const Color _softOrange = Color(0xFFFFB347);
const Color _pureWhite = Color(0xFFFFFFFF);
const Color _discordBlue = Color(0xFF5865F2);

class StudyRoomDetailPage extends StatefulWidget {
  const StudyRoomDetailPage({super.key, required this.roomName, this.roomId});

  final String roomName;
  final String? roomId;

  @override
  State<StudyRoomDetailPage> createState() => _StudyRoomDetailPageState();
}

class _StudyRoomDetailPageState extends State<StudyRoomDetailPage> with WidgetsBindingObserver {
  // Agora (for mobile)
  RtcEngine? _engine;
  final List<int> _remoteUids = [];
  
  bool _localUserJoined = false;
  bool _isInitializing = true;
  String? _error;
  
  // Controls
  bool _micOn = true;
  bool _cameraOn = true;
  bool _isFrontCamera = true;

  // Timer
  Timer? _sessionTimer;
  int _sessionDuration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAgora();
  }

  Future<void> _initializeAgora() async {
    try {
      // Request permissions (mobile only)
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();
      
      if (cameraStatus.isDenied || micStatus.isDenied) {
        setState(() {
          _error = 'Camera and microphone permissions are required';
          _isInitializing = false;
        });
        return;
      }

      // Create Agora engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: AgoraConfig.appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('✅ Joined study room: ${connection.channelId}');
            setState(() {
              _localUserJoined = true;
              _isInitializing = false;
            });
            _startSessionTimer();
            _updateRoomParticipants(true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('✅ User joined: $remoteUid');
            setState(() {
              if (!_remoteUids.contains(remoteUid)) {
                _remoteUids.add(remoteUid);
              }
            });
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('❌ User left: $remoteUid');
            setState(() {
              _remoteUids.remove(remoteUid);
            });
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('❌ Agora Error: $err - $msg');
            setState(() {
              _error = 'Connection error: $msg';
            });
          },
        ),
      );

      // Enable video
      await _engine!.enableVideo();
      await _engine!.startPreview();

      // Generate channel name from room
      final channelName = 'studyroom_${widget.roomId ?? widget.roomName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}';
      
      // Join channel
      await _engine!.joinChannel(
        token: '',
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize: $e';
        _isInitializing = false;
      });
    }
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _sessionDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _updateRoomParticipants(bool joining) async {
    if (widget.roomId == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final docRef = FirebaseFirestore.instance.collection('study_rooms').doc(widget.roomId);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data()!;
        List<String> members = List<String>.from(data['members'] ?? []);
        int activeUsers = data['activeUsers'] ?? 0;

        if (joining) {
          if (!members.contains(uid)) {
            members.add(uid);
          }
          transaction.update(docRef, {
            'members': members,
            'activeUsers': activeUsers + 1,
          });
        } else {
          members.remove(uid);
          transaction.update(docRef, {
            'members': members,
            'activeUsers': (activeUsers - 1).clamp(0, 999),
          });
        }
      });
    } catch (e) {
      debugPrint('Error updating participants: $e');
    }
  }

  Future<void> _toggleMic() async {
    setState(() => _micOn = !_micOn);
    await _engine?.muteLocalAudioStream(!_micOn);
  }

  Future<void> _toggleCamera() async {
    setState(() => _cameraOn = !_cameraOn);
    await _engine?.muteLocalVideoStream(!_cameraOn);
  }

  Future<void> _switchCamera() async {
    await _engine?.switchCamera();
    setState(() => _isFrontCamera = !_isFrontCamera);
  }

  Future<void> _leaveRoom() async {
    await _updateRoomParticipants(false);
    await _engine?.leaveChannel();
    await _engine?.release();
    _sessionTimer?.cancel();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    _updateRoomParticipants(false);
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      _updateRoomParticipants(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    
    int crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 4);
    
    return Scaffold(
      backgroundColor: _deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(isMobile),
            Expanded(
              child: _isInitializing
                  ? _buildLoadingView()
                  : _error != null
                      ? _buildErrorView()
                      : _buildVideoGrid(crossAxisCount, isMobile),
            ),
            _buildBottomControls(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: _electricBlue),
          const SizedBox(height: 16),
          Text(
            'Joining ${widget.roomName}...',
            style: AppFonts.clashGrotesk(color: _pureWhite, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: _coralPink, size: 48),
          const SizedBox(height: 16),
          Text(
            _error ?? 'An error occurred',
            style: AppFonts.clashGrotesk(color: _coralPink, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _electricBlue),
            onPressed: () {
              setState(() {
                _error = null;
                _isInitializing = true;
              });
              _initializeAgora();
            },
            child: Text('Retry', style: AppFonts.clashGrotesk(color: _pureWhite)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _midnightBlue,
        border: Border(bottom: BorderSide(color: _pureWhite.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: _pureWhite),
            onPressed: _leaveRoom,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.roomName,
                  style: AppFonts.clashGrotesk(
                    color: _pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_localUserJoined)
                  Text(
                    _formatDuration(_sessionDuration),
                    style: AppFonts.clashGrotesk(
                      color: _mintGreen,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          
          // Participant count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _pureWhite.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, size: 16, color: _mintGreen),
                const SizedBox(width: 6),
                Text(
                  '${_remoteUids.length + (_localUserJoined ? 1 : 0)}',
                  style: AppFonts.clashGrotesk(
                    color: _pureWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid(int crossAxisCount, bool isMobile) {
    final totalParticipants = _remoteUids.length + 1; // +1 for local user
    
    if (totalParticipants == 1) {
      // Only local user - full screen
      return Padding(
        padding: const EdgeInsets.all(8),
        child: _buildVideoTile(0, isLocal: true, isMobile: isMobile),
      );
    }
    
    if (totalParticipants == 2) {
      // 2 participants - stack layout
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            // Remote user full screen
            _buildVideoTile(_remoteUids.first, isLocal: false, isMobile: isMobile),
            // Local user small
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: isMobile ? 100 : 160,
                height: isMobile ? 140 : 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _mintGreen, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildVideoTile(0, isLocal: true, isMobile: isMobile, isSmall: true),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Grid for 3+ participants
    return GridView.builder(
      padding: EdgeInsets.all(isMobile ? 8 : 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isMobile ? 8 : 12,
        mainAxisSpacing: isMobile ? 8 : 12,
        childAspectRatio: isMobile ? 3 / 4 : 16 / 10,
      ),
      itemCount: totalParticipants,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildVideoTile(0, isLocal: true, isMobile: isMobile);
        }
        return _buildVideoTile(_remoteUids[index - 1], isLocal: false, isMobile: isMobile);
      },
    );
  }

  Widget _buildVideoTile(int uid, {required bool isLocal, required bool isMobile, bool isSmall = false}) {
    return Container(
      decoration: BoxDecoration(
        color: _midnightBlue,
        borderRadius: BorderRadius.circular(12),
        border: isLocal && !isSmall
            ? Border.all(color: _mintGreen, width: 2)
            : Border.all(color: _pureWhite.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video view
            if (_engine != null)
              _buildAgoraVideoView(uid, isLocal)
            else
              Container(color: _midnightBlue),

            // Camera off overlay
            if (isLocal && !_cameraOn)
              Container(
                color: _midnightBlue,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: isSmall ? 24 : 40,
                        backgroundColor: _discordBlue.withOpacity(0.3),
                        child: Icon(
                          Icons.person,
                          size: isSmall ? 24 : 40,
                          color: _pureWhite,
                        ),
                      ),
                      if (!isSmall) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Camera Off',
                          style: AppFonts.clashGrotesk(
                            color: _pureWhite.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Name tag
            if (!isSmall)
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLocal ? 'You' : 'User $uid',
                        style: AppFonts.clashGrotesk(
                          color: _pureWhite,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isLocal && !_micOn) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.mic_off, size: 14, color: _coralPink),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgoraVideoView(int uid, bool isLocal) {
    if (isLocal) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(
            channelId: 'studyroom_${widget.roomId ?? widget.roomName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
          ),
        ),
      );
    }
  }



  Widget _buildBottomControls(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: _midnightBlue,
        border: Border(top: BorderSide(color: _pureWhite.withOpacity(0.1))),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildControlButton(
              icon: _micOn ? Icons.mic : Icons.mic_off,
              isActive: _micOn,
              onTap: _toggleMic,
            ),
            SizedBox(width: isMobile ? 12 : 16),
            
            _buildControlButton(
              icon: _cameraOn ? Icons.videocam : Icons.videocam_off,
              isActive: _cameraOn,
              onTap: _toggleCamera,
            ),
            SizedBox(width: isMobile ? 12 : 16),
            
            _buildControlButton(
              icon: Icons.flip_camera_ios,
              isActive: true,
              onTap: _switchCamera,
            ),
            SizedBox(width: isMobile ? 12 : 16),
            
            _buildControlButton(
              icon: Icons.chat_bubble_outline,
              isActive: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat coming soon!')),
                );
              },
            ),
            
            SizedBox(width: isMobile ? 16 : 24),
            
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _coralPink,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: isMobile ? 12 : 14,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _leaveRoom,
              child: const Icon(Icons.call_end, size: 20, color: _pureWhite),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? _pureWhite.withOpacity(0.1) : _coralPink.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isActive ? _pureWhite : _coralPink,
        ),
      ),
    );
  }
}
