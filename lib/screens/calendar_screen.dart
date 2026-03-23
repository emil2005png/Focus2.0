import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:focus_app/providers/calendar_provider.dart';
import 'package:focus_app/models/calendar_activity.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  static void showAddEditDialog(BuildContext context, {CalendarActivity? activity}) {
    final titleController = TextEditingController(text: activity?.title ?? '');
    final descriptionController = TextEditingController(text: activity?.description ?? '');
    DateTime selectedTime = activity?.dateTime ?? context.read<CalendarProvider>().selectedDay;
    String selectedType = activity?.type ?? 'activity';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(activity == null ? 'Add Activity' : 'Edit Activity', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   _buildTypeSelection(selectedType, (type) {
                    setState(() {
                      selectedType = type;
                    });
                  }),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: selectedType == 'exam' ? 'Exam Subject' : 'Title',
                      labelStyle: TextStyle(color: Colors.indigo[300]),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.indigo)),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Title cannot be empty' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      labelStyle: TextStyle(color: Colors.indigo[300]),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.indigo)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(DateFormat('MMM dd, hh:mm a').format(selectedTime)),
                      trailing: const Icon(Icons.calendar_today, color: Colors.indigo),
                      onTap: () async {
                        DateTime? date = await showDatePicker(
                          context: context,
                          initialDate: selectedTime,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          if (!context.mounted) return;
                          TimeOfDay? time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedTime),
                          );
                          if (time != null) {
                            setState(() {
                              selectedTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final provider = context.read<CalendarProvider>();
                  if (activity == null) {
                    provider.addActivity(titleController.text, descriptionController.text, selectedTime, type: selectedType);
                  } else {
                    provider.updateActivity(activity.copyWith(
                      title: titleController.text,
                      description: descriptionController.text,
                      dateTime: selectedTime,
                      type: selectedType,
                    ));
                  }
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedType == 'exam' ? Colors.redAccent : Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTypeSelection(String currentType, Function(String) onSelected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _typeButton('Activity', 'activity', currentType == 'activity', Icons.event_note, Colors.indigo, onSelected),
        const SizedBox(width: 12),
        _typeButton('Exam', 'exam', currentType == 'exam', Icons.school, Colors.redAccent, onSelected),
      ],
    );
  }

  static Widget _typeButton(String label, String value, bool isSelected, IconData icon, Color color, Function(String) onSelected) {
    return InkWell(
      onTap: () => onSelected(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Calendar', style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Column(
        children: [
          const _CalendarWidget(),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.event_note, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Daily Overview',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Expanded(child: _EventListWidget()),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => showAddEditDialog(context),
          heroTag: 'calendar_fab',
          backgroundColor: Colors.indigo,
          elevation: 4,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _CalendarWidget extends StatelessWidget {
  const _CalendarWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: provider.focusedDay,
            selectedDayPredicate: (day) => provider.isSameDay(provider.selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              provider.setSelectedDay(selectedDay);
              provider.setFocusedDay(focusedDay);
            },
            eventLoader: (day) => provider.getActivitiesForDay(day),
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.15), shape: BoxShape.circle),
              todayTextStyle: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
              outsideDaysVisible: false,
              markersMaxCount: 4,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty && !provider.hasHabitCompletion(day) && provider.getMoodForDay(day) == null) return null;
                
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       if (events.any((e) => (e as CalendarActivity).type == 'exam'))
                        _indicator(Colors.redAccent),
                      if (events.any((e) => (e as CalendarActivity).type == 'activity'))
                        _indicator(Colors.orange),
                      if (provider.hasHabitCompletion(day))
                         _indicator(Colors.green),
                      if (provider.getMoodForDay(day) != null)
                        Text(provider.getMoodForDay(day)!, style: const TextStyle(fontSize: 8)),
                    ],
                  ),
                );
              },
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
              leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.indigo),
              rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.indigo),
            ),
          ),
        );
      },
    );
  }

  Widget _indicator(Color color) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 0.5),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EventListWidget extends StatelessWidget {
  const _EventListWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final activities = provider.getActivitiesForDay(provider.selectedDay);
        final mood = provider.getMoodForDay(provider.selectedDay);
        final hasHabit = provider.hasHabitCompletion(provider.selectedDay);

        if (activities.isEmpty && mood == null && !hasHabit) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                  child: Icon(Icons.event_available, size: 48, color: Colors.grey[400]),
                ),
                const SizedBox(height: 16),
                Text('Nothing tracked for this day', style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 16)),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (mood != null || hasHabit) 
               Padding(
                 padding: const EdgeInsets.only(bottom: 16),
                 child: Row(
                   children: [
                     if (mood != null) _summaryChip("Mood: $mood", Colors.amber),
                     if (mood != null && hasHabit) const SizedBox(width: 8),
                     if (hasHabit) _summaryChip("Habits Completed", Colors.green),
                   ],
                 ),
               ),
            ...activities.map((event) => _buildEventCard(context, event, provider)),
          ],
        );
      },
    );
  }

  Widget _summaryChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarActivity event, CalendarProvider provider) {
    final isExam = event.type == 'exam';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final examDay = DateTime(event.dateTime.year, event.dateTime.month, event.dateTime.day);
    final daysRemaining = examDay.difference(today).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isExam ? Colors.redAccent.withValues(alpha: 0.2) : Colors.grey[100]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isExam ? Colors.redAccent : Colors.indigo).withValues(alpha: 0.1), 
            borderRadius: BorderRadius.circular(12)
          ),
          child: Icon(isExam ? Icons.school : Icons.notifications_active_outlined, color: isExam ? Colors.redAccent : Colors.indigo),
        ),
        title: Text(event.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isExam && daysRemaining >= 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  daysRemaining == 0 ? "EXAM TODAY!" : "$daysRemaining days remaining",
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            if (event.description.isNotEmpty)
              Text(event.description, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(DateFormat('hh:mm a').format(event.dateTime), style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) async {
            if (value == 'edit') {
              CalendarScreen.showAddEditDialog(context, activity: event);
            } else if (value == 'delete') {
              // Show confirmation dialog before deleting
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Event'),
                  content: Text('Are you sure you want to delete "${event.title}"?'),
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
                provider.deleteActivity(event.id);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}
