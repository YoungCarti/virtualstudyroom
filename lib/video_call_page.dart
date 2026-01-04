import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../config/agora_config.dart';

class VideoCallPage extends StatefulWidget {
  final String channelName;
  final String classCode;
  final String groupId;
  final String groupName;
  final String? messageId; // Optional message ID for tracking participants

  const VideoCallPage({
    Key? key,
    required this.channelName,
    required this.classCode,
    required this.groupId,
    required this.groupName,
    this.messageId,
  }) : super(key: key);

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> with WidgetsBindingObserver {
  late RtcEngine _engine;
  final List<int> _remoteUids = [];
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isFrontCamera = true;
  Timer? _callTimer;
  int _callDuration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAgora();
  }

  Future<void> _initializeAgora() async {
    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Create Agora engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: AgoraConfig.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Register event handlers
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('✅ SUCCESS: Local user joined channel: ${connection.channelId}, UID: ${connection.localUid}');
          setState(() {
            _localUserJoined = true;
          });
          _startCallTimer();
          _updateParticipantStatus(true); // Join
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('✅ Remote user joined: $remoteUid');
          setState(() {
            _remoteUids.add(remoteUid);
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint('❌ Remote user $remoteUid left channel');
          setState(() {
            _remoteUids.remove(remoteUid);
          });
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint('❌ AGORA ERROR: $err - $msg');
        },
        onConnectionStateChanged: (RtcConnection connection, 
            ConnectionStateType state, ConnectionChangedReasonType reason) {
          debugPrint('🔄 Connection state changed: $state, reason: $reason');
        },
      ),
    );

    // Enable video
    await _engine.enableVideo();
    await _engine.startPreview();

    // Join channel with proper options
    await _engine.joinChannel(
      token: '', // Use empty string for now, implement token server for production
      channelId: widget.channelName,
      uid: 0, // Let Agora assign UID
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _updateParticipantStatus(bool isJoining) async {
    if (widget.messageId == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('classes').doc(widget.classCode)
        .collection('groups').doc(widget.groupId)
        .collection('messages').doc(widget.messageId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        List<String> participants = List<String>.from(snapshot.data()?['participants'] ?? []);

        if (isJoining) {
          if (!participants.contains(uid)) {
            participants.add(uid);
            transaction.update(docRef, {'participants': participants});
          }
        } else {
          participants.remove(uid);
          // If no participants left, mark as ended
          if (participants.isEmpty) {
            transaction.update(docRef, {
              'participants': participants,
              'status': 'ended'
            });
          } else {
            transaction.update(docRef, {'participants': participants});
          }
        }
      });
    } catch (e) {
      debugPrint("Error updating participant status: $e");
    }
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _engine.muteLocalAudioStream(_isMuted);
  }

  Future<void> _toggleCamera() async {
    setState(() {
      _isCameraOff =!_isCameraOff;
    });
    await _engine.muteLocalVideoStream(_isCameraOff);
  }

  Future<void> _switchCamera() async {
    await _engine.switchCamera();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  Future<void> _leaveCall() async {
    await _updateParticipantStatus(false); // Leave
    await _engine.leaveChannel();
    await _engine.release();
    _callTimer?.cancel();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callTimer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) {
      _updateParticipantStatus(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video grid
            _buildVideoGrid(),
            
            // Top bar with group name and timer
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.groupName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(_callDuration),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Control buttons at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      onPressed: _toggleMute,
                      color: _isMuted ? Colors.red : Colors.white,
                    ),
                    _buildControlButton(
                      icon:_isCameraOff ? Icons.videocam_off : Icons.videocam,
                      onPressed: _toggleCamera,
                      color: _isCameraOff ? Colors.red : Colors.white,
                    ),
                    _buildControlButton(
                      icon: Icons.flip_camera_ios,
                      onPressed: _switchCamera,
                      color: Colors.white,
                    ),
                    _buildControlButton(
                      icon: Icons.call_end,
                      onPressed: _leaveCall,
                      color: Colors.white,
                      backgroundColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? Colors.white.withOpacity(0.2),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        iconSize: 30,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildVideoGrid() {
    final participants = [0, ..._remoteUids]; // 0 represents local user
    
    if (participants.isEmpty || !_localUserJoined) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Single participant (just local user)
    if (participants.length == 1) {
      return _buildVideoView(0, isLocal: true);
    }

    // Two participants (local + 1 remote)
    if (participants.length == 2) {
      return Stack(
        children: [
          // Remote user takes full screen
          _buildVideoView(_remoteUids.first, isLocal: false),
          // Local user in small window
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildVideoView(0, isLocal: true),
              ),
            ),
          ),
        ],
      );
    }

    // Multiple participants - grid view
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: participants.length <= 4 ? 2 : 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final uid = participants[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildVideoView(uid, isLocal: uid == 0),
          ),
        );
      },
    );
  }

  Widget _buildVideoView(int uid, {required bool isLocal}) {
    if (_isCameraOff && isLocal) {
      return Container(
        color: Colors.grey[900],
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white, size: 48),
        ),
      );
    }

    if (isLocal) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _engine,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: uid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    }
  }
}
