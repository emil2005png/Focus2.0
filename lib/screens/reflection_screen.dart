import 'package:flutter/material.dart';
import 'dart:math';
import 'package:focus_app/screens/journal_entry_screen.dart'; // To link reflection to journal

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  final List<String> _prompts = [
    "What made you smile today?",
    "What is one thing you learned about yourself recently?",
    "Describe a challenge you overcame this week.",
    "What are you grateful for right now?",
    "How do you want to feel tomorrow?",
    "Who has supported you lately, and how?",
    "What is a habit you'd like to build?",
  ];

  String _currentPrompt = "";

  @override
  void initState() {
    super.initState();
    _generateNewPrompt();
  }

  void _generateNewPrompt() {
    setState(() {
      _currentPrompt = _prompts[Random().nextInt(_prompts.length)];
    });
  }

  void _reflectOnThis() {
    // Navigate to Journal Entry with pre-filled content (optional) or just context
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const JournalEntryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lightbulb_circle, size: 80, color: Colors.amber),
              const SizedBox(height: 24),
              const Text(
                'Daily Reflection',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _currentPrompt,
                  style: const TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: _reflectOnThis,
                icon: const Icon(Icons.edit),
                label: const Text('Reflect on this'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _generateNewPrompt,
                child: const Text('New Prompt'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
