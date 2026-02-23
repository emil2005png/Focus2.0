import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:focus_app/screens/journal_entry_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class JournalListScreen extends StatelessWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light paper-like background
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text('Journal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87)),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            centerTitle: false,
            floating: true,
            pinned: true,
          ),
          StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getJournals(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}')));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                 return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.book, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No journal entries yet.\nStart writing your story!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Bottom padding for floating nav
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
                      final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(date);

                      return Dismissible(
                        key: Key(doc.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          firestoreService.deleteJournal(doc.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Entry deleted')),
                          );
                        },
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JournalEntryScreen(entry: doc),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border(
                                left: BorderSide(
                                  color: Theme.of(context).primaryColor,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['title'] ?? 'Untitled',
                                        style: GoogleFonts.outfit( // Updated font
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (data['mood'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: Text(
                                          data['mood'], 
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                    Icon(Icons.edit, size: 16, color: Colors.grey[400]),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const Divider(height: 20),
                                Text(
                                  data['content'] ?? '',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.merriweather( // Serif for content
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Padding( // Adjust FAB position
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const JournalEntryScreen()),
            );
          },
          label: const Text('New Entry'),
          icon: const Icon(Icons.create),
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
