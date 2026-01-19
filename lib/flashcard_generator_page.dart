import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/share_dialogs.dart';

// Color Palette
const Color _deepNavy = Color(0xFF0A1929);
const Color _midnightBlue = Color(0xFF122A46);
const Color _electricBlue = Color(0xFF2196F3);
const Color _purpleAccent = Color(0xFF9B59B6);
const Color _mintGreen = Color(0xFF4ECDC4);
const Color _pureWhite = Color(0xFFFFFFFF);

class FlashcardGeneratorPage extends StatefulWidget {
  const FlashcardGeneratorPage({super.key, this.initialOutline});

  final String? initialOutline;

  @override
  State<FlashcardGeneratorPage> createState() => _FlashcardGeneratorPageState();
}

class _FlashcardGeneratorPageState extends State<FlashcardGeneratorPage> {
  final TextEditingController _notesController = TextEditingController();
  final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    if (widget.initialOutline != null) {
      _notesController.text = widget.initialOutline!;
      // Auto-trigger generation after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateFlashcards(autoStart: true);
      });
    }
  }
  
  // Attachments
  List<File> _attachedImages = [];
  List<Map<String, dynamic>> _attachedFiles = [];
  
  // Generated flashcards
  List<Map<String, String>> _flashcards = [];
  bool _isGenerating = false;
  bool _showEditor = false;  // Show editing screen after generation
  bool _showViewer = false;  // Show study mode

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _generateFlashcards({bool autoStart = false}) async {
    final content = _notesController.text.trim();
    
    if (content.isEmpty && _attachedImages.isEmpty && _attachedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please add some study materials first.', style: GoogleFonts.outfit()),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    
    setState(() => _isGenerating = true);
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Build material description
      final hasText = content.isNotEmpty;
      final hasImages = _attachedImages.isNotEmpty;
      final hasDocuments = _attachedFiles.isNotEmpty;
      
      String materialDescription;
      if (hasText && hasDocuments) {
        materialDescription = 'Use the provided text notes AND the attached documents.';
      } else if (hasDocuments) {
        materialDescription = 'Generate flashcards based on the attached documents.';
      } else if (hasImages && hasText) {
        materialDescription = 'Study Notes:\n$content';
      } else if (hasImages) {
        materialDescription = 'Generate flashcards from the attached images.';
      } else {
        materialDescription = 'Study Notes:\n$content';
      }
      
      final prompt = '''
Create flashcards for studying and memorization based on the following materials.
Generate 10-20 flashcards covering the key concepts, terms, and definitions.

Each flashcard should have:
- "front": A question, term, or concept
- "back": The answer, definition, or explanation

IMPORTANT:
- Make flashcards that are great for memorization
- Cover all important topics
- Keep answers concise but complete
- Seed: $timestamp

Return ONLY a valid JSON array. Do not include any other text.
Format:
[
  {"front": "What is photosynthesis?", "back": "The process by which plants convert sunlight, water, and CO2 into glucose and oxygen"},
  {"front": "Define osmosis", "back": "The movement of water molecules through a semi-permeable membrane from low to high solute concentration"}
]

$materialDescription
''';

      // Build parts list
      List<Map<String, dynamic>> parts = [
        {'text': prompt}
      ];
      
      // Add attached images
      for (final imageFile in _attachedImages) {
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);
        parts.add({
          'inlineData': {
            'mimeType': 'image/jpeg',
            'data': base64Image
          }
        });
      }
      
      // Add attached documents
      for (final fileData in _attachedFiles) {
        final file = fileData['file'] as File;
        final extension = fileData['extension'] as String;
        final bytes = await file.readAsBytes();
        final base64Data = base64Encode(bytes);
        
        String mimeType;
        if (extension == 'pdf') {
          mimeType = 'application/pdf';
        } else if (extension == 'docx') {
          mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        } else if (extension == 'doc') {
          mimeType = 'application/msword';
        } else {
          continue;
        }
        
        parts.add({
          'inlineData': {
            'mimeType': mimeType,
            'data': base64Data
          }
        });
      }

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {'parts': parts}
          ],
          'generationConfig': {
            'temperature': 0.8,
            'topP': 0.95,
            'topK': 40,
          }
        }),
      );

      setState(() => _isGenerating = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentText = data['candidates'][0]['content']['parts'][0]['text'];
        
        final jsonString = contentText.replaceAll('```json', '').replaceAll('```', '').trim();
        final List<dynamic> parsed = jsonDecode(jsonString);
        
        setState(() {
          _flashcards = parsed.map<Map<String, String>>((item) => {
            'front': item['front']?.toString() ?? '',
            'back': item['back']?.toString() ?? '',
          }).toList();
          if (autoStart) {
            _showViewer = true;
            _showEditor = false;
          } else {
            _showEditor = true;  // Show editor first, not viewer
          }
          _attachedImages.clear();
          _attachedFiles.clear();
        });
      } else {
        throw Exception('API Error: ${response.body}');
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating flashcards: $e')),
        );
      }
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _midnightBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _pureWhite.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _electricBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.insert_drive_file, color: _electricBlue),
              ),
              title: Text('Upload File', style: GoogleFonts.outfit(color: _pureWhite, fontWeight: FontWeight.w600)),
              subtitle: Text('PDF, DOC, DOCX files', style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.5), fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _purpleAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.image, color: _purpleAccent),
              ),
              title: Text('Upload Image', style: GoogleFonts.outfit(color: _pureWhite, fontWeight: FontWeight.w600)),
              subtitle: Text('Photos of notes', style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.5), fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final extension = result.files.single.extension?.toLowerCase() ?? '';
        
        setState(() {
          _attachedFiles.add({
            'file': file,
            'name': fileName,
            'extension': extension,
          });
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Document attached!', style: GoogleFonts.outfit()),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error attaching file: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _attachedImages.add(File(image.path));
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Image attached!', style: GoogleFonts.outfit()),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error attaching image: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show study viewer
    if (_showViewer && _flashcards.isNotEmpty) {
      return FlashcardViewer(
        flashcards: _flashcards,
        onBack: () => setState(() {
          _showViewer = false;
          _showEditor = true;  // Go back to editor, not main page
        }),
      );
    }
    
    // Show editor after generation
    if (_showEditor && _flashcards.isNotEmpty) {
      return _FlashcardEditor(
        flashcards: _flashcards,
        onUpdate: (updated) => setState(() => _flashcards = updated),
        onStart: () => setState(() {
          _showEditor = false;
          _showViewer = true;
        }),
        onBack: () => setState(() {
          _showEditor = false;
          _flashcards.clear();
        }),
      );
    }
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _deepNavy,
        appBar: AppBar(
          title: Text('Flashcard Generator', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: _pureWhite,
          bottom: TabBar(
            indicatorColor: _purpleAccent,
            labelColor: _purpleAccent,
            unselectedLabelColor: _pureWhite.withOpacity(0.5),
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "Create"),
              Tab(text: "My Library"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCreateTab(),
            _buildLibraryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create flashcards from your notes',
              style: GoogleFonts.outfit(fontSize: 16, color: _pureWhite.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            
            // Input Container
            Container(
              decoration: BoxDecoration(
                color: _midnightBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _pureWhite.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _notesController,
                    maxLines: (_attachedImages.isEmpty && _attachedFiles.isEmpty) ? 8 : 5,
                    style: GoogleFonts.outfit(color: _pureWhite, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Paste your notes here...",
                      hintStyle: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.4)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  
                  // Attached content
                  if (_attachedImages.isNotEmpty || _attachedFiles.isNotEmpty)
                    Container(
                      height: 90,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Images
                          ..._attachedImages.asMap().entries.map((entry) {
                            return _AttachmentThumbnail(
                              child: Image.file(entry.value, fit: BoxFit.cover),
                              onRemove: () => setState(() => _attachedImages.removeAt(entry.key)),
                            );
                          }),
                          // Files
                          ..._attachedFiles.asMap().entries.map((entry) {
                            final ext = entry.value['extension'] as String;
                            final name = entry.value['name'] as String;
                            return _AttachmentThumbnail(
                              child: _FileIcon(extension: ext, name: name),
                              onRemove: () => setState(() => _attachedFiles.removeAt(entry.key)),
                            );
                          }),
                        ],
                      ),
                    ),
                  
                  // Bottom row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _showUploadOptions,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _purpleAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.attach_file, color: _purpleAccent, size: 20),
                          ),
                        ),
                        Text(
                          '${_notesController.text.length}/100000',
                          style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.5), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Generate Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_notesController.text.trim().isEmpty && _attachedImages.isEmpty && _attachedFiles.isEmpty) || _isGenerating
                    ? null
                    : () => _generateFlashcards(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purpleAccent,
                  foregroundColor: _pureWhite,
                  disabledBackgroundColor: _purpleAccent.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isGenerating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _pureWhite)),
                          const SizedBox(width: 12),
                          Text('Creating flashcards...', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                        ],
                      )
                    : Text('Generate Flashcards', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text(
              'Saved Study Outlines',
              style: GoogleFonts.outfit(fontSize: 18, color: _pureWhite, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseAuth.instance.currentUser != null
                  ? FirebaseFirestore.instance
                      .collection('saved_outlines')
                      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                      .snapshots()
                  : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}', style: GoogleFonts.outfit(color: Colors.red));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _midnightBlue.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _pureWhite.withOpacity(0.1)),
                    ),
                    child: Center(
                      child: Text(
                        'No saved outlines found',
                        style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.5)),
                      ),
                    ),
                  );
                 }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Untitled';
                    final content = (data['outline'] ?? data['content'] ?? '') as String;
                    final date = (data['createdAt'] as Timestamp?)?.toDate();
                    final dateStr = date != null ? '${date.month}/${date.day}/${date.year}' : '';
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _notesController.text = content;
                          _attachedImages.clear();
                          _attachedFiles.clear();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Loaded "$title" into notes', style: GoogleFonts.outfit()),
                            backgroundColor: _purpleAccent,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _midnightBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _pureWhite.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _deepNavy,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.class_outlined, color: _purpleAccent),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.outfit(
                                      color: _pureWhite,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$dateStr • by you',
                                    style: GoogleFonts.outfit(
                                      color: _pureWhite.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.share, color: _pureWhite.withOpacity(0.5), size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                ShareHelper.shareContent(
                                  context: context,
                                  title: title,
                                  content: content,
                                  type: 'Flashcard Deck',
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.arrow_forward_ios, 
                              color: _pureWhite.withOpacity(0.3), 
                              size: 16
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      );
  }

  Widget _buildLibraryTab() {
     return StreamBuilder<QuerySnapshot>(
        stream: FirebaseAuth.instance.currentUser != null 
          ? FirebaseFirestore.instance
            .collection('generated_flashcards')
            .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .orderBy('createdAt', descending: true)
            .snapshots()
          : const Stream.empty(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}', style: GoogleFonts.outfit(color: Colors.red)));
          }
           final docs = snapshot.data?.docs ?? [];
           if (docs.isEmpty) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style_outlined, size: 60, color: _pureWhite.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No saved decks yet', style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.5))),
                  const SizedBox(height: 8),
                  Text('Generate flashcards and save them to see them here.', style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.3), fontSize: 12)),
                ],
              ));
           }
           return ListView.separated(
             padding: const EdgeInsets.all(20),
             itemCount: docs.length,
             separatorBuilder: (c, i) => const SizedBox(height: 12),
             itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final title = data['title'] ?? 'Untitled Deck';
                final count = (data['cards'] as List?)?.length ?? 0;
                final date = (data['createdAt'] as Timestamp?)?.toDate();
                final dateStr = date != null ? '${date.month}/${date.day}/${date.year}' : '';
                
                return GestureDetector(
                   onTap: () {
                      final cards = (data['cards'] as List).map<Map<String,String>>((e) => {
                         'front': e['front']?.toString() ?? '',
                         'back': e['back']?.toString() ?? '',
                      }).toList();
                      
                      setState(() {
                         _flashcards = cards;
                         _showViewer = true; // Auto open viewer
                         _showEditor = false;
                      });
                   },
                   child: Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                        color: _midnightBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _pureWhite.withOpacity(0.1)),
                     ),
                     child: Row(children: [
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _deepNavy, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.style, color: _mintGreen)),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                           Text(title, style: GoogleFonts.outfit(color: _pureWhite, fontWeight: FontWeight.bold, fontSize: 16)),
                           Text('$count cards • $dateStr', style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.5), fontSize: 12)),
                        ])),
                        const Icon(Icons.play_arrow_rounded, color: _mintGreen, size: 28),
                     ]),
                   ),
                );
             }
           );
        }
     );
  }
}

// Attachment Thumbnail Widget
class _AttachmentThumbnail extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;

  const _AttachmentThumbnail({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(height: 80, width: 80, child: child),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// File Icon Widget
class _FileIcon extends StatelessWidget {
  final String extension;
  final String name;

  const _FileIcon({required this.extension, required this.name});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    if (extension == 'pdf') {
      icon = Icons.picture_as_pdf;
      color = Colors.red.shade400;
    } else if (extension == 'doc' || extension == 'docx') {
      icon = Icons.description;
      color = Colors.blue.shade400;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.grey.shade400;
    }

    return Container(
      height: 80,
      width: 80,
      decoration: BoxDecoration(
        color: _deepNavy,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _pureWhite.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              name.length > 10 ? '${name.substring(0, 8)}...' : name,
              style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.7), fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// Flashcard Viewer with flip animation
class FlashcardViewer extends StatefulWidget {
  final List<Map<String, String>> flashcards;
  final VoidCallback onBack;

  const FlashcardViewer({super.key, required this.flashcards, required this.onBack});

  @override
  State<FlashcardViewer> createState() => _FlashcardViewerState();
}

class _FlashcardViewerState extends State<FlashcardViewer> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _showBack = false;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showBack = !_showBack);
  }

  void _nextCard() {
    if (_currentIndex < widget.flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _showBack = false;
        _flipController.reset();
      });
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showBack = false;
        _flipController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.flashcards[_currentIndex];
    
    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text('Flashcards', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _pureWhite,
      ),
      body: Column(
        children: [
          // Progress
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_currentIndex + 1} / ${widget.flashcards.length}',
                  style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.7), fontSize: 16),
                ),
              ],
            ),
          ),
          
          // Flashcard
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  _nextCard();
                } else if (details.primaryVelocity! > 0) {
                  _prevCard();
                }
              },
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * 3.14159;
                  final showFront = angle < 1.5708;
                  
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: showFront ? _midnightBlue : _purpleAccent.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _purpleAccent.withOpacity(0.5), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _purpleAccent.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..rotateY(showFront ? 0 : 3.14159),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                showFront ? Icons.help_outline : Icons.lightbulb_outline,
                                color: _purpleAccent,
                                size: 32,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                showFront ? 'QUESTION' : 'ANSWER',
                                style: GoogleFonts.outfit(
                                  color: _purpleAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                showFront ? card['front']! : card['back']!,
                                style: GoogleFonts.outfit(
                                  color: _pureWhite,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Hint
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Tap to flip • Swipe to navigate',
              style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.4), fontSize: 14),
            ),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: _currentIndex == widget.flashcards.length - 1 && _showBack
                // Show Finish button on last card after viewing answer
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text('Finish', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: _pureWhite,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: _currentIndex > 0 ? _prevCard : null,
                        icon: Icon(Icons.arrow_back_rounded, color: _currentIndex > 0 ? _pureWhite : _pureWhite.withOpacity(0.3)),
                        iconSize: 32,
                      ),
                      ElevatedButton(
                        onPressed: _flipCard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _purpleAccent,
                          foregroundColor: _pureWhite,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(_showBack ? 'Show Question' : 'Show Answer', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      ),
                      IconButton(
                        onPressed: _currentIndex < widget.flashcards.length - 1 ? _nextCard : null,
                        icon: Icon(Icons.arrow_forward_rounded, 
                          color: _currentIndex < widget.flashcards.length - 1 ? _pureWhite : _pureWhite.withOpacity(0.3)),
                        iconSize: 32,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// Flashcard Editor Widget
class _FlashcardEditor extends StatefulWidget {
  final List<Map<String, String>> flashcards;
  final Function(List<Map<String, String>>) onUpdate;
  final VoidCallback onStart;
  final VoidCallback onBack;

  const _FlashcardEditor({
    required this.flashcards,
    required this.onUpdate,
    required this.onStart,
    required this.onBack,
  });

  @override
  State<_FlashcardEditor> createState() => _FlashcardEditorState();
}

class _FlashcardEditorState extends State<_FlashcardEditor> {
  late List<Map<String, dynamic>> _editableCards;

  @override
  void initState() {
    super.initState();
    // Add unique ID to each card for Dismissible keys
    _editableCards = widget.flashcards.asMap().entries.map((entry) {
      return {
        'id': DateTime.now().millisecondsSinceEpoch.toString() + '_${entry.key}',
        'front': entry.value['front'] ?? '',
        'back': entry.value['back'] ?? '',
      };
    }).toList();
  }
  
  void _notifyUpdate() {
    // Convert back to format expected by parent
    final cleanList = _editableCards.map((e) => {
      'front': e['front'].toString(),
      'back': e['back'].toString(),
    }).toList();
    widget.onUpdate(cleanList);
  }

  void _deleteCard(int index) {
    if (_editableCards.length > 1) {
      setState(() {
        _editableCards.removeAt(index);
      });
      _notifyUpdate();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need at least one flashcard!', style: GoogleFonts.outfit()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void _editCard(int index) {
    final frontController = TextEditingController(text: _editableCards[index]['front']);
    final backController = TextEditingController(text: _editableCards[index]['back']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _midnightBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Flashcard', style: GoogleFonts.outfit(color: _pureWhite, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontController,
                maxLines: 3,
                style: GoogleFonts.outfit(color: _pureWhite),
                decoration: InputDecoration(
                  labelText: 'Question / Front',
                  labelStyle: GoogleFonts.outfit(color: _purpleAccent),
                  filled: true,
                  fillColor: _deepNavy,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: backController,
                maxLines: 3,
                style: GoogleFonts.outfit(color: _pureWhite),
                decoration: InputDecoration(
                  labelText: 'Answer / Back',
                  labelStyle: GoogleFonts.outfit(color: _purpleAccent),
                  filled: true,
                  fillColor: _deepNavy,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _editableCards[index]['front'] = frontController.text;
                _editableCards[index]['back'] = backController.text;
              });
              _notifyUpdate();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _purpleAccent),
            child: Text('Save', style: GoogleFonts.outfit(color: _pureWhite, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDeck() async {
    final titleController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _midnightBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Save Flashcard Deck', style: GoogleFonts.outfit(color: _pureWhite, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Give your study deck a name to save it to your library.', style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.7))),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              autofocus: true,
              style: GoogleFonts.outfit(color: _pureWhite),
              decoration: InputDecoration(
                labelText: 'Deck Title',
                labelStyle: GoogleFonts.outfit(color: _purpleAccent),
                filled: true,
                fillColor: _deepNavy,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isEmpty) return;
              
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              
              try {
                // Prepare cards
                final cleanCards = _editableCards.map((e) => {
                  'front': e['front'].toString(),
                  'back': e['back'].toString(),
                }).toList();
                
                await FirebaseFirestore.instance.collection('generated_flashcards').add({
                  'userId': user.uid,
                  'title': titleController.text.trim(),
                  'cards': cleanCards,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Deck saved to Library!', style: GoogleFonts.outfit()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _purpleAccent),
            child: Text('Save', style: GoogleFonts.outfit(color: _pureWhite)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: Text('Edit Flashcards', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _pureWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Deck',
            onPressed: _saveDeck,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Card count
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_editableCards.length} Flashcards',
                  style: GoogleFonts.outfit(color: _pureWhite, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Tap to edit, swipe to delete',
                  style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          
          // Cards list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _editableCards.length,
              itemBuilder: (context, index) {
                final card = _editableCards[index];
                return Dismissible(
                  key: Key(card['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteCard(index),
                  confirmDismiss: (_) async => _editableCards.length > 1,
                  child: GestureDetector(
                    onTap: () => _editCard(index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _midnightBlue,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _purpleAccent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          // Card number
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _purpleAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.outfit(color: _purpleAccent, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Card content preview
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card['front'].toString(),
                                  style: GoogleFonts.outfit(color: _pureWhite, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  card['back'].toString(),
                                  style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.5), fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Edit icon
                          Icon(Icons.edit, color: _pureWhite.withOpacity(0.4), size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Start button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('Start Studying', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purpleAccent,
                  foregroundColor: _pureWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
