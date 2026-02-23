import 'dart:math';

class QuoteService {
  final List<String> _quotes = [
    "The secret of getting ahead is getting started.",
    "Focus on being productive instead of busy.",
    "Your future is created by what you do today, not tomorrow.",
    "Don't watch the clock; do what it does. Keep going.",
    "Starve your distraction and feed your focus.",
    "Success is the sum of small efforts, repeated day in and day out.",
    "The only way to do great work is to love what you do.",
    "Believe you can and you're halfway there.",
    "It always seems impossible until it is done.",
    "Action is the foundational key to all success."
  ];

  String getRandomQuote() {
    return _quotes[Random().nextInt(_quotes.length)];
  }
}
