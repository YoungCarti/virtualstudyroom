import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'edit_profile_page.dart';

const Color _limeGreen = Color(0xFFB8E986);
const Color _darkBackground = Color(0xFF1C1C28);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return Scaffold(
        backgroundColor: _darkBackground,
        body: const Center(
          child: Text('Not signed in', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(_uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: _darkBackground,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snap.hasData || !snap.data!.exists) {
          return Scaffold(
            backgroundColor: _darkBackground,
            body: const Center(
              child: Text('Profile not found', style: TextStyle(color: Colors.white)),
            ),
          );
        }

        final data = snap.data!.data()!;
        // Prefer fullName field; fallback to legacy name
        final fullName = (data['fullName'] ?? data['name'] ?? 'Unnamed') as String;
        final email = (data['email'] ?? '') as String;
        final role = (data['role'] ?? 'student') as String;
        final program = (data['program'] ?? '') as String;
        final studentID = (data['studentID'] ?? '') as String;
        final enrolled = List<String>.from(data['enrolledClasses'] ?? <dynamic>[]);

        final initials = fullName.trim().isEmpty
            ? '?'
            : fullName.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').join().toUpperCase();

        return Scaffold(
          backgroundColor: _darkBackground,
          body: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 60),
                decoration: const BoxDecoration(
                  color: _limeGreen,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF2A2A3E)),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Color(0xFF2A2A3E)),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => EditProfilePage(userDocId: _uid),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: _limeGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF2A2A3E),
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Color(0xFF2A2A3E),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      role,
                      style: const TextStyle(color: Color(0xFF2A2A3E), fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${initials})',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Enrolled Classes',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (enrolled.isEmpty)
                        const Text('No enrolled classes', style: TextStyle(color: Colors.white54))
                      else
                        Wrap(
                          spacing: 8,
                          children: enrolled.map((c) {
                            return Chip(
                              label: Text(c),
                              backgroundColor: const Color(0xFF2D3250),
                              labelStyle: const TextStyle(color: Colors.white),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 24),
                      const Text('Academic Information', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (role == 'student') ...[
                        _InfoItem(label: 'Program', value: program.isEmpty ? 'Not set' : program),
                        const SizedBox(height: 12),
                        _InfoItem(label: 'Student ID', value: studentID.isEmpty ? 'Not set' : studentID),
                      ] else ...[
                        _InfoItem(label: 'Role', value: role),
                      ],
                      const SizedBox(height: 24),
                      const Text('Other info', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _InfoItem(label: 'Email', value: email),
                      const SizedBox(height: 12),
                      _InfoItem(label: 'Joined', value: _formatCreatedAt(data['createdAt'])),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatCreatedAt(dynamic ts) {
    try {
      if (ts is Timestamp) {
        final dt = ts.toDate();
        return '${dt.month}/${dt.day}/${dt.year}';
      }
      return 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
