import 'package:flutter/material.dart';
import 'package:focus_app/models/daily_plan.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:focus_app/theme/app_theme.dart';
import 'package:focus_app/widgets/glass_container.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyPlanningWidget extends StatefulWidget {
  const DailyPlanningWidget({super.key});

  @override
  State<DailyPlanningWidget> createState() => _DailyPlanningWidgetState();
}

class _DailyPlanningWidgetState extends State<DailyPlanningWidget> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showPlanningSheet(BuildContext context, DailyPlan? existingPlan) {
    final List<TextEditingController> _priorityControllers = List.generate(
      3,
      (index) => TextEditingController(
        text: existingPlan != null && index < existingPlan.priorities.length
            ? existingPlan.priorities[index]
            : '',
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Plan Your Day 🎯',
                  style: GoogleFonts.outfit(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('What are your top 3 priorities?',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16)),
              const SizedBox(height: 24),
              ...List.generate(3, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextField(
                    controller: _priorityControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Priority ${index + 1}',
                      prefixIcon: Icon(Icons.star_border_rounded,
                          color: index == 0
                              ? Colors.orange
                              : Colors.grey), // First one highlights
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final priorities = _priorityControllers
                        .map((c) => c.text.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();

                    // Convert priorities to tasks structure if needed, or just save priorities
                    // For now, let's treat priorities as simple strings in 'priorities' list
                    // And optionally create 'tasks' from them if we want checkable items.
                    
                    // Let's populate the 'tasks' list so they can be checked off
                    List<Map<String, dynamic>> newTasks = [];
                    if (existingPlan != null) {
                        // Preserve existing task states if the title matches, simplistic approach
                        // Or just clear and rewrite. Let's rewrite for simplicity of "Planning" phase.
                        // Ideally, we'd sync them.
                        
                        // Strategy: Create new task list. If a priority matches an existing task name, keep its state.
                        for (var p in priorities) {
                            var existingTask = existingPlan.tasks.firstWhere(
                                (t) => t['title'] == p, 
                                orElse: () => {'title': p, 'isCompleted': false}
                            );
                            newTasks.add({'title': p, 'isCompleted': existingTask['isCompleted']});
                        }
                    } else {
                        newTasks = priorities.map((p) => {'title': p, 'isCompleted': false}).toList();
                    }

                    final newPlan = DailyPlan(
                      id: existingPlan?.id ?? '', // Service handles empty ID as new
                      date: existingPlan?.date ?? DateTime.now(),
                      priorities: priorities,
                      tasks: newTasks,
                      notes: existingPlan?.notes ?? '',
                    );

                    await _firestoreService.saveDailyPlan(newPlan);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Save Plan',
                      style: GoogleFonts.outfit(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
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
        final bool hasPlan = plan != null && plan.priorities.isNotEmpty;

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
                              "${plan.tasks.where((t) => t['isCompleted'] == true).length}/${plan.tasks.length} Completed",
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
              else
                ...List.generate(plan.tasks.length, (index) {
                  final task = plan.tasks[index];
                  final isCompleted = task['isCompleted'] == true;
                  return InkWell(
                    onTap: () {
                         // Toggle completion locally for UI responsiveness then save
                         // Ideally we'd optimize this, but calling saveDailyPlan with modified list is easiest 
                         // given we need to update the specific item.
                         // But we have updateDailyPlanTask in service now!
                         _firestoreService.updateDailyPlanTask(plan.id, index, !isCompleted);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            color: isCompleted ? Colors.green : Colors.grey[400],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
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
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
