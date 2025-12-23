import 'dart:ui';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';

class GroupInfoPage extends StatefulWidget {
  const GroupInfoPage({
    super.key,
    required this.classCode,
    required this.groupId,
    required this.groupName,
  });

  final String classCode;
  final String groupId;
  final String groupName;

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  String _selectedTab = 'Media';

  Future<void> _leaveGroup() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _GlassDialog(
        title: 'Leave Group',
        content: Text(
          'Are you sure you want to leave "${widget.groupName}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classCode)
          .collection('groups')
          .doc(widget.groupId)
          .update({
        'members': FieldValue.arrayRemove([uid]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You left the group')),
        );
        // Pop twice: once for this page, once for the chat messages page
        Navigator.pop(context);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving group: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color topColor = const Color(0xFF7C3AED).withValues(alpha: 0.15);
    final Color bottomColor = const Color(0xFFC026D3).withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, bottomColor],
              ),
            ),
          ),

          // Ambient Glow Orbs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GlassIconButton(
                        icon: Icons.chevron_left,
                        onTap: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.groupName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // Tab Selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: _GlassContainer(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabButton(
                            label: 'Media',
                            isSelected: _selectedTab == 'Media',
                            onTap: () => setState(() => _selectedTab = 'Media'),
                          ),
                        ),
                        Expanded(
                          child: _TabButton(
                            label: 'Links',
                            isSelected: _selectedTab == 'Links',
                            onTap: () => setState(() => _selectedTab = 'Links'),
                          ),
                        ),
                        Expanded(
                          child: _TabButton(
                            label: 'Docs',
                            isSelected: _selectedTab == 'Docs',
                            onTap: () => setState(() => _selectedTab = 'Docs'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _selectedTab == 'Media'
                        ? _MediaSection(classCode: widget.classCode, groupId: widget.groupId)
                        : _selectedTab == 'Links'
                            ? _LinksSection(classCode: widget.classCode, groupId: widget.groupId)
                            : _DocsSection(classCode: widget.classCode, groupId: widget.groupId),
                  ),
                ),

                // Leave Group Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _leaveGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.15),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                        ),
                      ),
                      icon: const Icon(Icons.exit_to_app),
                      label: Text(
                        'Leave Group',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- SECTIONS ---

class _MediaSection extends StatelessWidget {
  const _MediaSection({required this.classCode, required this.groupId});

  final String classCode;
  final String groupId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classCode)
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .where('fileType', isEqualTo: 'image')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final uid = FirebaseAuth.instance.currentUser?.uid;
        final allDocs = snapshot.data?.docs ?? [];
        
        // Filter out deleted messages
        final docs = allDocs.where((doc) {
          final data = doc.data();
          final isDeleted = data['isDeleted'] as bool? ?? false;
          final deletedBy = List<String>.from(data['deletedBy'] ?? []);
          return !isDeleted && (uid == null || !deletedBy.contains(uid));
        }).toList();
        
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No media shared yet',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          );
        }

        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final imageUrl = data['fileUrl'] as String?;

            return GestureDetector(
              onTap: imageUrl != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _FullScreenImageViewer(imageUrl: imageUrl),
                        ),
                      );
                    }
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white.withValues(alpha: 0.1),
                          child: const Icon(Icons.broken_image, color: Colors.white54),
                        ),
                      )
                    : Container(
                        color: Colors.white.withValues(alpha: 0.1),
                        child: const Icon(Icons.image, color: Colors.white54),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LinksSection extends StatelessWidget {
  const _LinksSection({required this.classCode, required this.groupId});

  final String classCode;
  final String groupId;

  bool _containsUrl(String text) {
    final urlPattern = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(text);
  }

  List<String> _extractUrls(String text) {
    final urlPattern = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );
    return urlPattern.allMatches(text).map((m) => m.group(0)!).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classCode)
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final uid = FirebaseAuth.instance.currentUser?.uid;
        final allDocs = snapshot.data?.docs ?? [];
        
        // Filter out deleted messages and messages with links
        final messagesWithLinks = allDocs.where((doc) {
          final data = doc.data();
          final isDeleted = data['isDeleted'] as bool? ?? false;
          final deletedBy = List<String>.from(data['deletedBy'] ?? []);
          final text = data['text'] as String? ?? '';
          return !isDeleted && (uid == null || !deletedBy.contains(uid)) && _containsUrl(text);
        }).toList();

        if (messagesWithLinks.isEmpty) {
          return Center(
            child: Text(
              'No links shared yet',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          );
        }

        return ListView.separated(
          itemCount: messagesWithLinks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = messagesWithLinks[index].data();
            final text = data['text'] as String? ?? '';
            final urls = _extractUrls(text);

            return _GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22D3EE).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.link, color: Color(0xFF22D3EE), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          urls.first,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF22D3EE),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (text.replaceAll(RegExp(r'https?:\/\/[^\s]+'), '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      text,
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DocsSection extends StatelessWidget {
  const _DocsSection({required this.classCode, required this.groupId});

  final String classCode;
  final String groupId;

  Future<void> _downloadAndOpenFile(BuildContext context, String fileUrl, String fileName) async {
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
      final response = await http.get(Uri.parse(fileUrl));
      
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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classCode)
          .collection('groups')
          .doc(groupId)
          .collection('messages')
          .where('fileType', isEqualTo: 'file')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final uid = FirebaseAuth.instance.currentUser?.uid;
        final allDocs = snapshot.data?.docs ?? [];
        
        // Filter out deleted messages
        final docs = allDocs.where((doc) {
          final data = doc.data();
          final isDeleted = data['isDeleted'] as bool? ?? false;
          final deletedBy = List<String>.from(data['deletedBy'] ?? []);
          return !isDeleted && (uid == null || !deletedBy.contains(uid));
        }).toList();
        
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No documents shared yet',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final fileName = data['fileName'] as String? ?? 'Untitled';
            final fileUrl = data['fileUrl'] as String?;

            return GestureDetector(
              onTap: fileUrl != null 
                  ? () => _downloadAndOpenFile(context, fileUrl, fileName)
                  : null,
              child: _GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.insert_drive_file, color: Color(0xFFF59E0B)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fileUrl != null ? 'Tap to open' : 'File',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (fileUrl != null)
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 16,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// --- WIDGETS ---

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

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

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const _GlassDialog({
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: AlertDialog(
        backgroundColor: const Color(0xFF0F0F1A).withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
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
