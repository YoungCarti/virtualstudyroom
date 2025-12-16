import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class Assignment {
  final String id;
  final String classCode;
  final String className;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime createdAt;
  final String createdBy;
  final String? attachmentUrl;
  final String? attachmentName;
  final String submissionType; // 'individual' or 'group'

  Assignment({
    required this.id,
    required this.classCode,
    required this.className,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.createdAt,
    required this.createdBy,
    this.attachmentUrl,
    this.attachmentName,
    this.submissionType = 'individual',
  });

  factory Assignment.fromFirestore(DocumentSnapshot doc, String classCode, {String className = ''}) {
    final data = doc.data() as Map<String, dynamic>;
    return Assignment(
      id: doc.id,
      classCode: classCode,
      className: className,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      attachmentUrl: data['attachmentUrl'],
      attachmentName: data['attachmentName'],
      submissionType: data['submissionType'] ?? 'individual',
    );
  }
}

class AssignmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Singleton pattern
  AssignmentService._privateConstructor();
  static final AssignmentService instance = AssignmentService._privateConstructor();

  // Create assignment with optional file attachment
  Future<void> createAssignment({
    required String classCode,
    required String title,
    required String description,
    required DateTime dueDate,
    required String createdBy,
    File? file, // Mobile file
    Uint8List? fileBytes, // Web file bytes
    String? fileName,
    String submissionType = 'individual',
  }) async {
    String? attachmentUrl;

    // Upload file if provided
    if (fileName != null && (file != null || fileBytes != null)) {
      try {
        final storageRef = _storage
            .ref()
            .child('classes/$classCode/assignments/${DateTime.now().millisecondsSinceEpoch}_$fileName');
        
        if (kIsWeb && fileBytes != null) {
          await storageRef.putData(fileBytes);
        } else if (file != null) {
          await storageRef.putFile(file);
        }
        
        attachmentUrl = await storageRef.getDownloadURL();
      } catch (e) {
        print('Error uploading file: $e');
        rethrow;
      }
    }

    // Create assignment document
    await _firestore
        .collection('classes')
        .doc(classCode)
        .collection('assignments')
        .add({
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': createdBy,
      'attachmentUrl': attachmentUrl,
      'attachmentName': fileName,
      'submissionType': submissionType,
    });
  }

  // Fetch upcoming assignments for a list of enrolled classes
  Future<List<Assignment>> getUpcomingAssignments(List<String> classCodes) async {
    if (classCodes.isEmpty) return [];

    List<Assignment> allAssignments = [];
    final now = DateTime.now();
    
    for (final code in classCodes) {
      try {
        // Fetch class name first
        final classDoc = await _firestore.collection('classes').doc(code).get();
        final className = classDoc.data()?['className'] ?? code;

        final querySnapshot = await _firestore
            .collection('classes')
            .doc(code)
            .collection('assignments')
            .where('dueDate', isGreaterThan: Timestamp.fromDate(now))
            .get();

        final assignments = querySnapshot.docs
            .map((doc) => Assignment.fromFirestore(doc, code, className: className))
            .toList();
        
        allAssignments.addAll(assignments);
      } catch (e) {
        print('Error fetching assignments for class $code: $e');
      }
    }

    // Sort by due date ascending
    allAssignments.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Return top 5
    return allAssignments.take(5).toList();
  }

  // Stream of assignments for a specific class
  Stream<List<Assignment>> getAssignmentsForClass(String classCode) {
    return _firestore
        .collection('classes')
        .doc(classCode)
        .collection('assignments')
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Assignment.fromFirestore(doc, classCode))
          .toList();
    });
  }

  // Get student's group for a class
  Future<Map<String, String>?> getStudentGroup(String classCode, String uid) async {
    try {
      final querySnapshot = await _firestore
          .collection('classes')
          .doc(classCode)
          .collection('groups')
          .where('members', arrayContains: uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return {
          'groupId': doc.id,
          'groupName': doc.data()['groupName'] ?? 'Unknown Group',
        };
      }
      return null;
    } catch (e) {
      print('Error fetching student group: $e');
      return null;
    }
  }

  // Submit assignment
  Future<void> submitAssignment({
    required String classCode,
    required String assignmentId,
    required String studentId,
    required String studentName,
    File? file,
    Uint8List? fileBytes,
    String? fileName,
    String? groupId, // Optional, for group submissions
    String? groupName, // Optional
  }) async {
    String? attachmentUrl;

    if (fileName != null && (file != null || fileBytes != null)) {
      try {
        final storageRef = _storage.ref().child(
            'classes/$classCode/assignments/$assignmentId/submissions/${DateTime.now().millisecondsSinceEpoch}_$fileName');

        if (kIsWeb && fileBytes != null) {
          await storageRef.putData(fileBytes);
        } else if (file != null) {
          await storageRef.putFile(file);
        }

        attachmentUrl = await storageRef.getDownloadURL();
      } catch (e) {
        print('Error uploading submission file: $e');
        rethrow;
      }
    }

    // Determine document ID: groupId if provided, else studentId
    final submissionId = groupId ?? studentId;

    await _firestore
        .collection('classes')
        .doc(classCode)
        .collection('assignments')
        .doc(assignmentId)
        .collection('submissions')
        .doc(submissionId)
        .set({
      'studentId': studentId,
      'studentName': studentName,
      'groupId': groupId,
      'groupName': groupName,
      'attachmentUrl': attachmentUrl,
      'attachmentName': fileName,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get single submission (by studentId or groupId)
  Stream<Submission?> getSubmission(
      String classCode, String assignmentId, String submissionId) {
    return _firestore
        .collection('classes')
        .doc(classCode)
        .collection('assignments')
        .doc(assignmentId)
        .collection('submissions')
        .doc(submissionId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Submission.fromFirestore(doc);
    });
  }

  // Get all submissions for an assignment (Lecturer only)
  Stream<List<Submission>> getSubmissions(String classCode, String assignmentId) {
    return _firestore
        .collection('classes')
        .doc(classCode)
        .collection('assignments')
        .doc(assignmentId)
        .collection('submissions')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Submission.fromFirestore(doc)).toList();
    });
  }
  // Delete assignment
  Future<void> deleteAssignment(String classCode, String assignmentId) async {
    try {
      // Delete assignment document
      await _firestore
          .collection('classes')
          .doc(classCode)
          .collection('assignments')
          .doc(assignmentId)
          .delete();
      
      // Note: This does not delete the subcollections (submissions) or the file from Storage.
      // In a production app, you'd want to use Cloud Functions to handle recursive deletion
      // or manually delete them here. For this demo, deleting the doc is sufficient to hide it.
    } catch (e) {
      print('Error deleting assignment: $e');
      rethrow;
    }
  }

  // Update assignment
  Future<void> updateAssignment({
    required String classCode,
    required String assignmentId,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    try {
      await _firestore
          .collection('classes')
          .doc(classCode)
          .collection('assignments')
          .doc(assignmentId)
          .update({
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
      });
    } catch (e) {
      print('Error updating assignment: $e');
      rethrow;
    }
  }
}

class Submission {
  final String studentId;
  final String studentName;
  final String? groupId;
  final String? groupName;
  final String? attachmentUrl;
  final String? attachmentName;
  final DateTime? submittedAt;

  Submission({
    required this.studentId,
    required this.studentName,
    this.groupId,
    this.groupName,
    this.attachmentUrl,
    this.attachmentName,
    this.submittedAt,
  });

  factory Submission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Submission(
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Unknown',
      groupId: data['groupId'],
      groupName: data['groupName'],
      attachmentUrl: data['attachmentUrl'],
      attachmentName: data['attachmentName'],
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
    );
  }
}
