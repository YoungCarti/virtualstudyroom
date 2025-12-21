import 'dart:io';
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
import 'widgets/gradient_background.dart';

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
  String? _selectedFileType; // 'image' or 'file'
  String? _selectedFileName;
  bool _isUploading = false;

  @override
  void dispose() {
    _msgController.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    
    final text = _msgController.text.trim();
    if (text.isEmpty && _selectedFile == null) return;

    setState(() => _isUploading = true);

    try {
      String? fileUrl;
      
      // Upload file if selected
      if (_selectedFile != null) {
        final fileName = _selectedFileName ?? 'file';
        final ref = FirebaseStorage.instance
            .ref()
            .child('chat_uploads')
            .child(widget.classCode)
            .child(widget.groupId)
            .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

        await ref.putFile(_selectedFile!);
        fileUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classCode)
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': uid,
        'createdAt': FieldValue.serverTimestamp(),
        if (fileUrl != null) ...{
          'fileUrl': fileUrl,
          'fileType': _selectedFileType,
          'fileName': _selectedFileName,
        }
      });
      
      _msgController.clear();
      setState(() {
        _selectedFile = null;
        _selectedFileType = null;
        _selectedFileName = null;
        _isUploading = false;
      });
      
      // Scroll to bottom
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }
  Future<void> _deleteMessage(String messageId, bool forMe) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final docRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classCode)
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .doc(messageId);

      if (forMe) {
        // Add user ID to deletedBy array
        await docRef.update({
          'deletedBy': FieldValue.arrayUnion([uid]),
        });
      } else {
        // Delete document completely
        await docRef.delete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }


  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Upload Image'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.orange),
              title: const Text('Upload File'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.groupName),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classCode)
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Start the conversation!'),
                  );
                }

                // Build list with date separators
                final List<_MessageItem> items = [];
                String? lastDate;

                for (final doc in docs) {
                  final data = doc.data();
                  
                  // Check if deleted by me
                  final deletedBy = List<String>.from(data['deletedBy'] ?? []);
                  if (deletedBy.contains(uid)) continue;

                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                  
                  if (createdAt != null) {
                    final dateStr = DateFormat('yyyy-MM-dd').format(createdAt);
                    
                    // Add date separator if date changed
                    if (lastDate != dateStr) {
                      items.add(_MessageItem.dateHeader(dateStr));
                      lastDate = dateStr;
                    }
                    
                    // Add message
                    items.add(_MessageItem.message(
                      doc: doc,
                      data: data,
                      createdAt: createdAt,
                      uid: uid,
                    ));
                  }
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    
                    if (item.isDateHeader) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                _formatDate(DateFormat('yyyy-MM-dd').parse(item.dateStr!)),
                                style: TextStyle(
                                  color: isDark ? Colors.white60 : Colors.black54,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return _MessageBubble(
                        key: ValueKey(item.messageId),
                        text: item.text!,
                        senderId: item.senderId!,
                        createdAt: item.createdAt,
                        isMe: uid == item.senderId,
                        isDark: isDark,
                        formatTime: _formatTime,
                        fileUrl: item.fileUrl,
                        fileType: item.fileType,
                        fileName: item.fileName,
                        messageId: item.messageId!,
                        onDelete: _deleteMessage,
                      );
                    }
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Column(
                children: [
                  if (_selectedFile != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A3E) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_selectedFileType == 'image')
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedFile!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.insert_drive_file,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFileName ?? 'File',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Tap send to upload',
                                  style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _selectedFile = null;
                                _selectedFileType = null;
                                _selectedFileName = null;
                              });
                            },
                            icon: const Icon(Icons.close),
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _showAttachmentOptions,
                        icon: const Icon(Icons.add_circle_outline),
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          minLines: 1,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Message',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF2A2A3E) : Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _sendMessage,
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            backgroundColor: const Color(0xFF6C63FF),
                            padding: EdgeInsets.zero,
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, color: Colors.white),
                        ),
                      ),
                    ],
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
}

class _MessageItem {
  _MessageItem.dateHeader(this.dateStr)
      : isDateHeader = true,
        text = null,
        senderId = null,
        createdAt = null,
        fileUrl = null,
        fileType = null,
        fileName = null,
        messageId = null;

  _MessageItem.message({
    required DocumentSnapshot doc,
    required Map<String, dynamic> data,
    required DateTime createdAt,
    required String? uid,
  })  : isDateHeader = false,
        dateStr = null,
        text = data['text'] as String? ?? '',
        senderId = data['senderId'] as String? ?? '',
        createdAt = createdAt,
        fileUrl = data['fileUrl'] as String?,
        fileType = data['fileType'] as String?,
        fileName = data['fileName'] as String?,
        messageId = doc.id;

  final bool isDateHeader;
  final String? dateStr;
  final String? text;
  final String? senderId;
  final DateTime? createdAt;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;
  final String? messageId;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.text,
    required this.senderId,
    required this.createdAt,
    required this.isMe,
    required this.isDark,
    required this.formatTime,
    this.fileUrl,
    this.fileType,
    this.fileName,
    required this.messageId,
    required this.onDelete,
  });

  final String text;
  final String senderId;
  final DateTime? createdAt;
  final bool isMe;
  final bool isDark;
  final String Function(DateTime) formatTime;
  final String? fileUrl;
  final String? fileType;
  final String? fileName;
  final String messageId;
  final Function(String, bool) onDelete;

  Future<void> _downloadImage(BuildContext context, String url) async {
    print('Starting download for: $url');
    try {
      // Request access permission
      final hasAccess = await Gal.hasAccess();
      print('Has access: $hasAccess');
      if (!hasAccess) {
        final granted = await Gal.requestAccess();
        print('Access granted: $granted');
        if (!granted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permission denied')),
            );
          }
          return;
        }
      }

      print('Downloading file...');
      final response = await http.get(Uri.parse(url));
      print('Download status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Get temp directory
        final tempDir = await getTemporaryDirectory();
        final fileName = 'chat_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${tempDir.path}/$fileName');
        
        // Write to temp file
        await file.writeAsBytes(response.bodyBytes);
        print('File written to: ${file.path}');
        
        // Save to gallery using Gal
        print('Saving to gallery...');
        await Gal.putImage(file.path, album: 'Study Link');
        print('Saved to gallery');
        
        if (context.mounted) {
          print('Context is mounted, showing snackbar');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image saved to Study Link album')),
          );
        } else {
          print('Context is NOT mounted');
        }
      } else {
        print('Failed to download: ${response.statusCode}');
      }
    } catch (e, stack) {
      print('Error downloading image: $e');
      print(stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading image: $e')),
        );
      }
    }
  }

  void _showImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download Image'),
              onTap: () {
                Navigator.pop(context);
                if (fileUrl != null) {
                  _downloadImage(context, fileUrl!);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete for Me'),
              onTap: () {
                Navigator.pop(context);
                onDelete(messageId, true);
              },
            ),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete for Everyone', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete(messageId, false);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(senderId).get(),
      builder: (context, snap) {
        final userName = snap.data?.data()?['fullName'] ??
            snap.data?.data()?['name'] ??
            'Unknown';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    userName,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFF6C63FF)
                        : (isDark ? const Color(0xFF2A2A3E) : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fileUrl != null) ...[
                        if (fileType == 'image')
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: EdgeInsets.zero,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      InteractiveViewer(
                                        child: Image.network(fileUrl!),
                                      ),
                                      Positioned(
                                        top: 40,
                                        right: 20,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                          onPressed: () => Navigator.pop(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            onLongPress: () => _showImageOptions(context),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                fileUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const SizedBox(
                                    height: 150,
                                    width: double.infinity,
                                    child: Center(child: CircularProgressIndicator()),
                                  );
                                },
                              ),
                            ),
                          )
                        else
                          InkWell(
                            onTap: () {
                              // TODO: Implement file download/open
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Downloading file...')),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.insert_drive_file,
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    fileName ?? 'File',
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      decoration: TextDecoration.underline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (text.isNotEmpty && text != 'Sent an image' && text != 'Sent a file')
                          const SizedBox(height: 8),
                      ],
                      if (text.isNotEmpty && (fileUrl == null || (text != 'Sent an image' && text != 'Sent a file')))
                        Text(
                          text,
                          style: TextStyle(
                            color: isMe
                                ? Colors.white
                                : (isDark ? Colors.white : const Color(0xFF1F1F33)),
                            fontSize: 15,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Text(
                  createdAt != null ? formatTime(createdAt!) : '',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}