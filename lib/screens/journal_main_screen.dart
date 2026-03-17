import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:focus_app/screens/journal_entry_screen.dart';
import 'package:focus_app/screens/journal_list_screen.dart';
import 'package:focus_app/screens/reflection_screen.dart';
import 'package:focus_app/screens/emotional_support_chat_screen.dart';
import 'package:focus_app/widgets/glass_container.dart';


class JournalMainScreen extends StatefulWidget {
  const JournalMainScreen({super.key});

  @override
  State<JournalMainScreen> createState() => _JournalMainScreenState();
}

class _JournalMainScreenState extends State<JournalMainScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light paper-like background
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Journal Hub', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87)),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            centerTitle: false,
            floating: true,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendar Widget
                  Text(
                    'Your Month',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GlassContainer(
                    color: Colors.white,
                    opacity: 1.0,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: TableCalendar(
                      firstDay: DateTime.utc(2020, 10, 16),
                      lastDay: DateTime.utc(2030, 3, 14),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        if (!isSameDay(_selectedDay, selectedDay)) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                        }
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Text(
                    'What\'s on your mind?',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Priority: New Entry
                  _buildActionCard(
                    context,
                    title: 'New Journal Entry',
                    subtitle: 'Write about your day...',
                    icon: Icons.create,
                    color: Theme.of(context).primaryColor,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const JournalEntryScreen()));
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Daily Reflection
                  _buildActionCard(
                    context,
                    title: 'Daily Reflection',
                    subtitle: 'Guided prompts and thoughts',
                    icon: Icons.lightbulb_outline,
                    color: Colors.amber,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ReflectionScreen()));
                    },
                  ),
                  const SizedBox(height: 16),

                  // View Past
                  _buildActionCard(
                    context,
                    title: 'Past Entries',
                    subtitle: 'Look back at your journey',
                    icon: Icons.history,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const JournalListScreen()));
                    },
                  ),
                  const SizedBox(height: 16),

                  // Emotional Support Chat
                  _buildActionCard(
                    context,
                    title: 'Emotional Support Chat',
                    subtitle: 'Talk to our AI for comfort',
                    icon: Icons.chat_bubble_outline,
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const EmotionalSupportChatScreen()));
                    },
                  ),

                  const SizedBox(height: 100), // Bottom padding for FAB/Nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border(
            left: BorderSide(
              color: color,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
