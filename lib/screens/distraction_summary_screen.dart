import 'package:flutter/material.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DistractionSummaryScreen extends StatelessWidget {
  const DistractionSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weekly Summary', style: GoogleFonts.outfit(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: FirestoreService().getDistractionsForWeek(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No distractions this week! \nKeep it up! 🚀",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[500]),
              ),
            );
          }

          final distractions = snapshot.data!;
          
          // Calculate Stats
          int totalMinutes = 0;
          Map<String, int> dailyTotals = {};
          Map<String, int> categoryCounts = {};

          for (var d in distractions) {
            final mins = d['durationMinutes'] as int? ?? 0;
            totalMinutes += mins;

            final date = (d['timestamp'] as Timestamp).toDate();
            final dayName = DateFormat('EEEE').format(date);
            dailyTotals[dayName] = (dailyTotals[dayName] ?? 0) + mins;

            final type = d['type'] as String? ?? 'Unknown';
            categoryCounts[type] = (categoryCounts[type] ?? 0) + 1;
          }

          // Highest Distraction Day
          String highestDay = "None";
          int maxDayMins = 0;
          dailyTotals.forEach((day, mins) {
            if (mins > maxDayMins) {
              maxDayMins = mins;
              highestDay = day;
            }
          });

          // Most Common Category
          String topCategory = "None";
          int maxCatCount = 0;
          categoryCounts.forEach((cat, count) {
            if (count > maxCatCount) {
              maxCatCount = count;
              topCategory = cat;
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(
                  context,
                  "Total Time Lost",
                  "$totalMinutes min",
                  Icons.timer_off_outlined,
                  Colors.redAccent,
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  context,
                  "Worst Day",
                  "$highestDay ($maxDayMins min)",
                  Icons.calendar_today_outlined,
                  Colors.orangeAccent,
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(
                  context,
                  "Top Distraction",
                  topCategory,
                  Icons.category_outlined,
                  Colors.purpleAccent,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
