import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/services/quote_service.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  final QuoteService _quoteService = QuoteService();
  late String _currentQuote;

  @override
  void initState() {
    super.initState();
    _currentQuote = _quoteService.getRandomQuote();
  }

  void _newQuote() {
    setState(() {
      _currentQuote = _quoteService.getRandomQuote();
    });
  }

  @override
  Widget build(BuildContext context) {
     return Scaffold(
      backgroundColor: Colors.amber[50],
      appBar: AppBar(
        title: Text('Daily Inspiration', style: GoogleFonts.outfit(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.format_quote_rounded, size: 60, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              _currentQuote,
              textAlign: TextAlign.center,
              style: GoogleFonts.patrickHand(
                fontSize: 32,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _newQuote,
              icon: const Icon(Icons.refresh),
              label: const Text("New Quote"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
