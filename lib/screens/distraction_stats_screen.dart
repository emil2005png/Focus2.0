import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:focus_app/screens/log_distraction_screen.dart';

class DistractionStatsScreen extends StatelessWidget {
  const DistractionStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: Text('Distraction Stats', style: GoogleFonts.outfit(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LogDistractionScreen()),
          );
        },
        label: Text(
          'Log Distraction',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add_alert_rounded),
        backgroundColor: Colors.red[400],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getDistractions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No distractions logged yet!\nKeep up the focus! 🎉",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(fontSize: 18, color: Colors.grey[500]),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final todayStr = DateTime.now().toIso8601String().split('T')[0];

          // Calculate Today's Stats
          int todayTotalMinutes = 0;
          Map<String, int> typeFrequency = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['timestamp'] as Timestamp).toDate();
            final dateStr = date.toIso8601String().split('T')[0];

            if (dateStr == todayStr) {
               final minutes = data['durationMinutes'] as int? ?? 0;
               todayTotalMinutes += minutes;

               final type = data['type'] as String? ?? 'Unknown';
               typeFrequency[type] = (typeFrequency[type] ?? 0) + 1;
            }
          }

          // Find Most Frequent
          String mostFrequent = "None";
          int maxCount = 0;
          typeFrequency.forEach((key, value) {
            if (value > maxCount) {
              maxCount = value;
              mostFrequent = key;
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Today's Time",
                        "$todayTotalMinutes min",
                        Icons.access_time_filled,
                        Colors.red[400]!,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        "Most Common",
                        mostFrequent,
                        Icons.warning_amber_rounded,
                        Colors.orange[400]!,
                        isSmallText: mostFrequent.length > 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Logs Header
                Text(
                  "Recent Distractions",
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Recent Logs List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length > 10 ? 10 : docs.length, // Show max 10
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final date = (data['timestamp'] as Timestamp).toDate();
                    final timeStr = DateFormat('h:mm a').format(date);
                    final dateLabel = DateFormat('MMM d').format(date);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      shadowColor: Colors.black12,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red[50],
                          child: Icon(Icons.broken_image_outlined, color: Colors.red[400], size: 20),
                        ),
                        title: Text(
                          data['type'] ?? 'Unknown',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                        ),
                        subtitle: data['note'] != null && data['note'].toString().isNotEmpty
                            ? Text(data['note'], maxLines: 1, overflow: TextOverflow.ellipsis)
                            : null,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${data['durationMinutes']} min",
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red[400]),
                            ),
                            Text(
                              "$dateLabel, $timeStr",
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isSmallText = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: isSmallText ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}
