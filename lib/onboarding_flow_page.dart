import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app_fonts.dart';
import 'home_dashboard.dart';
import 'services/notification_service.dart';

// --- Ocean Sunset Theme Colors ---
class _AppColors {
  static const background = Color(0xFF0A1929);
  static const cardBg = Color(0xFF122A46);
  static const primary = Color(0xFF2196F3);
  static const accent1 = Color(0xFFFF6B6B);
  static const accent2 = Color(0xFF4ECDC4);
  static const accent3 = Color(0xFFFFB347);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF90A4AE);
  static const divider = Color(0xFF1E3A5F);
}

class OnboardingFlowPage extends StatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  State<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<OnboardingFlowPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6; // Updated from 5 to 6

  // Collected data
  File? _profileImage;
  String _displayName = '';
  List<String> _selectedInterests = [];
  String? _selectedCampus;
  String? _selectedProgram; // New
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _displayName = doc.data()?['name'] ?? user.displayName ?? '';
        });
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? profilePictureUrl;

    // Upload profile picture if selected
    if (_profileImage != null) {
      try {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('${user.uid}.jpg');
        await ref.putFile(_profileImage!);
        profilePictureUrl = await ref.getDownloadURL();
      } catch (e) {
        debugPrint('Error uploading profile picture: $e');
      }
    }

    // Save to Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'profilePictureUrl': profilePictureUrl,
      'interests': _selectedInterests,
      'campus': _selectedCampus,
      'program': _selectedProgram,
      'notificationsEnabled': _notificationsEnabled,
      'onboardingCompleted': true,
    });

    // Navigate to home
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeDashboardPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with progress and skip
            _buildTopBar(),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _StepProfile(
                    displayName: _displayName,
                    profileImage: _profileImage,
                    onImageSelected: (file) => setState(() => _profileImage = file),
                    onNameChanged: (name) => setState(() => _displayName = name),
                    onContinue: _nextPage,
                  ),
                  _StepInterests(
                    selectedInterests: _selectedInterests,
                    onInterestsChanged: (interests) => setState(() => _selectedInterests = interests),
                    onContinue: _nextPage,
                  ),
                  _StepCampus(
                    selectedCampus: _selectedCampus,
                    onCampusSelected: (campus) => setState(() => _selectedCampus = campus),
                    onContinue: _nextPage,
                  ),
                  _StepProgram(
                    selectedProgram: _selectedProgram,
                    onProgramSelected: (program) => setState(() => _selectedProgram = program),
                    onContinue: _nextPage,
                  ),
                  _StepNotifications(
                    onEnabled: (enabled) => setState(() => _notificationsEnabled = enabled),
                    onContinue: _nextPage,
                  ),
                  _StepCompletion(
                    onComplete: _completeOnboarding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back button
          if (_currentPage > 0 && _currentPage < 4)
            GestureDetector(
              onTap: _previousPage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _AppColors.cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: _AppColors.textPrimary,
                  size: 18,
                ),
              ),
            )
          else
            const SizedBox(width: 34),

          // Progress dots
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (index) {
                final isActive = index == _currentPage;
                final isCompleted = index < _currentPage;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? _AppColors.primary
                        : isCompleted
                            ? _AppColors.accent2
                            : _AppColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),

          // Skip button
          if (_currentPage < 4)
            GestureDetector(
              onTap: () {
                // Skip to completion
                _pageController.animateToPage(
                  4,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(
                'Skip',
                style: AppFonts.clashGrotesk(
                  color: _AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            const SizedBox(width: 34),
        ],
      ),
    );
  }
}

// ============================================================================
// STEP 1: Profile Picture
// ============================================================================
class _StepProfile extends StatelessWidget {
  final String displayName;
  final File? profileImage;
  final Function(File) onImageSelected;
  final Function(String) onNameChanged;
  final VoidCallback onContinue;

  const _StepProfile({
    required this.displayName,
    this.profileImage,
    required this.onImageSelected,
    required this.onNameChanged,
    required this.onContinue,
  });

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: _AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: _AppColors.primary),
              ),
              title: Text(
                'Take Photo',
                style: AppFonts.clashGrotesk(color: _AppColors.textPrimary),
              ),
              onTap: () async {
                Navigator.pop(context);
                final picked = await picker.pickImage(source: ImageSource.camera);
                if (picked != null) onImageSelected(File(picked.path));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _AppColors.accent2.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: _AppColors.accent2),
              ),
              title: Text(
                'Choose from Gallery',
                style: AppFonts.clashGrotesk(color: _AppColors.textPrimary),
              ),
              onTap: () async {
                Navigator.pop(context);
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) onImageSelected(File(picked.path));
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Create your profile',
            style: AppFonts.clashGrotesk(
              color: _AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a profile picture and confirm your display name',
            style: AppFonts.clashGrotesk(
              color: _AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Profile picture
          Center(
            child: GestureDetector(
              onTap: () => _pickImage(context),
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _AppColors.cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: _AppColors.divider, width: 2),
                      image: profileImage != null
                          ? DecorationImage(
                              image: FileImage(profileImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: profileImage == null
                        ? const Icon(
                            Icons.camera_alt_outlined,
                            color: _AppColors.textSecondary,
                            size: 40,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: _AppColors.background, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Name field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: _AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _AppColors.divider),
            ),
            child: TextField(
              controller: TextEditingController(text: displayName),
              onChanged: onNameChanged,
              style: AppFonts.clashGrotesk(
                color: _AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Your display name',
                hintStyle: AppFonts.clashGrotesk(
                  color: _AppColors.textSecondary,
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Continue button
          _ContinueButton(onPressed: onContinue),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ============================================================================
// STEP 2: Choose Interests
// ============================================================================
class _StepInterests extends StatelessWidget {
  final List<String> selectedInterests;
  final Function(List<String>) onInterestsChanged;
  final VoidCallback onContinue;

  const _StepInterests({
    required this.selectedInterests,
    required this.onInterestsChanged,
    required this.onContinue,
  });

  static const _interests = [
    {'name': 'Mathematics', 'subtitle': 'Algebra, Calculus, Statistics', 'icon': Icons.calculate, 'color': Color(0xFFFF6B6B)},
    {'name': 'Science', 'subtitle': 'Physics, Chemistry, Biology', 'icon': Icons.science, 'color': Color(0xFF4ECDC4)},
    {'name': 'Technology', 'subtitle': 'Programming, AI, Robotics', 'icon': Icons.computer, 'color': Color(0xFF2196F3)},
    {'name': 'Business', 'subtitle': 'Finance, Marketing, Economics', 'icon': Icons.business_center, 'color': Color(0xFFFFB347)},
    {'name': 'Arts', 'subtitle': 'Design, Music, Literature', 'icon': Icons.palette, 'color': Color(0xFFE040FB)},
    {'name': 'Languages', 'subtitle': 'English, Malay, Mandarin', 'icon': Icons.translate, 'color': Color(0xFF00BCD4)},
  ];

  void _toggleInterest(String interest) {
    final updated = List<String>.from(selectedInterests);
    if (updated.contains(interest)) {
      updated.remove(interest);
    } else {
      updated.add(interest);
    }
    onInterestsChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Choose your interests',
            style: AppFonts.clashGrotesk(
              color: _AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select topics you want to study and learn about',
            style: AppFonts.clashGrotesk(
              color: _AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: ListView.separated(
              itemCount: _interests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _interests[index];
                final isSelected = selectedInterests.contains(item['name']);
                return _InterestTile(
                  name: item['name'] as String,
                  subtitle: item['subtitle'] as String,
                  icon: item['icon'] as IconData,
                  color: item['color'] as Color,
                  isSelected: isSelected,
                  onTap: () => _toggleInterest(item['name'] as String),
                );
              },
            ),
          ),
          
          // Continue button
          _ContinueButton(onPressed: onContinue),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InterestTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestTile({
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : _AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : _AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppFonts.clashGrotesk(
                      color: _AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppFonts.clashGrotesk(
                      color: _AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _AppColors.divider, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STEP 3: Choose Campus
// ============================================================================
class _StepCampus extends StatefulWidget {
  final String? selectedCampus;
  final Function(String?) onCampusSelected;
  final VoidCallback onContinue;

  const _StepCampus({
    this.selectedCampus,
    required this.onCampusSelected,
    required this.onContinue,
  });

  @override
  State<_StepCampus> createState() => _StepCampusState();
}

class _StepCampusState extends State<_StepCampus> {
  String _searchQuery = '';

  static const _campuses = [
    'UiTM Shah Alam',
    'UiTM Puncak Alam',
    'Universiti Malaya (UM)',
    'Universiti Putra Malaysia (UPM)',
    'Universiti Sains Malaysia (USM)',
    'Universiti Kebangsaan Malaysia (UKM)',
    'Universiti Teknologi Malaysia (UTM)',
    'Universiti Teknologi MARA (UiTM)',
    'Multimedia University (MMU)',
    'INTI International University',
    'Taylor\'s University',
    'Sunway University',
    'HELP University',
    'Asia Pacific University (APU)',
    'UCSI University',
    'Other',
  ];

  List<String> get _filteredCampuses {
    if (_searchQuery.isEmpty) return _campuses;
    return _campuses
        .where((c) => c.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Choose your campus',
            style: AppFonts.clashGrotesk(
              color: _AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your university or school',
            style: AppFonts.clashGrotesk(
              color: _AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _AppColors.divider),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: AppFonts.clashGrotesk(color: _AppColors.textPrimary),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search campus...',
                hintStyle: AppFonts.clashGrotesk(color: _AppColors.textSecondary),
                icon: const Icon(Icons.search, color: _AppColors.textSecondary),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.separated(
              itemCount: _filteredCampuses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final campus = _filteredCampuses[index];
                final isSelected = widget.selectedCampus == campus;
                return GestureDetector(
                  onTap: () => widget.onCampusSelected(campus),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _AppColors.primary.withOpacity(0.1)
                          : _AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _AppColors.primary : _AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.school,
                          color: isSelected ? _AppColors.primary : _AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            campus,
                            style: AppFonts.clashGrotesk(
                              color: _AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: _AppColors.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Continue button
          _ContinueButton(onPressed: widget.onContinue),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ============================================================================
// STEP 4: Choose Program
// ============================================================================
class _StepProgram extends StatefulWidget {
  final String? selectedProgram;
  final Function(String?) onProgramSelected;
  final VoidCallback onContinue;

  const _StepProgram({
    this.selectedProgram,
    required this.onProgramSelected,
    required this.onContinue,
  });

  @override
  State<_StepProgram> createState() => _StepProgramState();
}

class _StepProgramState extends State<_StepProgram> {
  String _searchQuery = '';
  final TextEditingController _customProgramController = TextEditingController();
  bool _isCustom = false;

  static const _programs = [
    'Bachelor of Computer Science',
    'Bachelor of Software Engineering',
    'Bachelor of Information Technology',
    'Bachelor of Data Science',
    'Bachelor of Artificial Intelligence',
    'Bachelor of Cybersecurity',
    'Bachelor of Business Administration',
    'Bachelor of Accounting',
    'Bachelor of Finance',
    'Bachelor of Marketing',
    'Bachelor of Mechanical Engineering',
    'Bachelor of Electrical Engineering',
    'Bachelor of Civil Engineering',
    'Bachelor of Medicine',
    'Bachelor of Law',
    'Other',
  ];

  List<String> get _filteredPrograms {
    if (_searchQuery.isEmpty) return _programs;
    return _programs
        .where((p) => p.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _customProgramController.dispose();
    super.dispose();
  }

  void _selectProgram(String program) {
    if (program == 'Other') {
      setState(() => _isCustom = true);
    } else {
      setState(() => _isCustom = false);
      widget.onProgramSelected(program);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Text(
            'Choose your program',
            style: AppFonts.clashGrotesk(
              color: _AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the program you are currently studying',
            style: AppFonts.clashGrotesk(
              color: _AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _AppColors.divider),
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              style: AppFonts.clashGrotesk(color: _AppColors.textPrimary),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search program...',
                hintStyle: AppFonts.clashGrotesk(color: _AppColors.textSecondary),
                icon: const Icon(Icons.search, color: _AppColors.textSecondary),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Custom program input (shown when "Other" is selected)
          if (_isCustom) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _AppColors.primary),
              ),
              child: TextField(
                controller: _customProgramController,
                autofocus: true,
                onChanged: (value) {
                  widget.onProgramSelected(value.trim().isNotEmpty ? value.trim() : null);
                },
                style: AppFonts.clashGrotesk(color: _AppColors.textPrimary),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter your program name...',
                  hintStyle: AppFonts.clashGrotesk(color: _AppColors.textSecondary),
                  icon: const Icon(Icons.edit, color: _AppColors.primary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, color: _AppColors.textSecondary),
                    onPressed: () {
                      setState(() => _isCustom = false);
                      widget.onProgramSelected(null);
                      _customProgramController.clear();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          Expanded(
            child: ListView.separated(
              itemCount: _filteredPrograms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final program = _filteredPrograms[index];
                final isSelected = widget.selectedProgram == program || 
                    (program == 'Other' && _isCustom);
                return GestureDetector(
                  onTap: () => _selectProgram(program),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _AppColors.accent3.withValues(alpha: 0.1)
                          : _AppColors.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? _AppColors.accent3 : _AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          program == 'Other' ? Icons.edit_note : Icons.school_outlined,
                          color: isSelected ? _AppColors.accent3 : _AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            program,
                            style: AppFonts.clashGrotesk(
                              color: _AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected && program != 'Other')
                          const Icon(Icons.check_circle, color: _AppColors.accent3),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Continue button
          _ContinueButton(onPressed: widget.onContinue),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ============================================================================
// STEP 5: Notifications
// ============================================================================
class _StepNotifications extends StatelessWidget {
  final Function(bool) onEnabled;
  final VoidCallback onContinue;

  const _StepNotifications({
    required this.onEnabled,
    required this.onContinue,
  });

  Future<void> _requestPermission(BuildContext context) async {
    try {
      // Request notification permission
      final status = await Permission.notification.request();
      if (status.isGranted) {
        onEnabled(true);
        await NotificationService().requestPermissions();
      }
      onContinue();
    } catch (e) {
      onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(),
          
          // Notification icon illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: _AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Decorative dots
                Positioned(
                  top: 20,
                  right: 30,
                  child: _dot(8, _AppColors.accent2),
                ),
                Positioned(
                  bottom: 30,
                  left: 20,
                  child: _dot(6, _AppColors.accent3),
                ),
                Positioned(
                  top: 40,
                  left: 40,
                  child: _dot(10, _AppColors.primary.withOpacity(0.5)),
                ),
                // Main icon
                Icon(
                  Icons.notifications_active,
                  size: 80,
                  color: _AppColors.primary,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          Text(
            'Turn on notifications',
            style: AppFonts.clashGrotesk(
              color: _AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Get notified about new assignments, group messages, and important updates',
              textAlign: TextAlign.center,
              style: AppFonts.clashGrotesk(
                color: _AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Turn on button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => _requestPermission(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Turn On Notifications',
                style: AppFonts.clashGrotesk(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Remind later
          TextButton(
            onPressed: () {
              onEnabled(false);
              onContinue();
            },
            child: Text(
              'Remind me later',
              style: AppFonts.clashGrotesk(
                color: _AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _dot(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ============================================================================
// STEP 5: Completion
// ============================================================================
class _StepCompletion extends StatefulWidget {
  final Future<void> Function() onComplete;

  const _StepCompletion({required this.onComplete});

  @override
  State<_StepCompletion> createState() => _StepCompletionState();
}

class _StepCompletionState extends State<_StepCompletion> {
  @override
  void initState() {
    super.initState();
    // Start completion after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success illustration
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: _AppColors.accent2.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _AppColors.accent2,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          Text(
            'Setting up your profile...',
            style: AppFonts.clashGrotesk(
              color: _AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 24),
          
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: _AppColors.primary,
              strokeWidth: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Shared Widgets
// ============================================================================
class _ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ContinueButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'Continue',
          style: AppFonts.clashGrotesk(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
