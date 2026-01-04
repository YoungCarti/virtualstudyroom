import 'dart:io';
import 'dart:math'; 
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart'; 
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import 'video_call_page.dart';
import 'audio_call_page.dart';
import 'config/agora_config.dart';
import 'group_info_page.dart';
import 'package:open_file/open_file.dart';


class GroupChatMessagesPage extends StatefulWidget {
  const GroupChatMessagesPage({
    super.key,
    required this.classCode,
    required this.groupId,
    required this.groupName,
  });

  final String classCode;
  final String groupId;
  final String groupName;

  @override
  State<GroupChatMessagesPage> createState() => _GroupChatMessagesPageState();
}

class _GroupChatMessagesPageState extends State<GroupChatMessagesPage> {
  final _msgController = TextEditingController();
  final _scrollCtrl = ScrollController();
  
  File? _selectedFile;
  String? _selectedFileType; 
  String? _selectedFileName;
  bool _isUploading = false;
  
  bool _showMentionSuggestions = false;
  final List<String> _mentionsList = ['gemini'];
  String _currentMentionQuery = '';
  
  bool _hasScrolledToBottom = false;
  String _currentUserName = 'User'; // Store current user name
  
  Map<String, String> _senderNameCache = {}; // Cache for sender names
  final Set<String> _fetchingSenderIds = {}; // Track IDs currently being fetched

  @override
  void initState() {
    super.initState();
    _msgController.addListener(_onTextChanged);
    _cleanupStaleMeetingParticipation();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists && mounted) {
           setState(() {
             _currentUserName = doc.data()?['fullName'] ?? doc.data()?['name'] ?? 'User';
           });
        }
      } catch (e) {
        // ignore
      }
    }
  }
  
  void _fetchSenderName(String senderId) {
    if (_senderNameCache.containsKey(senderId) || _fetchingSenderIds.contains(senderId)) return;
    
    _fetchingSenderIds.add(senderId);
    FirebaseFirestore.instance.collection('users').doc(senderId).get().then((doc) {
      if (!mounted) return;
      if (doc.exists) {
        final name = doc.data()?['fullName'] ?? doc.data()?['name'] ?? 'User';
        setState(() {
          _senderNameCache[senderId] = name;
        });
      }
      _fetchingSenderIds.remove(senderId);
    }).catchError((_) => _fetchingSenderIds.remove(senderId));
  }

  @override
  void dispose() {
    _msgController.removeListener(_onTextChanged);
    _msgController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // --- Meeting Logic ---
  String _generateMeetingCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
    return '${getRandomString(3)}-${getRandomString(3)}-${getRandomString(3)}';
    return '${getRandomString(3)}-${getRandomString(3)}-${getRandomString(3)}';
  }

  Future<void> _cleanupStaleMeetingParticipation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('classes').doc(widget.classCode)
          .collection('groups').doc(widget.groupId)
          .collection('messages')
          .where('type', isEqualTo: 'meeting')
          .where('participants', arrayContains: uid)
          .get();

      for (var doc in querySnapshot.docs) {
        // Run cleanup for each document found
        await FirebaseFirestore.instance.runTransaction((transaction) async {
            final snapshot = await transaction.get(doc.reference);
            if (!snapshot.exists) return;
            
            List<String> participants = List<String>.from(snapshot.data()?['participants'] ?? []);
            if (participants.contains(uid)) {
              participants.remove(uid);
              if (participants.isEmpty) {
                 transaction.update(doc.reference, {'participants': participants, 'status': 'ended'});
              } else {
                 transaction.update(doc.reference, {'participants': participants});
              }
            }
        });
      }
    } catch (e) {
      debugPrint("Error cleaning up stale meetings: $e");
    }

    _garbageCollectAbandonedMeetings();
  }

  Future<void> _garbageCollectAbandonedMeetings() async {
    try {
      final now = DateTime.now();
      final twoMinutesAgo = now.subtract(const Duration(minutes: 2));

      final querySnapshot = await FirebaseFirestore.instance
          .collection('classes').doc(widget.classCode)
          .collection('groups').doc(widget.groupId)
          .collection('messages')
          .where('type', isEqualTo: 'meeting')
          .get(); // Fetch all meetings to client-side filter (avoid composite index issues for now)

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'active';
        final participants = List<String>.from(data['participants'] ?? []);
        final createdAtRaw = data['createdAt'];
        DateTime? createdAt;

        if (createdAtRaw is Timestamp) {
          createdAt = createdAtRaw.toDate();
        }

        // Check if abandoned: Active, Empty, and Old (> 2 mins)
        if (status != 'ended' && participants.isEmpty) {
          if (createdAt != null && createdAt.isBefore(twoMinutesAgo)) {
             debugPrint("🗑️ Garbage collecting abandoned meeting: ${doc.id}");
             await doc.reference.update({'status': 'ended'});
          }
        }
      }
    } catch (e) {
      debugPrint("Error garbage collecting meetings: $e");
    }
  }

  void _showMeetingOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _GlassBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22D3EE).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.video_call_rounded, color: Color(0xFF22D3EE)),
                ),
                title: const Text("New Meeting", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Create a link to share", style: TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatedMeetingDialog();
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.keyboard_alt_rounded, color: Color(0xFFF59E0B)),
                ),
                title: const Text("Join with Code", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text("Enter a code provided by others", style: TextStyle(color: Colors.white54)),
                onTap: () {
                  Navigator.pop(context);
                  _showJoinDialog();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showCreatedMeetingDialog() {
    final String code = _generateMeetingCode();
    showDialog(
      context: context,
      builder: (context) => _GlassDialog(
        title: "Meeting Created",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Share this code with others:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            _GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(code, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code copied!")));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close", style: TextStyle(color: Colors.white54))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22D3EE), foregroundColor: Colors.black),
            icon: const Icon(Icons.login),
            label: const Text("Join Now"),
            onPressed: () async {
              Navigator.pop(context);
              
              // Auto-send meeting code to chat
              String? messageId;
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                try {
                  final docRef = await FirebaseFirestore.instance
                      .collection('classes').doc(widget.classCode)
                      .collection('groups').doc(widget.groupId)
                      .collection('messages').add({
                    'text': "Join my meeting! Code: $code",
                    'senderId': uid,
                    'senderName': _currentUserName,
                    'createdAt': FieldValue.serverTimestamp(),
                    'deletedBy': [],
                    'type': 'meeting',
                    'meetingCode': code,
                    'participants': [],
                    'status': 'active', // Initialize status
                  });
                  messageId = docRef.id;
                } catch (e) {
                  debugPrint("Error sending meeting code: $e");
                }
              }

              _joinMeetingWithCode(code, messageId: messageId);
            },
          ),
        ],
      ),
    );
  }

  void _showJoinDialog() {
    final TextEditingController codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => _GlassDialog(
        title: "Join Meeting",
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter the meeting code:", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            _GlassTextField(controller: codeCtrl, hintText: "e.g., abc-123-xyz"),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22D3EE), foregroundColor: Colors.black),
            child: const Text("Join"),
            onPressed: () {
              final code = codeCtrl.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _joinMeetingWithCode(code);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _joinMeetingWithCode(String meetingCode, {String? messageId}) async {
    if (AgoraConfig.appId == 'YOUR_AGORA_APP_ID_HERE') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configure Agora App ID'), backgroundColor: Colors.orange));
      return;
    }
    final permissions = await [Permission.camera, Permission.microphone].request();
    if (!permissions[Permission.camera]!.isGranted || !permissions[Permission.microphone]!.isGranted) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions required')));
      return;
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallPage(
            channelName: meetingCode,
            classCode: widget.classCode,
            groupId: widget.groupId,
            groupName: "Meeting: $meetingCode",
            messageId: messageId,
          ),
        ),
      );
    }
  }

  // --- Chat Logic ---
  void _onTextChanged() {
    final text = _msgController.text;
    final cursorPosition = _msgController.selection.baseOffset;
    if (cursorPosition < 0) return;
    int atIndex = -1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atIndex = i;
        break;
      }
      if (text[i] == ' ') break;
    }
    if (atIndex >= 0) {
      final mentionQuery = text.substring(atIndex + 1, cursorPosition).toLowerCase();
      final hasMatch = _mentionsList.any((m) => m.startsWith(mentionQuery));
      setState(() {
        _showMentionSuggestions = hasMatch;
        _currentMentionQuery = mentionQuery;
      });
    } else {
      if (_showMentionSuggestions) setState(() => _showMentionSuggestions = false);
    }
  }
  
  void _insertMention(String mention) {
    final text = _msgController.text;
    final cursorPosition = _msgController.selection.baseOffset;
    int atIndex = -1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atIndex = i;
        break;
      }
      if (text[i] == ' ') break;
    }
    if (atIndex >= 0) {
      final newText = text.substring(0, atIndex) + '@$mention ' + text.substring(cursorPosition);
      _msgController.text = newText;
      _msgController.selection = TextSelection.fromPosition(TextPosition(offset: atIndex + mention.length + 2));
    }
    setState(() => _showMentionSuggestions = false);
  }

  Future<void> _sendMessage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final text = _msgController.text.trim();
    if (text.isEmpty && _selectedFile == null) return;

    setState(() => _isUploading = true);

    try {
      String? fileUrl;
      if (_selectedFile != null) {
        final fileName = _selectedFileName ?? 'file';
        final ref = FirebaseStorage.instance
            .ref().child('chat_uploads').child(widget.classCode).child(widget.groupId)
            .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');
        await ref.putFile(_selectedFile!);
        fileUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('classes').doc(widget.classCode)
          .collection('groups').doc(widget.groupId)
          .collection('messages').add({
        'text': text,
        'senderId': uid,
        'senderName': _currentUserName, // Add sender name
        'createdAt': FieldValue.serverTimestamp(),
        'deletedBy': [],
        if (fileUrl != null) ...{
          'fileUrl': fileUrl,
          'fileType': _selectedFileType,
          'fileName': _selectedFileName,
        }
      });
      
      _msgController.clear();
      setState(() {
        _selectedFile = null; _selectedFileType = null; _selectedFileName = null; _isUploading = false;
      });
      
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _selectedFileType = 'image';
          _selectedFileName = pickedFile.name;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _selectedFileType = 'file';
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteMessage(String messageId, bool forMe) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final docRef = FirebaseFirestore.instance
          .collection('classes').doc(widget.classCode)
          .collection('groups').doc(widget.groupId)
          .collection('messages').doc(messageId);
      if (forMe) {
        await docRef.update({'deletedBy': FieldValue.arrayUnion([uid])});
      } else {
        await docRef.update({'isDeleted': true, 'fileUrl': FieldValue.delete(), 'fileName': FieldValue.delete()});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _GlassBottomSheet(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.image, color: Color(0xFF22D3EE)), title: const Text('Upload Image', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _pickImage(); }),
          ListTile(leading: const Icon(Icons.attach_file, color: Color(0xFFF59E0B)), title: const Text('Upload File', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _pickFile(); }),
        ]),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == now.year && date.month == now.month && date.day == now.day) return 'Today';
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatTime(DateTime date) => DateFormat('h:mm a').format(date);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Theme Colors
    final Color topColor = const Color(0xFF7C3AED).withValues(alpha: 0.15);
    final Color bottomColor = const Color(0xFFC026D3).withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupInfoPage(
                  classCode: widget.classCode,
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                ),
              ),
            );
          },
          child: Text(
            widget.groupName,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.video_call_rounded, color: Color(0xFF22D3EE)),
              tooltip: 'Meeting Options',
              onPressed: _showMeetingOptions,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Background Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, bottomColor],
              ),
            ),
          ),

          // 2. Ambient Glow Orbs
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2), // Violet
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.15), // Cyan
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // 3. Content
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('classes').doc(widget.classCode)
                      .collection('groups').doc(widget.groupId)
                      .collection('messages').orderBy('createdAt').snapshots(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final docs = snap.data?.docs ?? [];
                    if (docs.isEmpty) return Center(child: Text('No messages yet.', style: GoogleFonts.inter(color: Colors.white54)));

                    final List<_MessageItem> items = [];
                    String? lastDate;

                    for (final doc in docs) {
                      final data = doc.data();
                      final deletedBy = List<String>.from(data['deletedBy'] ?? []);
                      if (deletedBy.contains(uid)) continue;
                      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                      if (createdAt != null) {
                        final dateStr = DateFormat('yyyy-MM-dd').format(createdAt);
                        if (lastDate != dateStr) {
                          items.add(_MessageItem.dateHeader(dateStr));
                          lastDate = dateStr;
                        }
                        items.add(_MessageItem.message(doc: doc, data: data, createdAt: createdAt, uid: uid));
                      }
                    }

                    // Scroll to bottom after first frame (only once)
                    if (!_hasScrolledToBottom) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollCtrl.hasClients && mounted) {
                          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                          setState(() => _hasScrolledToBottom = true);
                        }
                      });
                    }

                    return ListView.builder(
                      reverse: true,
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[items.length - 1 - index];
                        if (item.isDateHeader) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(children: [
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                              Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(_formatDate(DateFormat('yyyy-MM-dd').parse(item.dateStr!)), style: TextStyle(color: Colors.white54, fontSize: 12))),
                              Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                            ]),
                          );
                        }
                        
                        // Resolve Sender Name
                        String displaySenderName = item.senderName ?? 'User';
                        if ((displaySenderName == 'User' || displaySenderName.isEmpty) && item.senderId != null) {
                           if (_senderNameCache.containsKey(item.senderId)) {
                             displaySenderName = _senderNameCache[item.senderId]!;
                           } else {
                             _fetchSenderName(item.senderId!);
                           }
                        }

                        return _MessageBubble(
                          key: ValueKey(item.messageId), text: item.text!, senderId: item.senderId!,
                          senderName: displaySenderName, // Use resolved name
                          createdAt: item.createdAt, isMe: uid == item.senderId,
                          formatTime: _formatTime, fileUrl: item.fileUrl, fileType: item.fileType,
                          fileName: item.fileName, messageId: item.messageId!, onDelete: _deleteMessage, isDeleted: item.isDeleted,
                          type: item.type, meetingCode: item.meetingCode, participants: item.participants,
                          onJoinMeeting: (code, msgId) => _joinMeetingWithCode(code, messageId: msgId),
                          status: item.status,
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                  child: Column(children: [
                    if (_selectedFile != null) _FilePreview(fileName: _selectedFileName, fileType: _selectedFileType, file: _selectedFile!, onRemove: () => setState(() => _selectedFile = null)),
                    if (_showMentionSuggestions) _MentionSuggestions(mentionsList: _mentionsList, query: _currentMentionQuery, onSelect: _insertMention),
                    _ChatInput(controller: _msgController, isUploading: _isUploading, onAttach: _showAttachmentOptions, onSend: _sendMessage),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- HELPERS ---

class _MessageItem {
  _MessageItem.dateHeader(this.dateStr) : isDateHeader = true, text = null, senderId = null, senderName = null, createdAt = null, fileUrl = null, fileType = null, fileName = null, messageId = null, isDeleted = false, type = null, meetingCode = null, participants = const [], status = 'active';
  _MessageItem.message({required DocumentSnapshot doc, required Map<String, dynamic> data, required DateTime createdAt, required String? uid}) : isDateHeader = false, dateStr = null, text = data['text'] as String? ?? '', senderId = data['senderId'] as String? ?? '', senderName = data['senderName'] as String? ?? 'User', createdAt = createdAt, fileUrl = data['fileUrl'] as String?, fileType = data['fileType'] as String?, fileName = data['fileName'] as String?, messageId = doc.id, isDeleted = data['isDeleted'] as bool? ?? false, type = data['type'] as String?, meetingCode = data['meetingCode'] as String?, participants = List<String>.from(data['participants'] ?? []), status = data['status'] as String? ?? 'active';
  final bool isDateHeader; final String? dateStr; final String? text; final String? senderId; final String? senderName; final DateTime? createdAt; final String? fileUrl; final String? fileType; final String? fileName; final String? messageId; final bool isDeleted; final String? type; final String? meetingCode; final List<String> participants; final String status;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key, required this.text, required this.senderId, required this.senderName,
    required this.createdAt, required this.isMe, required this.formatTime,
    this.fileUrl, this.fileType, this.fileName, required this.messageId,
    required this.onDelete, required this.isDeleted,
    this.type, this.meetingCode, this.participants = const [], this.onJoinMeeting, this.status = 'active',
  });

  final String text; final String senderId; final String senderName; final DateTime? createdAt;
  final bool isMe; final String Function(DateTime) formatTime; final String? fileUrl;
  final String? fileType; final String? fileName; final String messageId;
  final Function(String, bool) onDelete; final bool isDeleted;
  final String? type; final String? meetingCode; final List<String> participants;
  final Function(String, String)? onJoinMeeting; final String status;

  void _showOptions(BuildContext context) {
    if (isDeleted) return;
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => _GlassBottomSheet(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (fileUrl != null && fileType == 'image') ListTile(leading: const Icon(Icons.download, color: Colors.white), title: const Text('Save to Gallery', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); _saveImage(context); }),
        ListTile(leading: const Icon(Icons.delete_outline, color: Colors.white), title: const Text('Delete for Me', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); onDelete(messageId, true); }),
        if (isMe) ListTile(leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text('Delete for Everyone', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(context); onDelete(messageId, false); }),
      ]),
    ));
  }

  Future<void> _saveImage(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(fileUrl!));
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/temp.jpg').writeAsBytes(response.bodyBytes);
      await Gal.putImage(file.path);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved!')));
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
  }

  Future<void> _downloadAndOpenFile(BuildContext context) async {
    if (fileUrl == null || fileName == null) return;
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      // Download the file
      final response = await http.get(Uri.parse(fileUrl!));
      
      // Get the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      
      // Write the file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Open the file with external app
      final result = await OpenFile.open(filePath);
      
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${result.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAI = senderId == 'gemini_ai';
    
    // Bubble Color Logic
    final bubbleDecoration = isMe
        ? BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF6366F1)]), // Violet to Indigo
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(4)),
          )
        : BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1), // Glass
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20), bottomLeft: Radius.circular(4), bottomRight: Radius.circular(20)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        if (!isMe) Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 4),
          child: Text(isAI ? 'Gemini AI' : senderName, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ),
        GestureDetector(
          onLongPress: () => _showOptions(context),
          onTap: (fileType == 'file' && fileUrl != null) ? () => _downloadAndOpenFile(context) : null,
          child: Container(
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: type == 'meeting' ? null : bubbleDecoration,
            child: type == 'meeting' 
                ? _MeetingCard(
                    meetingCode: meetingCode ?? '',
                    participantCount: participants.length,
                    onJoin: () => onJoinMeeting?.call(meetingCode ?? '', messageId),
                    isMe: isMe,
                    status: status ?? 'active',
                  )
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (fileUrl != null) ...[
                if (fileType == 'image') 
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _FullScreenImageViewer(imageUrl: fileUrl!),
                        ),
                      );
                    },
                    child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(fileUrl!)),
                  )
                else if (fileType == 'file')
                  // WhatsApp-style file display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.insert_drive_file, color: Color(0xFFF59E0B), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName ?? 'Document',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Tap to open',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (fileType == 'image' || text.isNotEmpty) const SizedBox(height: 8),
              ],
              if (text.isNotEmpty)
                Text(isDeleted ? 'Deleted message' : text, style: TextStyle(color: Colors.white.withValues(alpha: isDeleted ? 0.5 : 1.0), fontSize: 15, fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal)),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, top: 4),
          child: Text(createdAt != null ? formatTime(createdAt!) : '', style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ),
      ]),
    );
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({required this.fileName, required this.fileType, required this.file, required this.onRemove});
  final String? fileName; final String? fileType; final File file; final VoidCallback onRemove;
  @override
  Widget build(BuildContext context) {
    return _GlassContainer(
      padding: const EdgeInsets.all(8), 
      child: Row(children: [
        if (fileType == 'image') ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(file, width: 50, height: 50, fit: BoxFit.cover))
        else const Icon(Icons.insert_drive_file, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(child: Text(fileName ?? 'File', overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white))),
        IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: onRemove),
      ]),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({required this.controller, required this.isUploading, required this.onAttach, required this.onSend});
  final TextEditingController controller; final bool isUploading; final VoidCallback onAttach; final VoidCallback onSend;
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white70), onPressed: onAttach),
      Expanded(child: _GlassTextField(controller: controller, hintText: 'Message...')),
      const SizedBox(width: 8),
      Container(
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF22D3EE)), // Cyan Send Button
        child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20), onPressed: isUploading ? null : onSend),
      ),
    ]);
  }
}

class _MentionSuggestions extends StatelessWidget {
  const _MentionSuggestions({required this.mentionsList, required this.query, required this.onSelect});
  final List<String> mentionsList; final String query; final Function(String) onSelect;
  @override
  Widget build(BuildContext context) {
    final filtered = mentionsList.where((m) => m.startsWith(query)).toList();
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: _GlassContainer(
        padding: EdgeInsets.zero,
        child: Column(mainAxisSize: MainAxisSize.min, children: filtered.map((m) => ListTile(title: Text('@$m', style: const TextStyle(color: Colors.white)), onTap: () => onSelect(m))).toList()),
      ),
    );
  }
}

// --- Reusable Glass Components ---

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const _GlassContainer({required this.child, this.padding});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  const _GlassTextField({required this.controller, required this.hintText});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              isDense: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassBottomSheet extends StatelessWidget {
  final Widget child;
  const _GlassBottomSheet({required this.child});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F1A).withValues(alpha: 0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  const _GlassDialog({required this.title, required this.content, required this.actions});
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: const Color(0xFF0F0F1A).withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: content,
        actions: actions,
      ),
    );
  }
}

// Full Screen Image Viewer
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image with pinch to zoom
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 48),
                ),
              ),
            ),
          ),
          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({
    required this.meetingCode,
    required this.participantCount,
    required this.onJoin,
    required this.isMe,
    required this.status,
  });

  final String meetingCode;
  final int participantCount;
  final VoidCallback onJoin;
  final bool isMe;
  final String status;

  @override
  Widget build(BuildContext context) {
    final bool isEnded = status == 'ended';
    final Color baseColor = isEnded ? Colors.grey : (isMe ? const Color(0xFF7C3AED) : Colors.white);
    
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEnded ? Colors.white.withValues(alpha: 0.05) : (isMe ? const Color(0xFF7C3AED).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.videocam_rounded, color: isEnded ? Colors.white54 : Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEnded ? 'Meeting Ended' : 'Video Meeting', style: TextStyle(color: isEnded ? Colors.white54 : Colors.white, fontWeight: FontWeight.bold)),
                  if (!isEnded) Text(meetingCode, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isEnded ? 'This meeting has ended' : '$participantCount active participant${participantCount == 1 ? '' : 's'}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
          ),
          if (!isEnded) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7C3AED),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onJoin,
                child: const Text('Join'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
