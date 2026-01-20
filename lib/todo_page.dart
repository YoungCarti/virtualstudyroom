import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'app_fonts.dart';

class ToDoPage extends StatefulWidget {
  const ToDoPage({super.key});

  @override
  State<ToDoPage> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  void _showAddToDoPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddToDoPage(
          uid: uid,
          onAddTask: _addTask,
        ),
      ),
    );
  }

  void _addTask(String title, String description, String? descriptionBottom, DateTime? dueDate, TimeOfDay? dueTime, int priority, String? imageUrl) async {
    if (uid == null) return;
    
    final data = <String, dynamic>{
      'task': title,
      'description': description,
      'descriptionBottom': descriptionBottom,
      'isCompleted': false,
      'priority': priority,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (dueDate != null) {
      DateTime finalDateTime = dueDate;
      if (dueTime != null) {
        finalDateTime = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          dueTime.hour,
          dueTime.minute,
        );
      }
      data['dueDate'] = Timestamp.fromDate(finalDateTime);
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('todos')
        .add(data);
  }

  void _updateTask(String docId, String title, String description, String? descriptionBottom, DateTime? dueDate, TimeOfDay? dueTime, int priority, String? imageUrl) {
    if (uid == null) return;

    final data = <String, dynamic>{
      'task': title,
      'description': description,
      'descriptionBottom': descriptionBottom,
      'priority': priority,
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (dueDate != null) {
      DateTime finalDateTime = dueDate;
      if (dueTime != null) {
        finalDateTime = DateTime(
          dueDate.year,
          dueDate.month,
          dueDate.day,
          dueTime.hour,
          dueTime.minute,
        );
      }
      data['dueDate'] = Timestamp.fromDate(finalDateTime);
    } else {
      data['dueDate'] = null;
    }

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('todos')
        .doc(docId)
        .update(data);
  }

  void _navigateToEditTask(Map<String, dynamic> data, String docId) {
    final title = data['task'] ?? '';
    final description = data['description'] ?? '';
    final descriptionBottom = data['descriptionBottom'] as String?;
    final priority = data['priority'] as int? ?? 0;
    final imageUrl = data['imageUrl'] as String?;
    
    DateTime? dueDate;
    TimeOfDay? dueTime;
    
    if (data['dueDate'] != null) {
      final timestamp = data['dueDate'] as Timestamp;
      final dt = timestamp.toDate();
      dueDate = DateTime(dt.year, dt.month, dt.day);
      dueTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      
      // If time is 00:00 and wasn't explicitly set (simplification), treat as no time
      // But for now, we pass it as is.
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddToDoPage(
          uid: uid,
          onAddTask: (t, d, dB, date, time, p, img) => _updateTask(docId, t, d, dB, date, time, p, img),
          initialTitle: title,
          initialDescription: description,
          initialDescriptionBottom: descriptionBottom,
          initialDate: dueDate,
          initialTime: dueTime,
          initialPriority: priority,
          initialImageUrl: imageUrl,
          isEditing: true,
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1: return const Color(0xFF2196F3);  // Low - Blue
      case 2: return const Color(0xFFFF9800);  // Medium - Orange
      case 3: return const Color(0xFFE53935);  // High - Red
      default: return Colors.grey;
    }
  }

  void _toggleTask(String taskId, bool currentStatus) {
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('todos')
        .doc(taskId)
        .update({'isCompleted': !currentStatus});
  }

  void _deleteTask(String taskId) {
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('todos')
        .doc(taskId)
        .delete();
  }

  String _formatDueDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today ${DateFormat('h:mm a').format(date)}';
    } else if (taskDate == tomorrow) {
      return 'Tomorrow ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My To-Do List',
          style: AppFonts.clashGrotesk(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: uid == null
            ? const Stream.empty()
            : FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('todos')
                .orderBy('createdAt', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading tasks',
                style: TextStyle(color: Colors.red.withValues(alpha: 0.7)),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!.docs;

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.clipboardList,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tasks yet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first task',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.2),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final data = task.data() as Map<String, dynamic>;
              final isCompleted = data['isCompleted'] ?? false;
              final title = data['task'] ?? '';
              final description = data['description'] ?? '';
              final dueDate = data['dueDate'] as Timestamp?;
              final priority = data['priority'] as int? ?? 0;
              final imageUrl = data['imageUrl'] as String?;

              return Dismissible(
                key: Key(task.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteTask(task.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(LucideIcons.trash2, color: Colors.red),
                ),
                child: GestureDetector(
                  onTap: () => _navigateToEditTask(data, task.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCompleted
                            ? const Color(0xFF4ECDC4).withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Checkbox
                        GestureDetector(
                          onTap: () => _toggleTask(task.id, isCompleted),
                          child: Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: isCompleted
                                  ? const Color(0xFF4ECDC4)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isCompleted
                                    ? const Color(0xFF4ECDC4)
                                    : Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: isCompleted
                                ? const Icon(LucideIcons.check,
                                    size: 14, color: Colors.black)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  color: isCompleted
                                      ? Colors.white.withValues(alpha: 0.3)
                                      : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor:
                                      Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              if (description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  description,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (dueDate != null || priority > 0 || imageUrl != null) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    if (priority > 0) ...[
                                      Icon(
                                        LucideIcons.flag,
                                        size: 12,
                                        color: _getPriorityColor(priority),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    if (dueDate != null) ...[
                                      if (priority > 0) const SizedBox(width: 8),
                                      Icon(
                                        LucideIcons.calendar,
                                        size: 12,
                                        color: const Color(0xFF2196F3),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDueDate(dueDate),
                                        style: const TextStyle(
                                          color: Color(0xFF2196F3),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                      if (dueDate != null || priority > 0) const SizedBox(width: 8),
                                      const Icon(
                                        LucideIcons.image,
                                        size: 12,
                                        color: Color(0xFF4ECDC4),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Menu icon
                        Icon(
                          LucideIcons.moreVertical,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddToDoPage,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }
}

// Full page for adding a new task
class AddToDoPage extends StatefulWidget {
  final String? uid;
  final void Function(String title, String description, String? descriptionBottom, DateTime? dueDate, TimeOfDay? dueTime, int priority, String? imageUrl) onAddTask;
  
  final String? initialTitle;
  final String? initialDescription;
  final String? initialDescriptionBottom;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final int initialPriority;
  final String? initialImageUrl;
  final bool isEditing;

  const AddToDoPage({
    super.key, 
    required this.uid, 
    required this.onAddTask,
    this.initialTitle,
    this.initialDescription,
    this.initialDescriptionBottom,
    this.initialDate,
    this.initialTime,
    this.initialPriority = 0,
    this.initialImageUrl,
    this.isEditing = false,
  });

  @override
  State<AddToDoPage> createState() => _AddToDoPageState();
}

class _AddToDoPageState extends State<AddToDoPage> {
  late TextEditingController titleController;
  late TextEditingController descController;
  late TextEditingController descBottomController;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int selectedPriority = 0; 
  XFile? selectedImage;
  String? existingImageUrl;
  bool isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.initialTitle);
    descController = TextEditingController(text: widget.initialDescription);
    descBottomController = TextEditingController(text: widget.initialDescriptionBottom);
    selectedDate = widget.initialDate;
    selectedTime = widget.initialTime;
    selectedPriority = widget.initialPriority;
    existingImageUrl = widget.initialImageUrl;
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    descBottomController.dispose();
    super.dispose();
  }

  static const priorityColors = [
    Colors.grey,        // No priority
    Color(0xFF2196F3),  // Low - Blue
    Color(0xFFFF9800),  // Medium - Orange
    Color(0xFFE53935),  // High - Red
  ];



  void _showDatePickerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DatePickerSheet(
        selectedDate: selectedDate,
        selectedTime: selectedTime,
        onDateSelected: (date, time) {
          setState(() {
            selectedDate = date;
            selectedTime = time;
          });
        },
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (selectedImage == null || widget.uid == null) return null;
    
    setState(() => isUploadingImage = true);
    
    try {
      final bytes = await selectedImage!.readAsBytes();
      final ref = FirebaseStorage.instance
          .ref()
          .child('todo_images')
          .child(widget.uid!)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    } finally {
      if (mounted) setState(() => isUploadingImage = false);
    }
  }

  // Helper to remove existing image
  void _removeImage() {
    // When removing image, merge bottom description into main description
    if (descBottomController.text.isNotEmpty) {
      final sep = descController.text.isNotEmpty ? '\n\n' : '';
      descController.text = '${descController.text}$sep${descBottomController.text}';
      descBottomController.clear();
    }
    
    setState(() {
      selectedImage = null;
      existingImageUrl = null;
    });
  }

  String _getDateLabel() {
    if (selectedDate == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);

    String dateStr;
    if (taskDate == today) {
      dateStr = 'Today';
    } else if (taskDate == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = DateFormat('MMM d').format(selectedDate!);
    }

    if (selectedTime != null) {
      dateStr += ' ${selectedTime!.format(context)}';
    }
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEditing ? 'Edit Task' : 'Add Task',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Title Input
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'What would you like to do?',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
                
                const SizedBox(height: 16),

                // Description Input (Top)
                TextField(
                  controller: descController,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
                
                if (selectedImage != null || existingImageUrl != null) ...[
                   const SizedBox(height: 16),
                   Stack(
                     children: [
                       ClipRRect(
                         borderRadius: BorderRadius.circular(12),
                         child: selectedImage != null 
                             ? Image.file(
                                 File(selectedImage!.path), 
                                 width: double.infinity,
                                 height: 200,
                                 fit: BoxFit.cover,
                               )
                             : Image.network(
                                 existingImageUrl!,
                                 width: double.infinity,
                                 height: 200,
                                 fit: BoxFit.cover,
                                 errorBuilder: (context, error, stackTrace) => Container(
                                   height: 200,
                                   color: Colors.white.withValues(alpha: 0.1),
                                   alignment: Alignment.center,
                                   child: const Icon(LucideIcons.imageOff, color: Colors.white),
                                 ),
                               ),
                       ),
                       Positioned(
                         top: 8,
                         right: 8,
                         child: GestureDetector(
                           onTap: _removeImage,
                           child: Container(
                             padding: const EdgeInsets.all(6),
                             decoration: const BoxDecoration(
                               color: Colors.black54,
                               shape: BoxShape.circle,
                             ),
                             child: const Icon(LucideIcons.x, size: 16, color: Colors.white),
                           ),
                         ),
                       ),
                     ],
                   ),
                   
                   const SizedBox(height: 16),
                   
                   // Description Input Bottom (Only if image exists)
                   TextField(
                     controller: descBottomController,
                     style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
                     decoration: InputDecoration(
                       hintText: 'Description below image (optional)',
                       hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                       border: InputBorder.none,
                     ),
                     maxLines: null,
                   ),
                ],

              ],
            ),
          ),
          
          // Bottom Toolbar
          Container(
            padding: EdgeInsets.only(
              left: 16, 
              right: 16, 
              top: 12, 
              bottom: 12 + MediaQuery.of(context).padding.bottom
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                // Calendar Icon
                GestureDetector(
                  onTap: _showDatePickerModal,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selectedDate != null
                          ? const Color(0xFF2196F3).withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.calendar,
                      size: 24,
                      color: selectedDate != null
                          ? const Color(0xFF2196F3)
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                if (selectedDate != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getDateLabel(),
                          style: const TextStyle(
                            color: Color(0xFF2196F3),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() {
                            selectedDate = null;
                            selectedTime = null;
                          }),
                          child: const Icon(
                            LucideIcons.x,
                            size: 14,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                // Flag Icon for Priority
                PopupMenuButton<int>(
                  offset: const Offset(0, -200),
                  color: const Color(0xFF252540),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    setState(() {
                      selectedPriority = value;
                    });
                  },
                  itemBuilder: (context) => [
                    _buildPriorityMenuItem(3, 'High Priority', const Color(0xFFE53935)),
                    _buildPriorityMenuItem(2, 'Medium Priority', const Color(0xFFFF9800)),
                    _buildPriorityMenuItem(1, 'Low Priority', const Color(0xFF2196F3)),
                    _buildPriorityMenuItem(0, 'No Priority', Colors.grey),
                  ],
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selectedPriority > 0
                          ? priorityColors[selectedPriority].withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.flag,
                      size: 24,
                      color: selectedPriority > 0
                          ? priorityColors[selectedPriority]
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                // Image Icon
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: selectedImage != null || existingImageUrl != null
                          ? const Color(0xFF4ECDC4).withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.image,
                      size: 24,
                      color: selectedImage != null || existingImageUrl != null
                          ? const Color(0xFF4ECDC4)
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                
                const SizedBox(width: 8),
                // Checklist Icon
                GestureDetector(
                  onTap: () {
                    // Check which controller has focus or default to top
                    // Simple logic: if image is present and bottom has focus or is empty?
                    // Let's just append to top for now, or determining focus is hard without FocusNodes.
                    // Improving: Check if bottom text is not empty? 
                    // Let's just add to descController (top) for simplicity as user requested "below image" typing.
                    // Actually, if user taps below image, they might want bullet there.
                    // But without FocusNode tracking, we default to the top one or bottom one? 
                    // Let's default to the Top one as it's the primary description.
                    
                    final controller = (selectedImage != null || existingImageUrl != null) && descBottomController.text.isNotEmpty
                        ? descBottomController
                        : descController;
                        
                    final text = controller.text;
                    final newText = text.isEmpty 
                        ? '○ ' 
                        : text.endsWith('\n') 
                        ? '$text○ ' 
                            : '$text\n○ ';
                    controller.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: newText.length),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.checkCircle2,
                      size: 24,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Send Button
                GestureDetector(
                  onTap: isUploadingImage
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty || widget.uid == null) {
                            Navigator.pop(context);
                            return;
                          }
                          
                          String? imageUrl = existingImageUrl;
                          if (selectedImage != null) {
                            imageUrl = await _uploadImage();
                          }
                          
                          widget.onAddTask(
                            titleController.text.trim(),
                            descController.text.trim(),
                            (selectedImage != null || existingImageUrl != null) ? descBottomController.text.trim() : null,
                            selectedDate,
                            selectedTime,
                            selectedPriority,
                            imageUrl,
                          );
                          if (context.mounted) Navigator.pop(context);
                        },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: isUploadingImage
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(LucideIcons.send, size: 24, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<int> _buildPriorityMenuItem(int value, String label, Color color) {
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [
          Icon(LucideIcons.flag, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// Date Picker Sheet
class _DatePickerSheet extends StatefulWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final void Function(DateTime? date, TimeOfDay? time) onDateSelected;

  const _DatePickerSheet({
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateSelected,
  });

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDate = widget.selectedDate;
    _selectedTime = widget.selectedTime;
    _currentMonth = _selectedDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime _getNextMonday() {
    final now = DateTime.now();
    int daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    if (daysUntilMonday == 0) daysUntilMonday = 7;
    return DateTime(now.year, now.month, now.day + daysUntilMonday);
  }

  void _selectQuickDate(DateTime date, {TimeOfDay? time}) {
    setState(() {
      _selectedDate = date;
      _selectedTime = time;
      _currentMonth = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextMonday = _getNextMonday();

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, color: Colors.white),
                ),
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF2196F3),
                    labelColor: const Color(0xFF2196F3),
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
                    tabs: const [
                      Tab(text: 'Date'),
                      Tab(text: 'Time'),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    widget.onDateSelected(_selectedDate, _selectedTime);
                    Navigator.pop(context);
                  },
                  icon: const Icon(LucideIcons.check, color: Color(0xFF2196F3)),
                ),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Date Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Quick Options
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _QuickDateOption(
                            icon: Icons.today,
                            label: 'Today',
                            date: today,
                            isSelected: _selectedDate != null &&
                                DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day) == today,
                            onTap: () => _selectQuickDate(today),
                          ),
                          _QuickDateOption(
                            icon: Icons.wb_twilight,
                            label: 'Tomorrow',
                            date: tomorrow,
                            isSelected: _selectedDate != null &&
                                DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day) == tomorrow,
                            onTap: () => _selectQuickDate(tomorrow),
                          ),
                          _QuickDateOption(
                            icon: Icons.calendar_month,
                            label: 'Next Monday',
                            date: nextMonday,
                            isSelected: _selectedDate != null &&
                                DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day) == nextMonday,
                            onTap: () => _selectQuickDate(nextMonday),
                          ),
                          _QuickDateOption(
                            icon: Icons.wb_sunny,
                            label: 'Today\nMorning',
                            date: today,
                            isSelected: _selectedDate != null &&
                                DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day) == today &&
                                _selectedTime?.hour == 9,
                            onTap: () => _selectQuickDate(today, time: const TimeOfDay(hour: 9, minute: 0)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Calendar Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('MMMM').format(_currentMonth),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                                  });
                                },
                                icon: Icon(LucideIcons.chevronLeft,
                                    color: Colors.white.withValues(alpha: 0.5)),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                                  });
                                },
                                icon: Icon(LucideIcons.chevronRight,
                                    color: Colors.white.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Weekday Headers
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                              .map((day) => Expanded(
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),

                      // Calendar Grid
                      _buildCalendarGrid(),
                    ],
                  ),
                ),

                // Time Tab
                _buildTimePicker(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final startWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    List<Widget> dayWidgets = [];

    // Empty cells before first day
    for (int i = 1; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isSelected = _selectedDate != null &&
          DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day) == date;
      final isToday = date == todayDate;

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : isToday
                          ? const Color(0xFF2196F3)
                          : Colors.white.withValues(alpha: 0.7),
                  fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  Widget _buildTimePicker() {
    final times = <TimeOfDay>[
      const TimeOfDay(hour: 6, minute: 0),
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 12, minute: 0),
      const TimeOfDay(hour: 15, minute: 0),
      const TimeOfDay(hour: 18, minute: 0),
      const TimeOfDay(hour: 21, minute: 0),
    ];

    final labels = ['6 AM', '9 AM', '12 PM', '3 PM', '6 PM', '9 PM'];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Times',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(times.length, (index) {
              final isSelected = _selectedTime == times[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTime = times[index];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF2196F3)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF2196F3)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          // Custom Time Button
          GestureDetector(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime ?? TimeOfDay.now(),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color(0xFF2196F3),
                        surface: Color(0xFF1A1A2E),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                setState(() {
                  _selectedTime = time;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.clock, color: Color(0xFF2196F3)),
                  const SizedBox(width: 12),
                  Text(
                    _selectedTime != null
                        ? 'Selected: ${_selectedTime!.format(context)}'
                        : 'Choose custom time',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickDateOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickDateOption({
    required this.icon,
    required this.label,
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2196F3)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF2196F3)
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF2196F3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
