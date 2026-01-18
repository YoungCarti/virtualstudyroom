import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  const QuizMakerPage({super.key});

  @override
  State<QuizMakerPage> createState() => _QuizMakerPageState();
}

class _QuizMakerPageState extends State<QuizMakerPage> {
  final user = FirebaseAuth.instance.currentUser;
  
  // Quiz Configuration State
  String? _selectedOutlineId;
  String? _selectedOutlineContent;
  String? _selectedOutlineTitle;
  double _questionCount = 20;
  double _timerMinutes = 30;
  bool _isMultipleChoice = true;
  bool _isGenerating = false;

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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
             child: Text(
               'Choose or upload materials to generate practice questions designed for you',
               style: GoogleFonts.outfit(
                 color: _pureWhite.withOpacity(0.7),
                 fontSize: 14,
               ),
             ),
          ),
          
          // Tabs (Visual only for now matching screenshot)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildTab('Flashcard sets', true),
                _buildTab('Upload files', false),
                _buildTab('Paste text', false),
                _buildTab('Google Drive', false),
              ],
            ),
          ),
          
          const Divider(color: _midnightBlue, height: 1),
          
          // Saved Outlines List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('saved_outlines')
                  .where('userId', isEqualTo: user!.uid)
                  // .orderBy('createdAt', descending: true) // Temporarily removed to fix index error
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 64, color: _pureWhite.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'No saved outlines yet',
                          style: GoogleFonts.outfit(color: _pureWhite.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Untitled';
                    final date = (data['createdAt'] as Timestamp?)?.toDate();
                    final dateStr = date != null ? '${date.month}/${date.day}/${date.year}' : '';
                    
                    return GestureDetector(
                      onTap: () => _showConfigurationModal(
                        docs[index].id, 
                        title, 
                        data['outline'] ?? ''
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
                                    '$dateStr • by you', // Matching screenshot "76 terms • by you" style
                                    style: GoogleFonts.outfit(
                                      color: _pureWhite.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Preview',
                              style: GoogleFonts.outfit(
                                color: _pureWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.add_circle_outline, color: _pureWhite.withOpacity(0.7)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 24),
      padding: const EdgeInsets.only(bottom: 8),
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
          color: isActive ? _pureWhite : _pureWhite.withOpacity(0.5),
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  void _showConfigurationModal(String id, String title, String content) {
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
                    "Customize '$title'",
                    style: GoogleFonts.outfit(
                      color: _pureWhite.withOpacity(0.8),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                
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
                        'Questions (max 100)',
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
                        max: 100,
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
                      onChanged: (val) => setModalState(() => _isMultipleChoice = true), // For now enforce one or other
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
                
                const Spacer(),
                
                // Actions
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close modal
                    _generateQuiz(context, title, content);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: _electricBlue,
                    elevation: 0,
                  ),
                  child: const Text('Take this test', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                 ElevatedButton(
                  onPressed: () {
                     // TODO: View question bank
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: _pureWhite,
                    elevation: 0,
                  ),
                   child: const Text('View question bank', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Future<void> _generateQuiz(BuildContext context, String title, String content) async {
    setState(() => _isGenerating = true);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prompt = '''
Create a practice test based on the following study notes.
Number of questions: ${_questionCount.round()}
Type: ${_isMultipleChoice ? "Multiple Choice" : "Written/Short Answer"}

Return ONLY a valid JSON array of objects.
Format:
[
  {
    "question": "The question text",
    "options": ["Option A", "Option B", "Option C", "Option D"], // Only if multiple choice
    "correctIndex": 0 // Index of the correct option (0-3)
  }
]

Review Notes:
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
          ]
        }),
      );

      if (context.mounted) Navigator.pop(context); // Close loading dialog
      setState(() => _isGenerating = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contentText = data['candidates'][0]['content']['parts'][0]['text'];
        
        final jsonString = contentText.replaceAll('```json', '').replaceAll('```', '').trim();
        final List<dynamic> questions = jsonDecode(jsonString);
        
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizPage(
                title: title,
                questions: questions,
                timerMinutes: _timerMinutes.round(),
              ),
            ),
          );
        }
      } else {
        throw Exception('API Error: ${response.body}');
      }
    } catch (e) {
      if (context.mounted)Navigator.pop(context); // Close loading dialog if error
      setState(() => _isGenerating = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating quiz: $e')),
        );
      }
    }
  }
}

class QuizPage extends StatefulWidget {
  final String title;
  final List<dynamic> questions;
  final int timerMinutes;

  const QuizPage({
    super.key,
    required this.title,
    required this.questions,
    required this.timerMinutes,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int _currentQuestionIndex = 0;
  Map<int, int> _selectedAnswers = {};
  int _secondsRemaining = 0;
  Timer? _timer;
  
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
        // TODO: Auto-submit quiz
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentQuestionIndex];
    final options = List<String>.from(question['options'] ?? []);

    return Scaffold(
      backgroundColor: _deepNavy,
      appBar: AppBar(
        title: Text(widget.title, style: GoogleFonts.outfit(fontSize: 16)),
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
                    final isSelected = _selectedAnswers[_currentQuestionIndex] == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedAnswers[_currentQuestionIndex] = index;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? _electricBlue.withOpacity(0.2) : _midnightBlue,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? _electricBlue : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
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
                      // Finish Quiz
                      Navigator.pop(context); // Basic exit for now
                      // TODO: Show Results Page
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
}
