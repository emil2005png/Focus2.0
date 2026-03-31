import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:focus_app/services/points_service.dart';
import 'package:focus_app/models/vision_board_task.dart';
import 'package:focus_app/widgets/glass_container.dart';
import 'package:focus_app/widgets/fade_in_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VisionBoardScreen extends StatefulWidget {
  const VisionBoardScreen({super.key});

  @override
  State<VisionBoardScreen> createState() => _VisionBoardScreenState();
}

class _VisionBoardScreenState extends State<VisionBoardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final PointsService _pointsService = PointsService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        await _firestoreService.uploadVisionBoardImage(File(image.path));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vision Board updated!')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: GlassContainer(
          color: Colors.white,
          opacity: 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Vision Goal',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final newTask = VisionBoardTask(
                        id: '',
                        title: titleController.text,
                        description: descController.text,
                        createdAt: DateTime.now(),
                      );
                      _firestoreService.addVisionBoardTask(newTask);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Goal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleTask(VisionBoardTask task) async {
    final updatedTask = VisionBoardTask(
      id: task.id,
      title: task.title,
      description: task.description,
      createdAt: task.createdAt,
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );
    await _firestoreService.updateVisionBoardTask(updatedTask);

    if (updatedTask.isCompleted) {
      try {
        final rewards = await _pointsService.awardTaskCompletion();
        if (!mounted) return;
        _showRewardFeedback(rewards['points'] as int? ?? 0, rewards['bonus'] as int? ?? 0);
      } catch (e) {
        debugPrint('Failed to award points: \$e');
      }
    }
  }

  void _showRewardFeedback(int points, int bonus) {
    String message = '+$points points awarded!';
    if (bonus > 0) {
      message += '\nDAILY BONUS: +$bonus points! 🎉';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show bottom sheet to edit an existing vision board task
  void _showEditTaskSheet(VisionBoardTask task) {
    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: GlassContainer(
          color: Colors.white,
          opacity: 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Vision Goal',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      final updatedTask = task.copyWith(
                        title: titleController.text,
                        description: descController.text,
                      );
                      _firestoreService.updateVisionBoardTask(updatedTask);
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Delete a vision board task with confirmation
  Future<void> _deleteTask(VisionBoardTask task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestoreService.deleteVisionBoardTask(task.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Vision Board', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Top Vision Image Section
                StreamBuilder<DocumentSnapshot>(
                  stream: _firestoreService.getUserProfile(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final imageUrl = data?['visionBoardUrl'] as String?;

                    return Container(
                      height: 350,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        image: imageUrl != null && imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: imageUrl.startsWith('http') 
                                  ? NetworkImage(imageUrl) as ImageProvider
                                  : FileImage(File(imageUrl)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageUrl == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Upload your vision\nto stay motivated!',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : null,
                    );
                  },
                ),
                // Edit button overlay
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: _isUploading
                      ? const CircularProgressIndicator()
                      : FloatingActionButton.small(
                          onPressed: _pickImage,
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          child: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
                        ),
                ),
              ],
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Vision Goals',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StreamBuilder<int>(
                        stream: _pointsService.getTotalPointsStream(),
                        builder: (context, snapshot) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '${snapshot.data ?? 0} pts',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber[800],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          StreamBuilder<List<VisionBoardTask>>(
            stream: _firestoreService.getVisionBoardTasks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              }
              
              final tasks = snapshot.data ?? [];
              
              if (tasks.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No tasks yet.\nAdd one to start earning points!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final task = tasks[index];
                    return FadeInAnimation(
                      delay: Duration(milliseconds: 50 * index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: _buildTaskCard(task),
                      ),
                    );
                  },
                  childCount: tasks.length,
                ),
              );
            },
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskSheet,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTaskCard(VisionBoardTask task) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        await _deleteTask(task);
        return false; // Firestore stream handles removal
      },
      child: GlassContainer(
        color: Colors.white,
        opacity: 0.8,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (_) => _toggleTask(task),
              activeColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      color: task.isCompleted ? Colors.grey : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (task.description != null && task.description!.isNotEmpty)
                    Text(
                      task.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                ],
              ),
            ),
            if (task.isCompleted)
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
            else
              IconButton(
                icon: Icon(Icons.edit_outlined, color: Colors.grey[400], size: 20),
                onPressed: () => _showEditTaskSheet(task),
              ),
          ],
        ),
      ),
    );
  }
}
