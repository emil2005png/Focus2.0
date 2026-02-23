import 'dart:async';
import 'package:flutter/material.dart';
import 'package:focus_app/models/daily_plan.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/glass_container.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/services/notification_service.dart';
import 'package:intl/intl.dart';

class DailyPlanningWidget extends StatefulWidget {
  const DailyPlanningWidget({super.key});

  @override
  State<DailyPlanningWidget> createState() => _DailyPlanningWidgetState();
}

class _DailyPlanningWidgetState extends State<DailyPlanningWidget> {
  final FirestoreService _firestoreService = FirestoreService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update UI every minute to keep "remaining time" accurate
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showPlanningSheet(BuildContext context, DailyPlan? existingPlan) {
    // Initialize temporary state for the sheet
    // We use a List of Maps to hold controller and metadata for each task
    List<Map<String, dynamic>> _tempTasks = [];

    if (existingPlan != null && existingPlan.tasks.isNotEmpty) {
      for (var task in existingPlan.tasks) {
        DateTime? deadline;
        if (task['deadline'] != null) {
          deadline = DateTime.tryParse(task['deadline'].toString());
        }

        _tempTasks.add({
          'controller': TextEditingController(text: task['title']),
          'deadline': deadline,
          'isCompleted': task['isCompleted'] ?? false,
          'key': UniqueKey(), // Stable key for reordering
        });
      }
    } else {
      // Default to 1 empty task if no plan
       _tempTasks.add({
          'controller': TextEditingController(),
          'deadline': null,
          'isCompleted': false,
          'key': UniqueKey(),
        });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85, // Taller sheet
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Plan Your Day 🎯',
                      style: GoogleFonts.outfit(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('Drag to prioritize. Swipe to remove.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  const SizedBox(height: 16),
                  
                  // Task List
                  Expanded(
                    child: ReorderableListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      onReorder: (oldIndex, newIndex) {
                        setSheetState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          final item = _tempTasks.removeAt(oldIndex);
                          _tempTasks.insert(newIndex, item);
                        });
                      },
                      children: [
                        for (int index = 0; index < _tempTasks.length; index++)
                          Container(
                            key: _tempTasks[index]['key'],
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_indicator_rounded, color: Colors.grey),
                              ),
                              title: TextField(
                                controller: _tempTasks[index]['controller'],
                                decoration: const InputDecoration(
                                  hintText: 'What needs to be done?',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: GoogleFonts.outfit(fontSize: 16),
                                textCapitalization: TextCapitalization.sentences,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Deadline Picker
                                  IconButton(
                                    icon: Icon(
                                      Icons.calendar_today_rounded,
                                      color: _tempTasks[index]['deadline'] != null 
                                          ? Colors.indigo 
                                          : Colors.grey[400],
                                      size: 20,
                                    ),
                                    onPressed: () async {
                                        final now = DateTime.now();
                                        final initialDate = _tempTasks[index]['deadline'] ?? now;
                                        
                                        final DateTime? pickedDate = await showDatePicker(
                                          context: context,
                                          initialDate: initialDate,
                                          firstDate: now.subtract(const Duration(days: 1)),
                                          lastDate: now.add(const Duration(days: 365)),
                                        );
                                        
                                        if (pickedDate != null) {
                                            TimeOfDay initialTime = TimeOfDay.fromDateTime(initialDate);
                                            if (context.mounted) {
                                                final TimeOfDay? pickedTime = await showTimePicker(
                                                    context: context,
                                                    initialTime: initialTime,
                                                );
                                                
                                                if (pickedTime != null) {
                                                    setSheetState(() {
                                                        _tempTasks[index]['deadline'] = DateTime(
                                                            pickedDate.year,
                                                            pickedDate.month,
                                                            pickedDate.day,
                                                            pickedTime.hour,
                                                            pickedTime.minute,
                                                        );
                                                    });
                                                }
                                            }
                                        }
                                    },
                                  ),
                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                                    onPressed: () {
                                      setSheetState(() {
                                        _tempTasks.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Actions
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                    child: Column(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setSheetState(() {
                              _tempTasks.add({
                                'controller': TextEditingController(),
                                'deadline': null,
                                'isCompleted': false,
                                'key': UniqueKey(),
                              });
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add Task"),
                          style: OutlinedButton.styleFrom(
                             minimumSize: const Size(double.infinity, 50),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final notificationService = NotificationService();
                            List<Map<String, dynamic>> newTasks = [];
                            List<String> validPriorities = [];
                            
                            // Re-schedule notifications logic could be smarter, 
                            // but for now we wipe and recreate based on new list to ensure sync.
                            // In a real app we might track IDs more persistently.
                            // Here we assume IDs 100... onwards.
                            // First, cancel a reasonable range or track them. 
                            // For simplicity, we just cancel 100-120.
                             for(int i=0; i<20; i++) {
                                 await notificationService.cancel(100 + i);
                             }

                            for (int i = 0; i < _tempTasks.length; i++) {
                                String title = _tempTasks[i]['controller'].text.trim();
                                if (title.isNotEmpty) {
                                    validPriorities.add(title);
                                    
                                    Map<String, dynamic> taskMap = {
                                        'title': title,
                                        'isCompleted': _tempTasks[i]['isCompleted'],
                                    };
                                    
                                    if (_tempTasks[i]['deadline'] != null) {
                                        DateTime d = _tempTasks[i]['deadline'];
                                        taskMap['deadline'] = d.toIso8601String();
                                        
                                        if (_tempTasks[i]['isCompleted'] != true && d.isAfter(DateTime.now())) {
                                            await notificationService.scheduleTaskReminder(100 + i, title, d);
                                        }
                                    }
                                    
                                    newTasks.add(taskMap);
                                }
                            }

                            final newPlan = DailyPlan(
                              id: existingPlan?.id ?? '',
                              date: existingPlan?.date ?? DateTime.now(),
                              priorities: validPriorities,
                              tasks: newTasks,
                              notes: existingPlan?.notes ?? '',
                            );

                            await _firestoreService.saveDailyPlan(newPlan);
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Save Plan',
                              style: GoogleFonts.outfit(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DailyPlan?>(
      stream: _firestoreService.getDailyPlanStream(DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }

        final plan = snapshot.data;
        var tasks = plan?.tasks ?? [];
        final bool hasPlan = plan != null && tasks.isNotEmpty;

        if (hasPlan) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                 _checkDeadlineAlert(context, tasks);
             });
        }

        return GlassContainer(
          color: Colors.white,
          opacity: 0.8,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.list_alt_rounded,
                            color: Colors.indigo, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Plan",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (hasPlan)
                             Text(
                               "${tasks.where((t) => t['isCompleted'] == true).length}/${tasks.length} Completed",
                               style: TextStyle(
                                   color: Colors.grey[600], fontSize: 13),
                             ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(hasPlan ? Icons.edit_outlined : Icons.add_circle_outline,
                        color: Colors.indigo),
                    onPressed: () => _showPlanningSheet(context, plan),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!hasPlan)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Column(
                      children: [
                        Text(
                          "No plan set for today.",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => _showPlanningSheet(context, plan),
                          child: const Text("Set Priorities"),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                   // Active Tasks
                   ...tasks.asMap().entries
                       .where((e) => e.value['isCompleted'] != true)
                       .map((e) => _buildTaskItem(context, plan!, e.value, e.key)),
                   
                   // Completed Tasks
                   if (tasks.any((t) => t['isCompleted'] == true)) ...[
                       const SizedBox(height: 16),
                       Row(
                           children: [
                               Expanded(child: Divider(color: Colors.grey[200])),
                               Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                   child: Text("Completed", style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.bold)),
                               ),
                               Expanded(child: Divider(color: Colors.grey[200])),
                           ],
                       ),
                       const SizedBox(height: 8),
                       ...tasks.asMap().entries
                           .where((e) => e.value['isCompleted'] == true)
                           .map((e) => _buildTaskItem(context, plan!, e.value, e.key)),
                   ]
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskItem(BuildContext context, DailyPlan plan, Map<String, dynamic> task, int taskIndex) {
        final isCompleted = task['isCompleted'] == true;
        
        String? deadlineText;
        Color timeColor = Colors.grey[600]!;
        IconData timeIcon = Icons.schedule;
        
        if (task.containsKey('deadline') && task['deadline'] != null && !isCompleted) {
             DateTime? deadline;
             // Handle both old format (HH:mm) and new format (ISO8601)
             if ((task['deadline'] as String).contains('T') || (task['deadline'] as String).length > 5) {
                 deadline = DateTime.tryParse(task['deadline']);
             } else {
                 // Fallback for old simple time strings if any exist in DB
                 final parts = (task['deadline'] as String).split(':');
                 final now = DateTime.now();
                 deadline = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
             }

             if (deadline != null) {
                  final now = DateTime.now();
                  final diff = deadline.difference(now);
                  
                  if (diff.isNegative) {
                      timeColor = Colors.red;
                      timeIcon = Icons.warning_amber_rounded;
                      deadlineText = "Overdue";
                  } else {
                      if (diff.inMinutes < 60) {
                          timeColor = Colors.orange;
                          timeIcon = Icons.access_time_filled;
                          deadlineText = "${diff.inMinutes}m left";
                      } else if (diff.inHours < 24) {
                          timeColor = Colors.indigo;
                          int hours = diff.inHours;
                          int minutes = diff.inMinutes % 60;
                          if (minutes > 0) {
                              deadlineText = "${hours}h ${minutes}m left";
                          } else {
                              deadlineText = "${hours}h left";
                          }
                      } else {
                          timeColor = Colors.grey;
                          deadlineText = DateFormat('MMM d, h:mm a').format(deadline);
                      }
                  }
             }
        }

        return InkWell(
          onTap: () {
               _firestoreService.updateDailyPlanTask(plan.id, taskIndex, !isCompleted);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: isCompleted ? Colors.green : Colors.grey[400],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                            task['title'],
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: isCompleted
                                  ? Colors.grey[400]
                                  : Colors.black87,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          if (deadlineText != null && !isCompleted)
                              Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: timeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8)
                                  ),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                          Icon(timeIcon, size: 12, color: timeColor),
                                          const SizedBox(width: 4),
                                          Text(
                                              deadlineText,
                                              style: TextStyle(
                                                  fontSize: 12, color: timeColor, fontWeight: FontWeight.bold
                                              )
                                          )
                                      ],
                                  ),
                              )
                      ]
                  )
                ),
              ],
            ),
          ),
        );
  }

  // Anti-spam flag for alerts
  static bool _hasShownAlert = false;

  void _checkDeadlineAlert(BuildContext context, List<dynamic> tasks) {
      if (_hasShownAlert) return;

      final now = DateTime.now();

      for (var task in tasks) {
          if (task['isCompleted'] == true) continue;
          if (!task.containsKey('deadline') || task['deadline'] == null) continue;

          DateTime? deadline;
           if ((task['deadline'] as String).contains('T') || (task['deadline'] as String).length > 5) {
               deadline = DateTime.tryParse(task['deadline']);
           } else {
               final parts = (task['deadline'] as String).split(':');
               deadline = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
           }

          if (deadline != null) {
              final diff = deadline.difference(now);
              // Alert if due within 30 mins and not overdue by more than 5 mins
              if (diff.inMinutes > 0 && diff.inMinutes <= 30) {
                   _hasShownAlert = true;
                   showDialog(
                       context: context,
                       builder: (context) => AlertDialog(
                           title: const Text("⏰ Task Due Soon!"),
                           content: Text("Your priority '${task['title']}' is due in ${diff.inMinutes} minutes!"),
                           actions: [
                               TextButton(
                                   onPressed: () => Navigator.pop(context),
                                   child: const Text("I'm on it!"),
                               )
                           ],
                       )
                   );
                   break; 
              }
          }
      }
  }
}

