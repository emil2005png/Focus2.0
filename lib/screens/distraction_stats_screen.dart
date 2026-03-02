import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:focus_app/screens/log_distraction_screen.dart';
import 'package:focus_app/services/advice_service.dart';

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

          // Calculate Today's Stats and Group by Date
          int todayTotalMinutes = 0;
          Map<String, int> typeFrequency = {};
          Map<String, List<Map<String, dynamic>>> groupedDistractions = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            // Use 'date' field if available, fallback to timestamp
            final dateStr = data['date'] ?? (data['timestamp'] as Timestamp?)?.toDate().toIso8601String().split('T')[0] ?? 'Unknown';

            if (dateStr == todayStr) {
               final minutes = data['durationMinutes'] as int? ?? 0;
               todayTotalMinutes += minutes;

               final type = data['type'] as String? ?? 'Unknown';
               typeFrequency[type] = (typeFrequency[type] ?? 0) + 1;
            }

            // Grouping logic
            if (!groupedDistractions.containsKey(dateStr)) {
              groupedDistractions[dateStr] = [];
            }
            Map<String, dynamic> item = Map.from(data);
            item['id'] = doc.id;
            groupedDistractions[dateStr]!.add(item);
          }

          // Sort dates (descending)
          final sortedDates = groupedDistractions.keys.toList()..sort((a, b) => b.compareTo(a));

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
                // Insight Card
                FutureBuilder<String?>(
                  future: firestoreService.getTodayMood(),
                  builder: (context, moodSnapshot) {
                    final advice = AdviceService().generateAdvice(
                      totalDistractionMinutes: todayTotalMinutes,
                      currentMood: moodSnapshot.data,
                      distractionCount: snapshot.data!.docs.where((doc) => (doc.data() as Map)['date'] == todayStr).length,
                    );
                    
                    if (advice == null) return const SizedBox.shrink();
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo[400]!, Colors.indigo[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's Insight",
                                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  advice.message,
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),

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

                // Grouped Log List
                for (var dateKey in sortedDates) ...[
                   Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      _getDateLabel(dateKey, todayStr),
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                    ),
                  ),
                   ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: groupedDistractions[dateKey]!.length,
                    itemBuilder: (context, index) {
                      final data = groupedDistractions[dateKey]![index];
                      final timestamp = data['timestamp'] as Timestamp?;
                      final timeStr = timestamp != null ? DateFormat('h:mm a').format(timestamp.toDate()) : "";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
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
                              if (timeStr.isNotEmpty)
                                Text(
                                  timeStr,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _getDateLabel(String dateKey, String todayStr) {
    if (dateKey == todayStr) return "Today";
    
    try {
      final date = DateTime.parse(dateKey);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = yesterday.toIso8601String().split('T')[0];
      
      if (dateKey == yesterdayStr) return "Yesterday";
      
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateKey;
    }
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
