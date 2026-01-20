import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'widgets/share_dialogs.dart';
import 'quiz_history_page.dart';

// Ocean Sunset Color Palette
const Color _deepNavy = Color(0xFF0A1929);
const Color _midnightBlue = Color(0xFF122A46);
const Color _electricBlue = Color(0xFF2196F3);
const Color _mintGreen = Color(0xFF4ECDC4);
const Color _softOrange = Color(0xFFFFB347);
const Color _pureWhite = Color(0xFFFFFFFF);

// API Key from .env
final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

class QuizMakerPage extends StatefulWidget {
  const QuizMakerPage({
    super.key, 
    this.initialOutline,
    this.classCode, // Add optional classCode
  });

  final String? initialOutline;
  final String? classCode;

  @override
  State<QuizMakerPage> createState() => _QuizMakerPageState();
}

class _QuizMakerPageState extends State<QuizMakerPage> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialOutline != null) {
      _notesController.text = widget.initialOutline!;
      // Auto-trigger generation after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateFromPastedText(autoStart: true);
      });
    }
  }
  
  // Quiz Configuration State
  String? _selectedOutlineId;
  String? _selectedOutlineContent;
  String? _selectedOutlineTitle;
  double _questionCount = 20;
  double _timerMinutes = 30;
  bool _isMultipleChoice = true;
  bool _isGenerating = false;
  
  // Attached files/images for quiz generation
  List<File> _attachedImages = [];
  List<Map<String, dynamic>> _attachedFiles = []; // {file, name, extension}
  
  // Generated questions storage
  List<dynamic> _generatedQuestions = [];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        backgroundColor: _deepNavy,
        body: Center(child: Text('Please sign in to use Quiz Maker', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        title: Text(
          'Generate a practice test',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,

        foregroundColor: _pureWhite,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Quiz History',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const QuizHistoryPage())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste your notes to generate practice questions',
              style: GoogleFonts.outfit(
                color: _pureWhite.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            
            // Large Text Input Area with Upload Icon and Attached Images
            Container(
              decoration: BoxDecoration(
                color: _midnightBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _pureWhite.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Input
                  TextField(
                    controller: _notesController,
                    maxLines: (_attachedImages.isEmpty && _attachedFiles.isEmpty) ? 8 : 5,
                    maxLength: 100000,
                    style: GoogleFonts.outfit(color: _pureWhite, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Put your notes here. We'll do the rest.",
                      hintStyle: GoogleFonts.outfit(
                        color: _pureWhite.withOpacity(0.4),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      counterText: '', // Hide default counter
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  
                  // Attached Images and Files inside container
                  if (_attachedImages.isNotEmpty || _attachedFiles.isNotEmpty)
                    Container(
                      height: 90,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          // Display attached images
                          ..._attachedImages.asMap().entries.map((entry) {
                            final index = entry.key;
                            final imageFile = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      imageFile,
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _attachedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          
                          // Display attached files
                          ..._attachedFiles.asMap().entries.map((entry) {
                            final index = entry.key;
                            final fileData = entry.value;
                            final extension = fileData['extension'] as String;
                            final fileName = fileData['name'] as String;
                            
                            // Choose icon based on file type
                            IconData fileIcon;
                            Color iconColor;
                            if (extension == 'pdf') {
                              fileIcon = Icons.picture_as_pdf;
                              iconColor = Colors.red.shade400;
                            } else if (extension == 'doc' || extension == 'docx') {
                              fileIcon = Icons.description;
                              iconColor = Colors.blue.shade400;
                            } else {
                              fileIcon = Icons.insert_drive_file;
                              iconColor = Colors.grey.shade400;
                            }
                            
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Stack(
                                children: [
                                  Container(
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
                                        Icon(fileIcon, color: iconColor, size: 28),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4),
                                          child: Text(
                                            fileName.length > 10 
                                                ? '${fileName.substring(0, 8)}...'
                                                : fileName,
                                            style: GoogleFonts.outfit(
                                              color: _pureWhite.withOpacity(0.7),
                                              fontSize: 9,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _attachedFiles.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  
                  // Bottom row with upload icon and character count
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Upload Icon Button
                        GestureDetector(
                          onTap: _showUploadOptions,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _electricBlue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.attach_file,
                              color: _electricBlue,
                              size: 20,
                            ),
                          ),
                        ),
                        // Character count
                        Text(
                          '${_notesController.text.length}/100000',
                          style: GoogleFonts.outfit(
                            color: _pureWhite.withOpacity(0.5),
                            fontSize: 12,
                          ),
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
                    : () => _generateFromPastedText(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _electricBlue,
                  foregroundColor: _pureWhite,
                  disabledBackgroundColor: _electricBlue.withOpacity(0.3),
                  disabledForegroundColor: _pureWhite.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _pureWhite,
                        ),
                      )
                    : Text(
                        'Generate Questions',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Divider with "OR" text
            Row(
              children: [
                Expanded(child: Divider(color: _pureWhite.withOpacity(0.2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: GoogleFonts.outfit(
                      color: _pureWhite.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: _pureWhite.withOpacity(0.2))),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Saved Study Outlines Section
            Text(
              'Saved Study Outlines',
              style: GoogleFonts.outfit(
                color: _pureWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate questions from your saved outlines',
              style: GoogleFonts.outfit(
                color: _pureWhite.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            
            // Saved Outlines List
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('saved_outlines')
                  .where('userId', isEqualTo: user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: _midnightBlue.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _pureWhite.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.description_outlined, size: 48, color: _pureWhite.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'No saved outlines yet',
                          style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.5)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create outlines from Study AI to see them here',
                          style: GoogleFonts.outfit(
                            color: _pureWhite.withOpacity(0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                    final date = (data['createdAt'] as Timestamp?)?.toDate();
                    final dateStr = date != null ? '${date.month}/${date.day}/${date.year}' : '';
                    
                    return GestureDetector(
                      onTap: () => _generateAndShowConfig(
                        docs[index].id, 
                        title, 
                        (data['outline'] ?? data['content'] ?? '') as String
                      ),
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
                              child: const Icon(Icons.class_outlined, color: _electricBlue),
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
                                  content: data['outline'] ?? '',
                                  type: 'Quiz Study Guide',
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.arrow_forward_ios, 
                              color: _pureWhite.withOpacity(0.5), 
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Generate questions from pasted text, images, and documents
  Future<void> _generateFromPastedText({bool autoStart = false}) async {
    final content = _notesController.text.trim();
    
    // Check if there's any content (text, images, or files)
    if (content.isEmpty && _attachedImages.isEmpty && _attachedFiles.isEmpty) return;
    
    setState(() => _isGenerating = true);
    
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Determine what materials we have
      final hasText = content.isNotEmpty;
      final hasImages = _attachedImages.isNotEmpty;
      final hasDocuments = _attachedFiles.isNotEmpty;
      
      String materialDescription;
      if (hasText && hasDocuments) {
        materialDescription = 'Use the provided text notes AND the attached documents to generate questions.';
      } else if (hasDocuments) {
        materialDescription = 'Generate questions based on the attached documents.';
      } else if (hasImages && hasText) {
        materialDescription = 'Study Notes:\n$content';
      } else if (hasImages) {
        materialDescription = 'Generate questions from the attached images.';
      } else {
        materialDescription = 'Study Notes:\n$content';
      }
      
      final prompt = '''
Create a UNIQUE practice test based on the following study materials.
Generate exactly 50 diverse multiple choice questions.

IMPORTANT RULES:
- Each question MUST be different from any previous generation
- Cover ALL topics in the materials, not just the beginning
- Mix difficulty levels (easy, medium, hard)
- Use different question formats (what, why, how, which, when)
- Randomize the position of correct answers (don't always make it option A)
- Seed: $timestamp

Return ONLY a valid JSON array of objects. Do not include any other text.
Format:
[
  {
    "question": "The question text",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctIndex": 0
  }
]

$materialDescription
''';

      // Build parts list with text prompt and images
      List<Map<String, dynamic>> parts = [
        {'text': prompt}
      ];
      
      // Add attached images as base64
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
      
      // Add attached documents (PDF, DOC, DOCX) as base64
      for (final fileData in _attachedFiles) {
        final file = fileData['file'] as File;
        final extension = fileData['extension'] as String;
        final bytes = await file.readAsBytes();
        final base64Data = base64Encode(bytes);
        
        // Determine MIME type based on extension
        String mimeType;
        if (extension == 'pdf') {
          mimeType = 'application/pdf';
        } else if (extension == 'docx') {
          mimeType = 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
        } else if (extension == 'doc') {
          mimeType = 'application/msword';
        } else {
          continue; // Skip unsupported file types
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
            {
              'parts': parts
            }
          ],
          'generationConfig': {
            'temperature': 1.0,
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
        final List<dynamic> questions = jsonDecode(jsonString);
        
        questions.shuffle();
        
        setState(() {
          _generatedQuestions = questions;
          _selectedOutlineTitle = 'Custom Notes';
          _questionCount = questions.length.toDouble().clamp(5, 50);
          // Clear attachments after successful generation
          _attachedImages.clear();
          _attachedFiles.clear();
        });
        
        if (context.mounted) {
          if (autoStart) {
            _startQuiz();
          } else {
            _showConfigurationModal('Custom Notes', questions.length);
          }
        }
      } else {
        throw Exception('API Error: ${response.body}');
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating quiz: $e')),
        );
      }
    }
  }

  /// Show upload options bottom sheet
  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: _midnightBlue,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
            Text(
              'Upload Content',
              style: GoogleFonts.outfit(
                color: _pureWhite,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Extract text from your files or images',
              style: GoogleFonts.outfit(
                color: _pureWhite.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            
            // Upload File Option
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _electricBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description, color: _electricBlue),
              ),
              title: Text(
                'Upload File',
                style: GoogleFonts.outfit(
                  color: _pureWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'PDF, DOC, DOCX files',
                style: GoogleFonts.outfit(
                  color: _pureWhite.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: _pureWhite.withOpacity(0.5),
                size: 16,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Upload Image Option
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _mintGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image, color: _mintGreen),
              ),
              title: Text(
                'Upload Image',
                style: GoogleFonts.outfit(
                  color: _pureWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Extract text from photos of notes',
                style: GoogleFonts.outfit(
                  color: _pureWhite.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: _pureWhite.withOpacity(0.5),
                size: 16,
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Pick a document file (PDF, DOC, DOCX)
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
        
        // Add file to attached files list
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
          SnackBar(
            content: Text('Error attaching file: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Pick an image and attach it
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        final imageFile = File(image.path);
        
        setState(() {
          _attachedImages.add(imageFile);
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
          SnackBar(
            content: Text('Error attaching image: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  /// Append content to notes
  void _appendToNotes(String content) {
    final currentText = _notesController.text;
    if (currentText.isEmpty) {
      _notesController.text = content;
    } else {
      _notesController.text = '$currentText\n\n$content';
    }
    // Move cursor to end
    _notesController.selection = TextSelection.fromPosition(
      TextPosition(offset: _notesController.text.length),
    );
    setState(() {});
  }

  /// Generate questions first, then show config modal
  Future<void> _generateAndShowConfig(String id, String title, String content) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _midnightBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: _mintGreen),
              const SizedBox(height: 16),
              Text(
                'Generating questions...',
                style: GoogleFonts.outfit(color: _pureWhite),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Generate unique timestamp seed for variety
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final prompt = '''
Create a UNIQUE practice test based on the following study notes.
Generate exactly 50 diverse multiple choice questions.

IMPORTANT RULES:
- Each question MUST be different from any previous generation
- Cover ALL topics in the notes, not just the beginning
- Mix difficulty levels (easy, medium, hard)
- Use different question formats (what, why, how, which, when)
- Randomize the position of correct answers (don't always make it option A)
- Seed: $timestamp

Return ONLY a valid JSON array of objects.
Format:
[
  {
    "question": "The question text",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctIndex": 0
  }
]

Study Notes:
$content
''';

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'temperature': 1.0, // Higher temperature = more variety
            'topP': 0.95,
            'topK': 40,
          }
        }),
      );

      if (context.mounted) Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentText = data['candidates'][0]['content']['parts'][0]['text'];
        
        final jsonString = contentText.replaceAll('```json', '').replaceAll('```', '').trim();
        final List<dynamic> questions = jsonDecode(jsonString);
        
        // Shuffle questions for extra randomness
        questions.shuffle();
        
        setState(() {
          _generatedQuestions = questions;
          _selectedOutlineTitle = title;
          _questionCount = questions.length.toDouble().clamp(5, 50);
        });
        
        if (context.mounted) {
          _showConfigurationModal(title, questions.length);
        }
      } else {
        throw Exception('API Error: ${response.body}');
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading dialog if error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating quiz: $e')),
        );
      }
    }
  }

  void _showConfigurationModal(String title, int totalQuestions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: _deepNavy,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: _midnightBlue)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Your test has been generated',
                    style: GoogleFonts.outfit(
                      color: _pureWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "$totalQuestions questions ready • Customize '$title'",
                    style: GoogleFonts.outfit(
                      color: _pureWhite.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Scrollable Configuration Section
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Count
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _midnightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Questions (max $totalQuestions)',
                                style: GoogleFonts.outfit(
                                  color: _pureWhite.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _questionCount.round().toString(),
                                style: GoogleFonts.outfit(
                                  color: _pureWhite,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Slider(
                                value: _questionCount,
                                min: 5,
                                max: totalQuestions.toDouble(),
                                activeColor: _mintGreen,
                                inactiveColor: _deepNavy,
                                onChanged: (val) => setModalState(() => _questionCount = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Timer
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _midnightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Timer (minutes)',
                                style: GoogleFonts.outfit(
                                  color: _pureWhite.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _timerMinutes.round().toString(),
                                style: GoogleFonts.outfit(
                                  color: _pureWhite,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                               Slider(
                                value: _timerMinutes,
                                min: 5,
                                max: 60,
                                activeColor: _mintGreen,
                                inactiveColor: _deepNavy,
                                onChanged: (val) => setModalState(() => _timerMinutes = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Toggles
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Multiple choice',
                              style: GoogleFonts.outfit(
                                color: _pureWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Switch(
                              value: _isMultipleChoice,
                              onChanged: (val) => setModalState(() => _isMultipleChoice = true),
                              activeColor: _electricBlue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                         Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Written',
                              style: GoogleFonts.outfit(
                                color: _pureWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Switch(
                              value: !_isMultipleChoice,
                              onChanged: (val) => setModalState(() => _isMultipleChoice = false),
                              activeColor: _electricBlue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Actions (Fixed at bottom)
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close modal
                      _startQuiz();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _electricBlue,
                      foregroundColor: _pureWhite,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Take this test', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                   child: TextButton(
                    onPressed: () {
                       // TODO: View question bank
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: _pureWhite.withOpacity(0.7),
                    ),
                     child: const Text('View question bank'),
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _startQuiz() {
    // Take only the number of questions the user selected
    final questionsToUse = _generatedQuestions.take(_questionCount.round()).toList();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPage(
          title: _selectedOutlineTitle ?? 'Quiz',
          questions: questionsToUse,
          timerMinutes: _timerMinutes.round(),
          classCode: widget.classCode,
        ),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final String title;
  final List<dynamic> questions;
  final int timerMinutes;
  final String? classCode;

  const QuizPage({
    super.key,
    required this.title,
    required this.questions,
    required this.timerMinutes,
    this.classCode,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentQuestionIndex = 0;
  Map<int, int> _selectedAnswers = {};
  Map<int, bool> _checkedAnswers = {}; // Track which questions have been checked
  int _secondsRemaining = 0;
  Timer? _timer;
  bool _quizCompleted = false;
  
  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.timerMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _finishQuiz();
      }
    });
  }

  Future<void> _saveQuizResult() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      final score = _calculateScore();
      final total = widget.questions.length;
      final percentage = (score / total * 100).round();
      final now = DateTime.now();

        // 1. Save Quiz Result
      await FirebaseFirestore.instance.collection('quiz_results').add({
        'userId': user.uid,
        'quizTitle': widget.title,
        'score': score,
        'totalQuestions': total,
        'percentage': percentage,
        'classCode': widget.classCode,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Global Gamification Logic (Update User Profile)
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      // Update Global XP
      await userRef.update({
        'totalScore': FieldValue.increment(score),
      });

      // 3. Class-Specific Leaderboard (Contextual XP) 🏆
      if (widget.classCode != null) {
        final userData = await userRef.get();
        final userName = userData.data()?['fullName'] ?? userData.data()?['name'] ?? 'Student';
        
        final leaderboardRef = FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classCode)
            .collection('leaderboard')
            .doc(user.uid);

        await leaderboardRef.set({
          'userId': user.uid,
          'name': userName,
          'score': FieldValue.increment(score), // Accumulate score
          'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    
    // Badge: Perfect Score
    List<String> newBadges = [];
    if (percentage == 100) {
      newBadges.add('perfect_score');
    }
    
    // Badge: Night Owl (after 10 PM / 22:00)
    if (now.hour >= 22) {
      newBadges.add('night_owl');
    }

    // Update User Badges
    if (newBadges.isNotEmpty) {
      await userRef.set({
        'badges': FieldValue.arrayUnion(newBadges)
      }, SetOptions(merge: true));
    }

    } catch (e) {
      // DEBUG: Show error to user
      print('Error saving quiz result: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving score: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _finishQuiz() {
    _timer?.cancel();
    _saveQuizResult();
    setState(() => _quizCompleted = true);
  }

  int _calculateScore() {
    int correct = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final correctIndex = widget.questions[i]['correctIndex'];
      if (_selectedAnswers[i] == correctIndex) {
        correct++;
      }
    }
    return correct;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show results page if quiz is completed
    if (_quizCompleted) {
      return _buildResultsPage();
    }
    
    final question = widget.questions[_currentQuestionIndex];
    final options = List<String>.from(question['options'] ?? []);
    final correctIndex = question['correctIndex'] as int;
    final hasChecked = _checkedAnswers[_currentQuestionIndex] == true;
    final selectedIndex = _selectedAnswers[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        // DEBUG: content show classCode if present
        title: Column(
          children: [
            Text(widget.title, style: GoogleFonts.outfit(fontSize: 16)),
            if (widget.classCode != null)
              Text(
                'Class: ${widget.classCode}', 
                style: GoogleFonts.firaCode(fontSize: 10, color: _mintGreen)
              ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _pureWhite,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _softOrange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(_secondsRemaining / 60).floor()}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.firaCode(
                    color: _deepNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.questions.length,
            backgroundColor: _midnightBlue,
            color: _mintGreen,
            minHeight: 4,
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${widget.questions.length}',
                    style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question['question'],
                    style: GoogleFonts.outfit(
                      color: _pureWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  ...List.generate(options.length, (index) {
                    final isSelected = selectedIndex == index;
                    final isCorrect = index == correctIndex;
                    
                    // Determine colors based on check status
                    Color bgColor = _midnightBlue;
                    Color borderColor = Colors.transparent;
                    IconData? feedbackIcon;
                    Color? iconColor;
                    
                    if (hasChecked) {
                      if (isCorrect) {
                        bgColor = const Color(0xFF1B5E20).withOpacity(0.3); // Green
                        borderColor = const Color(0xFF4CAF50);
                        feedbackIcon = Icons.check_circle;
                        iconColor = const Color(0xFF4CAF50);
                      } else if (isSelected && !isCorrect) {
                        bgColor = const Color(0xFFB71C1C).withOpacity(0.3); // Red
                        borderColor = const Color(0xFFF44336);
                        feedbackIcon = Icons.cancel;
                        iconColor = const Color(0xFFF44336);
                      }
                    } else if (isSelected) {
                      bgColor = _electricBlue.withOpacity(0.2);
                      borderColor = _electricBlue;
                    }
                    
                    return GestureDetector(
                      onTap: hasChecked ? null : () {
                        setState(() {
                          _selectedAnswers[_currentQuestionIndex] = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (feedbackIcon != null) ...[
                              Icon(feedbackIcon, color: iconColor, size: 24),
                            ] else ...[
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? _electricBlue : _pureWhite.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: const BoxDecoration(
                                            color: _electricBlue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                options[index],
                                style: GoogleFonts.outfit(
                                  color: _pureWhite,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  
                  // Show "Check Answer" button if not yet checked
                  if (!hasChecked && selectedIndex != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _checkedAnswers[_currentQuestionIndex] = true;
                          });
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('Check Answer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _mintGreen,
                          foregroundColor: _deepNavy,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ],
                  
                  // Show feedback message after checking
                  if (hasChecked) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedIndex == correctIndex 
                            ? const Color(0xFF1B5E20).withOpacity(0.2)
                            : const Color(0xFFB71C1C).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedIndex == correctIndex ? Icons.celebration : Icons.lightbulb_outline,
                            color: selectedIndex == correctIndex ? const Color(0xFF4CAF50) : _softOrange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedIndex == correctIndex 
                                  ? 'Correct! Well done!' 
                                  : 'The correct answer is: ${options[correctIndex]}',
                              style: GoogleFonts.outfit(
                                color: _pureWhite,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Bottom Navigation
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _midnightBlue)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentQuestionIndex > 0)
                  TextButton.icon(
                    onPressed: () => setState(() => _currentQuestionIndex--),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: TextButton.styleFrom(foregroundColor: _pureWhite),
                  )
                else
                  const SizedBox.shrink(),
                  
                ElevatedButton(
                  onPressed: () {
                    if (_currentQuestionIndex < widget.questions.length - 1) {
                      setState(() => _currentQuestionIndex++);
                    } else {
                      _finishQuiz();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _electricBlue,
                    foregroundColor: _pureWhite,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    _currentQuestionIndex < widget.questions.length - 1 ? 'Next' : 'Submit',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPage() {
    final score = _calculateScore();
    final total = widget.questions.length;
    final percentage = (score / total * 100).round();
    
    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        title: Text('Results', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _pureWhite,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Score Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: percentage >= 70 
                      ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                      : percentage >= 50 
                          ? [const Color(0xFFF57C00), const Color(0xFFFF9800)]
                          : [const Color(0xFFB71C1C), const Color(0xFFD32F2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    percentage >= 70 ? Icons.emoji_events : percentage >= 50 ? Icons.thumb_up : Icons.refresh,
                    size: 64,
                    color: _pureWhite,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$percentage%',
                    style: GoogleFonts.outfit(
                      color: _pureWhite,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$score out of $total correct',
                    style: GoogleFonts.outfit(
                      color: _pureWhite.withOpacity(0.9),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    percentage >= 70 ? 'Excellent work!' : percentage >= 50 ? 'Good effort!' : 'Keep practicing!',
                    style: GoogleFonts.outfit(
                      color: _pureWhite.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Question Summary
            Text(
              'Question Summary',
              style: GoogleFonts.outfit(
                color: _pureWhite,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...List.generate(widget.questions.length, (index) {
              final question = widget.questions[index];
              final options = List<String>.from(question['options'] ?? []);
              
              // Safely get correctIndex with bounds checking
              int correctIndex = question['correctIndex'] as int? ?? 0;
              if (correctIndex < 0 || correctIndex >= options.length) {
                correctIndex = 0; // Default to first option if invalid
              }
              
              final userAnswer = _selectedAnswers[index];
              final isCorrect = userAnswer != null && userAnswer == correctIndex;
              final wasSkipped = userAnswer == null;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _midnightBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: wasSkipped 
                        ? Colors.grey 
                        : (isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          wasSkipped 
                              ? Icons.remove_circle_outline 
                              : (isCorrect ? Icons.check_circle : Icons.cancel),
                          color: wasSkipped 
                              ? Colors.grey 
                              : (isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Question ${index + 1}',
                          style: GoogleFonts.outfit(
                            color: _pureWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (wasSkipped) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Skipped',
                              style: GoogleFonts.outfit(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question['question'] ?? '',
                      style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 8),
                    if (userAnswer != null && userAnswer >= 0 && userAnswer < options.length)
                      Text(
                        'Your answer: ${options[userAnswer]}',
                        style: GoogleFonts.outfit(
                          color: isCorrect ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
                        ),
                      ),
                    if (!isCorrect && options.isNotEmpty)
                      Text(
                        'Correct answer: ${options[correctIndex]}',
                        style: GoogleFonts.outfit(color: const Color(0xFF4CAF50)),
                      ),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _electricBlue,
                foregroundColor: _pureWhite,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
