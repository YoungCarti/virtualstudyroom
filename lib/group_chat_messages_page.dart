import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    if (text.isEmpty) return;

    try {
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
      });
      _msgController.clear();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
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
                        text: item.text!,
                        senderId: item.senderId!,
                        createdAt: item.createdAt,
                        isMe: uid == item.senderId,
                        isDark: isDark,
                        formatTime: _formatTime,
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
              child: Row(
                children: [
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
                      onPressed: _sendMessage,
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        backgroundColor: const Color(0xFF6C63FF),
                        padding: EdgeInsets.zero,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
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
        createdAt = null;

  _MessageItem.message({
    required DocumentSnapshot doc,
    required Map<String, dynamic> data,
    required DateTime createdAt,
    required String? uid,
  })  : isDateHeader = false,
        dateStr = null,
        text = data['text'] as String? ?? '',
        senderId = data['senderId'] as String? ?? '',
        createdAt = createdAt;

  final bool isDateHeader;
  final String? dateStr;
  final String? text;
  final String? senderId;
  final DateTime? createdAt;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.senderId,
    required this.createdAt,
    required this.isMe,
    required this.isDark,
    required this.formatTime,
  });

  final String text;
  final String senderId;
  final DateTime? createdAt;
  final bool isMe;
  final bool isDark;
  final String Function(DateTime) formatTime;

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
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF1F1F33)),
                      fontSize: 15,
                    ),
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