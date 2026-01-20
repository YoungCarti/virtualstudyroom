import 'dart:ui';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // --- State Variables ---
  String _selectedLanguage = 'English (US)';
  bool _notifyAssignments = true;
  bool _notifyGroups = true;
  bool _notifyAppUpdates = false;

  // Language Options
  final List<String> _languages = [
    'English (US)',
    'English (UK)',
    'Bahasa Melayu',
    '中文 (简体)',
    '中文 (繁體)',
    '日本語',
    '한국어',
  ];

  @override
  Widget build(BuildContext context) {
    // Define Theme Colors based on your profile page
    final Color topColor = const Color(0xFF0A1929); // Deep Navy
    final Color bottomColor = const Color(0xFF122A46); // Midnight Blue

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [topColor, bottomColor],
              ),
            ),
          ),

          // 2. Ambient Glow Orbs (Visual decorations)
          // 2. Ambient Glow Orbs (Optimized)
          Positioned(
            top: -100,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                     const Color(0xFF2196F3).withValues(alpha: 0.25), // Electric Blue
                     Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4ECDC4).withValues(alpha: 0.2), // Mint Green
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // --- SECTION 1: GENERAL (Language) ---
                _buildSectionHeader("General"),
                _GlassContainer(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.language, color: Colors.white70, size: 22),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                "Language",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // Language Dropdown
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedLanguage,
                                  dropdownColor: const Color(0xFF2d2140), // Dark dropdown bg
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                                  style: const TextStyle(color: Colors.white, fontSize: 14),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() => _selectedLanguage = newValue);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Language set to $_selectedLanguage')),
                                      );
                                    }
                                  },
                                  items: _languages.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- SECTION 2: NOTIFICATIONS ---
                _buildSectionHeader("Notifications"),
                _GlassContainer(
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        title: "Assignment Alerts",
                        subtitle: "Get notified when assignments are posted",
                        icon: Icons.assignment_outlined,
                        value: _notifyAssignments,
                        onChanged: (v) => setState(() => _notifyAssignments = v),
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        title: "Group Messages",
                        subtitle: "Receive messages from your study groups",
                        icon: Icons.groups_outlined,
                        value: _notifyGroups,
                        onChanged: (v) => setState(() => _notifyGroups = v),
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        title: "App Updates",
                        subtitle: "New features and system alerts",
                        icon: Icons.system_update_alt,
                        value: _notifyAppUpdates,
                        onChanged: (v) => setState(() => _notifyAppUpdates = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- SECTION 3: ABOUT ---
                _buildSectionHeader("About"),
                _GlassContainer(
                  child: Column(
                    children: [
                      _buildLinkTile(
                        title: "Terms of Service",
                        icon: Icons.description_outlined,
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _buildLinkTile(
                        title: "App Version",
                        trailing: "v1.0.0",
                        icon: Icons.info_outline,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4ECDC4), // Mint Green
            activeTrackColor: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
            inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
            inactiveThumbColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required String title,
    required IconData icon,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.3),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Colors.white.withValues(alpha: 0.1),
      indent: 54, // Match icon padding + size
    );
  }
}

// Reusable Glass Container
class _GlassContainer extends StatelessWidget {
  final Widget child;

  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF122A46).withValues(alpha: 0.5), // Midnight Blue semi-transparent
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}