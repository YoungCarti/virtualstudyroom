import 'package:flutter/material.dart';

const Color _primaryCyan = Color(0xFF5BB5D9);
const Color _darkBackground = Color(0xFF1C1C28);
const Color _cardBackground = Color(0xFF2A2A3E);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Saabiresh Loganathan');
  final _ageController = TextEditingController(text: '23');
  final _bioController = TextEditingController();
  final _socialMediaController = TextEditingController();
  final _countryController = TextEditingController(text: 'Sri Lanka');
  final _emailController = TextEditingController();
  final _dobController = TextEditingController(text: '11/08/1947');
  
  String _selectedGender = 'Male';
  String _selectedPronoun = 'He/Him';
  final List<String> _interests = [];
  final _interestController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _socialMediaController.dispose();
    _countryController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  void _addInterest() {
    if (_interestController.text.trim().isNotEmpty) {
      setState(() {
        _interests.add(_interestController.text.trim());
        _interestController.clear();
      });
    }
  }

  void _removeInterest(int index) {
    setState(() {
      _interests.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1947, 8, 11),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      appBar: AppBar(
        backgroundColor: _darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                        image: const DecorationImage(
                          image: NetworkImage('https://i.pravatar.cc/150?img=33'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _primaryCyan,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Name Field
              _buildLabel('Name'),
              _buildTextField(
                controller: _nameController,
                hintText: 'Enter your name',
              ),
              const SizedBox(height: 20),

              // Age Field
              _buildLabel('Age'),
              _buildTextField(
                controller: _ageController,
                hintText: 'Enter your age',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Bio Field
              _buildLabel('Bio'),
              _buildTextField(
                controller: _bioController,
                hintText: 'Add bio or anything about yourself',
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Social Media Field
              _buildLabel('Social Media'),
              _buildTextField(
                controller: _socialMediaController,
                hintText: 'Link to your profile',
              ),
              const SizedBox(height: 20),

              // Interests Field
              _buildLabel('Interests'),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _interestController,
                      hintText: 'Add an interest',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _primaryCyan,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: _addInterest,
                    ),
                  ),
                ],
              ),
              if (_interests.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _interests.asMap().entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _primaryCyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _primaryCyan, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.value,
                            style: const TextStyle(
                              color: _primaryCyan,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _removeInterest(entry.key),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: _primaryCyan,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),

              // Country Field
              _buildLabel('Country'),
              _buildTextField(
                controller: _countryController,
                hintText: 'Enter your country',
              ),
              const SizedBox(height: 20),

              // Pronouns Field
              _buildLabel('Pronouns'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF3A3A52)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPronoun,
                    isExpanded: true,
                    dropdownColor: _cardBackground,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8B8B9F)),
                    items: ['Do not show', 'She/Her', 'He/Him', 'They/Them']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPronoun = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Student Email Field
              _buildLabel('Student Email'),
              _buildTextField(
                controller: _emailController,
                hintText: 'marvin@email.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Date of Birth Field
              _buildLabel('Date of birth'),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                    controller: _dobController,
                    hintText: 'Select date',
                    suffixIcon: Icons.calendar_today,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Gender Selection
              _buildLabel('Gender'),
              Row(
                children: [
                  Expanded(
                    child: _buildGenderOption(
                      'Male',
                      _selectedGender == 'Male',
                      () => setState(() => _selectedGender = 'Male'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGenderOption(
                      'Female',
                      _selectedGender == 'Female',
                      () => setState(() => _selectedGender = 'Female'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated successfully!')),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryCyan,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Update Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3A3A52)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF8B8B9F),
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: const Color(0xFF8B8B9F), size: 20)
              : null,
        ),
      ),
    );
  }

  Widget _buildGenderOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? _primaryCyan.withOpacity(0.1) : _cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _primaryCyan : const Color(0xFF3A3A52),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? _primaryCyan : const Color(0xFF8B8B9F),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _primaryCyan : Colors.white,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
