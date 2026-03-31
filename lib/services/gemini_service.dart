import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = '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';
  static const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _modelName = 'google/gemini-2.0-flash-001';

  final List<Map<String, String>> _history = [];

  GeminiService() {
    _history.add({
      'role': 'system',
      'content': 'You are a compassionate and empathetic emotional support assistant integrated into a personal journal app. '
          'Your goal is to provide a safe space for users to express their feelings, offer validation, and suggest gentle coping strategies or reflective questions. '
          'Be warm, non-judgmental, and supportive. Use active listening techniques. '
          'If a user expresses thoughts of self-harm or serious crisis, gently encourage them to seek professional help and provide resources if appropriate, while remaining supportive.'
    });
  }

  Future<String?> sendMessage(String message) async {
    try {
      _history.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://focus-app.com', // Required by OpenRouter
          'X-Title': 'Focus App', // Optional
        },
        body: jsonEncode({
          'model': _modelName,
          'messages': _history,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiMessage = data['choices'][0]['message']['content'] as String;
        _history.add({'role': 'assistant', 'content': aiMessage});
        return aiMessage;
      } else {
        debugPrint('OpenRouter Error: ${response.statusCode} - ${response.body}');
        return "I'm processing what you said, but I'm having trouble finding the right words. Could you tell me more?";
      }
    } catch (e) {
      debugPrint('Service Error: $e');
      rethrow;
    }
  }

  void resetHistory() {
    final systemPrompt = _history.first;
    _history.clear();
    _history.add(systemPrompt);
  }
}
