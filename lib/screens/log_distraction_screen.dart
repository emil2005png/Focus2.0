import 'package:flutter/material.dart';
import 'package:focus_app/services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart';

class LogDistractionScreen extends StatefulWidget {
  const LogDistractionScreen({super.key});

  @override
  State<LogDistractionScreen> createState() => _LogDistractionScreenState();
}

class _LogDistractionScreenState extends State<LogDistractionScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedType = 'Social Media';
  final TextEditingController _otherTypeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  final List<String> _distractionTypes = [
    'Social Media',
    'Gaming',
    'Overthinking',
    'YouTube / Streaming',
    'Chatting',
    'Other',
  ];

  @override
  void dispose() {
    _otherTypeController.dispose();
    _durationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveDistraction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final type = _selectedType == 'Other'
            ? _otherTypeController.text.trim()
            : _selectedType;

        final duration = int.parse(_durationController.text.trim());
        final note = _noteController.text.trim();

        await _firestoreService.addDistraction(
          type: type,
          durationMinutes: duration,
          note: note.isNotEmpty ? note : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Distraction logged successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error logging distraction: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Log Distraction', style: GoogleFonts.outfit(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What distracted you?',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _distractionTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
              ),
              if (_selectedType == 'Other') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _otherTypeController,
                  decoration: InputDecoration(
                    labelText: 'Specify Distraction',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (_selectedType == 'Other' && (value == null || value.isEmpty)) {
                      return 'Please specify the distraction';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'How long? (minutes)',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g., 15',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  suffixText: 'min',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter duration';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Add a note (optional)',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Any context...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveDistraction,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.red[400], // Distraction feels "bad" or "alert"
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Log Distraction', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
