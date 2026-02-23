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
    "Action is the foundational key to all success.",
    "Success is not final, failure is not fatal: it is the courage to continue that counts.",
    "You are never too old to set another goal or to dream a new dream.",
    "Act as if what you do makes a difference. It does.",
    "Dream big and dare to fail.",
    "Do what you can, with what you have, where you are.",
    "Keep your face always toward the sunshine—and shadows will fall behind you.",
    "The power of imagination makes us infinite.",
  ];

  String getRandomQuote() {
    return _quotes[Random().nextInt(_quotes.length)];
  }
}
