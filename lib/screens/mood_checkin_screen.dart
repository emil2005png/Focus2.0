import 'package:flutter/material.dart';
import 'package:focus_app/models/mood_entry.dart';
import 'package:focus_app/services/auth_service.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:focus_app/widgets/auth_gate.dart';
import 'package:focus_app/data/quotes.dart';
import 'dart:math';

import 'package:focus_app/screens/quote_screen.dart'; // Add this import

class MoodCheckInScreen extends StatefulWidget {
  const MoodCheckInScreen({super.key});

  @override
  State<MoodCheckInScreen> createState() => _MoodCheckInScreenState();
}

class _MoodCheckInScreenState extends State<MoodCheckInScreen> {
  final _noteController = TextEditingController();
  final List<String> _moods = ['Happy', 'Excited', 'Calm', 'Sad', 'Anxious', 'Tired'];
  final List<String> _emojis = ['😊', '🤩', '😌', '😔', '😰', '😴'];
  int _selectedMoodIndex = -1;
  bool _isLoading = false;

  void _saveMood() async {
    if (_selectedMoodIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a mood')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
       await FirestoreService().addMood(
        moodIndex: _selectedMoodIndex,
        note: _noteController.text.trim(),
      );
      
        // Show motivational quote full screen
        final random = Random();
        final quote = motivationalQuotes[random.nextInt(motivationalQuotes.length)];
        
        if (mounted) {
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QuoteScreen(quote: quote),
            ),
          );
        }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving mood: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How are you feeling?'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: _moods.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedMoodIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMoodIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _emojis[index],
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _moods[index],
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Add a note (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : _saveMood,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Check-in'),
            ),
          ],
        ),
      ),
    );
  }
}
