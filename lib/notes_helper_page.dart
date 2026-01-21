import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'widgets/share_dialogs.dart';

// Ocean Sunset Color Palette
const Color _deepNavy = Color(0xFF0A1929);
const Color _midnightBlue = Color(0xFF122A46);
const Color _electricBlue = Color(0xFF2196F3);
const Color _mintGreen = Color(0xFF4ECDC4);
const Color _softOrange = Color(0xFFFFB347);
const Color _pureWhite = Color(0xFFFFFFFF);

// API Key from .env
final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

class NotesHelperPage extends StatefulWidget {
  const NotesHelperPage({super.key, this.initialContent, this.initialTitle});

  final String? initialContent;
  final String? initialTitle;

  @override
  State<NotesHelperPage> createState() => _NotesHelperPageState();
}

class _NotesHelperPageState extends State<NotesHelperPage> {
  final TextEditingController _notesController = TextEditingController();
  
  // Attached files/images
  List<File> _attachedImages = [];
  List<Map<String, dynamic>> _attachedFiles = []; // {file, name, extension}
  
  @override
  void initState() {
    super.initState();
    if (widget.initialContent != null) {
      _generatedOutline = widget.initialContent;
      _generatedTitle = widget.initialTitle ?? 'Shared Notes';
      _showOutline = true;
    }
  }
  final TextEditingController _editController = TextEditingController();
  bool _isGenerating = false;
  bool _isEditing = false;
  String? _generatedOutline;
  String? _generatedTitle;
  List<Map<String, String>> _references = [];
  bool _showOutline = false;
  int _selectedTab = 0;

  @override
  void dispose() {
    _notesController.dispose();
    _editController.dispose();
    super.dispose();
  }

  Future<void> _generateOutline() async {
    if (_notesController.text.trim().isEmpty && _attachedImages.isEmpty && _attachedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text or upload a file first.')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final prompt = '''
You are a study assistant. Analyze the following student notes and create a well-structured outline and a list of study references.

Return ONLY a valid JSON object with this exact structure:
{
  "title": "A short, descriptive title for the notes",
  "outline": "The markdown generated outline here...",
  "references": [
    {
      "title": "Title of the resource",
      "url": "https://example.com/relevant-link"
    }
  ]
}

For the outline:
- A clear title based on the topic
- Main sections with headers (use ## for headers)
- Bullet points for key concepts (use - for bullets)
- Code blocks if there's any code (use ``` for code)

For references:
- Provide 3-5 high-quality, real web links relevant to the topic (e.g., documentation, tutorials, articles).

Student Notes:
${_notesController.text}
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
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Clean markdown code fence if present
        final jsonString = contentText.replaceAll('```json', '').replaceAll('```', '').trim();
        final content = jsonDecode(jsonString);
        
        if (mounted) {
          setState(() {
             // Use AI title, or fallback to first line of notes, or generic default
            _generatedTitle = content['title']?.toString() ?? 
                             (_notesController.text.split('\n').firstWhere((l) => l.isNotEmpty, orElse: () => 'Study Notes').trim());
            
            // Ensure title isn't too long if extracted from notes
            if (_generatedTitle!.length > 50) {
              _generatedTitle = '${_generatedTitle!.substring(0, 47)}...';
            }

            _generatedOutline = content['outline'];
            _references = List<Map<String, String>>.from(
              (content['references'] as List? ?? []).map((item) => { // Handle null list
                'title': item['title'].toString(),
                'url': item['url'].toString(),
              })
            );
            _showOutline = true;
            _isGenerating = false;
            _selectedTab = 0;
          });
        }
      } else {
        throw Exception('API Error: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating outline: $e')),
        );
      }
    }
  }

  // --- Upload Helpers ---

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _attachedImages.add(File(image.path));
      });
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      final extension = result.files.single.extension ?? '';
      final name = result.files.single.name;
      
      setState(() {
        _attachedFiles.add({
          'file': file,
          'name': name,
          'extension': extension,
        });
      });
    }
  }

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
                color: _pureWhite.withValues(alpha: 0.3),
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
                color: _pureWhite.withValues(alpha: 0.6),
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
                  color: _electricBlue.withValues(alpha: 0.2),
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
                  color: _pureWhite.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: _pureWhite.withValues(alpha: 0.5),
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
                  color: _mintGreen.withValues(alpha: 0.2),
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
                  color: _pureWhite.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: _pureWhite.withValues(alpha: 0.5),
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        title: Text(
          _showOutline ? 'Study Outline' : 'Notes Helper',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _pureWhite,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_showOutline) {
              setState(() => _showOutline = false);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: _showOutline
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => setState(() => _showOutline = false),
                  tooltip: 'Edit notes',
                ),
              ]
            : null,
      ),
      body: _showOutline 
        ? (_selectedTab == 0 ? _buildOutlineView() : _buildQuickReferenceView()) 
        : _buildInputView(),
    );
  }

  Widget _buildInputView() {
    final charCount = _notesController.text.length;
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notes Input Card
                Container(
                  decoration: BoxDecoration(
                    color: _midnightBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _notesController,
                    maxLines: 12,
                    maxLength: 100000,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Put your notes here. We\'ll do the rest.',
                      hintStyle: TextStyle(color: _pureWhite.withValues(alpha: 0.4)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(20),
                      counterText: '',
                    ),
                    style: GoogleFonts.outfit(
                      color: _pureWhite,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
                
                // Attached Images and Files display
                if (_attachedImages.isNotEmpty || _attachedFiles.isNotEmpty)
                  Container(
                    height: 90,
                    margin: const EdgeInsets.only(top: 16),
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
                                        color: Colors.black.withValues(alpha: 0.6),
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
                                    border: Border.all(color: _pureWhite.withValues(alpha: 0.2)),
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
                                            color: _pureWhite.withValues(alpha: 0.7),
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
                                        color: Colors.black.withValues(alpha: 0.6),
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

                // Upload Button and Char count row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Upload Icon Button
                      GestureDetector(
                        onTap: _showUploadOptions,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _electricBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.attach_file,
                            color: _electricBlue,
                            size: 22,
                          ),
                        ),
                      ),
                      // Character count
                      Text(
                        '$charCount/100,000 characters',
                        style: GoogleFonts.outfit(
                          color: _pureWhite.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // What you'll get section
                Text(
                  'From your notes, you\'ll get',
                  style: GoogleFonts.outfit(
                    color: _pureWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Outline feature
                _buildFeatureItem(
                  icon: Icons.format_list_bulleted_rounded,
                  iconColor: _mintGreen,
                  title: 'Study Outline',
                  description: 'Organized structure of your notes',
                ),
                const SizedBox(height: 12),
                
                // Key concepts feature
                _buildFeatureItem(
                  icon: Icons.lightbulb_outline_rounded,
                  iconColor: _softOrange,
                  title: 'Key Concepts',
                  description: 'Important points highlighted',
                ),
                const SizedBox(height: 12),
                
                // Code blocks feature
                _buildFeatureItem(
                  icon: Icons.code_rounded,
                  iconColor: _electricBlue,
                  title: 'Code Examples',
                  description: 'Formatted code snippets',
                ),
              ],
            ),
          ),
        ),
        
        // Bottom bar with disclaimer and generate button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _midnightBlue.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(color: _pureWhite.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'This product is enhanced by AI and may provide incorrect or problematic content. Do not enter personal data.',
                  style: GoogleFonts.outfit(
                    color: _pureWhite.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isGenerating || (_notesController.text.trim().isEmpty && _attachedImages.isEmpty && _attachedFiles.isEmpty)
                    ? null
                    : _generateOutline,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_notesController.text.trim().isEmpty && _attachedImages.isEmpty && _attachedFiles.isEmpty)
                      ? _midnightBlue
                      : _mintGreen,
                  foregroundColor: (_notesController.text.trim().isEmpty && _attachedImages.isEmpty && _attachedFiles.isEmpty)
                      ? _pureWhite.withValues(alpha: 0.4)
                      : _deepNavy,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _deepNavy,
                        ),
                      )
                    : Text(
                        'Generate',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: _pureWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.outfit(
                  color: _pureWhite.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutlineView() {
    if (_generatedOutline == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header Section
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title - Full Width
              Text(
                _generatedTitle ?? 'Study Notes',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _pureWhite,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              
              // Metadata and Actions Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Date
                    Icon(Icons.calendar_today, color: _pureWhite.withValues(alpha: 0.6), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Created ${_getCurrentDate()}',
                      style: GoogleFonts.outfit(
                        color: _pureWhite.withValues(alpha: 0.6),
                        fontSize: 14,
                      ),
                    ),
                    
                    const SizedBox(width: 24), // Spacer replacement
                    
                    // Actions
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _saveOutline(),
                          child: _buildHeaderAction(Icons.bookmark_border, 'Save'),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                             ShareHelper.shareContent(
                                context: context,
                                title: _generatedTitle ?? 'Study Notes',
                                content: _generatedOutline ?? '',
                                type: 'Notes',
                             );
                          },
                          child: _buildHeaderAction(Icons.share_outlined, 'Share'),
                        ),
                        const SizedBox(width: 8),
                        // Compact "More" button to save space
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _midnightBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.more_horiz, color: _pureWhite, size: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _pureWhite.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              _buildTab('Outline', _selectedTab == 0, 0),
              _buildTab('Quick reference', _selectedTab == 1, 1),
            ],
          ),
        ),
        
        // Outline content
        Expanded(
          child: _isEditing
              ? Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _midnightBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _editController,
                    maxLines: null,
                    style: GoogleFonts.firaCode(
                      color: _pureWhite,
                      fontSize: 14,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildMarkdownContent(_generatedOutline!),
                ),
        ),
        
        // Bottom action bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                label: _isEditing ? 'Save changes' : 'Edit outline',
                onTap: () {
                  if (_isEditing) {
                    // Save changes
                    setState(() {
                      _generatedOutline = _editController.text;
                      _isEditing = false;
                    });
                  } else {
                    // Start editing
                    _editController.text = _generatedOutline ?? '';
                    setState(() => _isEditing = true);
                  }
                },
                isPrimary: _isEditing,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.school_outlined,
                label: 'Study',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Study mode coming soon!')),
                  );
                },
                isPrimary: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String label, bool isActive, int index) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? _pureWhite : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isActive ? _pureWhite : _pureWhite.withValues(alpha: 0.5),
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickReferenceView() {
    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _pureWhite.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              _buildTab('Outline', _selectedTab == 0, 0),
              _buildTab('Quick reference', _selectedTab == 1, 1),
            ],
          ),
        ),
        
        // References Content
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _references.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ref = _references[index];
              return Container(
                decoration: BoxDecoration(
                  color: _midnightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _deepNavy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.language, color: _electricBlue),
                  ),
                  title: Text(
                    ref['title'] ?? 'Reference Link',
                    style: GoogleFonts.outfit(
                      color: _pureWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    ref['url'] ?? '',
                    style: GoogleFonts.outfit(
                      color: _pureWhite.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(Icons.open_in_new, color: _mintGreen, size: 20),
                  onTap: () async {
                    if (ref['url'] != null) {
                      final uri = Uri.parse(ref['url']!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary ? _mintGreen : _midnightBlue,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isPrimary ? _deepNavy : _pureWhite,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: isPrimary ? _deepNavy : _pureWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isPrimary) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: _deepNavy, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarkdownContent(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (var line in lines) {
      if (line.startsWith('## ')) {
        // Header
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(
            line.substring(3),
            style: GoogleFonts.outfit(
              color: _pureWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
      } else if (line.startsWith('### ')) {
        // Subheader
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(
            line.substring(4),
            style: GoogleFonts.outfit(
              color: _pureWhite,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ));
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        // Bullet point
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: TextStyle(color: _mintGreen, fontSize: 14)),
              Expanded(
                child: Text.rich(
                  _parseInlineStyles(
                    line.substring(2),
                    GoogleFonts.outfit(
                      color: _pureWhite.withValues(alpha: 0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('```')) {
        // Skip code block markers
        continue;
      } else if (line.trim().isNotEmpty) {
        // Regular text or code
        final isCode = _isInsideCodeBlock(lines, lines.indexOf(line));
        if (isCode) {
          widgets.add(Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _midnightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              line,
              style: GoogleFonts.firaCode(
                color: _mintGreen,
                fontSize: 13,
              ),
            ),
          ));
        } else {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text.rich(
              _parseInlineStyles(
                line,
                GoogleFonts.outfit(
                  color: _pureWhite.withValues(alpha: 0.8),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  TextSpan _parseInlineStyles(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final Match match in boldRegex.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      // Add the bold part
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(
          fontWeight: FontWeight.bold,
          color: _pureWhite, // Make bold text slightly brighter
        ),
      ));

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  bool _isInsideCodeBlock(List<String> lines, int currentIndex) {
    int codeBlockCount = 0;
    for (int i = 0; i < currentIndex; i++) {
      if (lines[i].trim().startsWith('```')) {
        codeBlockCount++;
      }
    }
    return codeBlockCount % 2 == 1;
  }

  Widget _buildHeaderAction(IconData icon, String? label) {
    return Container(
      padding: label != null 
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
          : const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _midnightBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _pureWhite, size: 16),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: _pureWhite,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${now.month}/${now.day}/${now.year.toString().substring(2)}';
  }

  Future<void> _saveOutline() async {
    if (_generatedOutline == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to save outlines')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('saved_outlines').add({
        'userId': user.uid,
        'title': _generatedTitle ?? 'Study Notes',
        'outline': _generatedOutline,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'notes',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to Quiz Maker!'),
            backgroundColor: _mintGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving outline: $e')),
        );
      }
    }
  }
}
