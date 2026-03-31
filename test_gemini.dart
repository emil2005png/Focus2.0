import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String _apiKey = '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';
  const String _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';
  const String _modelName = 'google/gemini-2.0-flash-001';

  final List<Map<String, String>> _history = [];
  _history.add({
    'role': 'system',
    'content': 'You are a compassionate and empathetic emotional support assistant integrated into a personal journal app. '
  });
  _history.add({'role': 'user', 'content': 'hello who are you'});

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

  print(response.statusCode);
  print(response.body);
}
