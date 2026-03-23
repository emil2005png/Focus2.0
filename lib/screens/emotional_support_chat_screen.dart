import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_app/services/gemini_service.dart';
import 'package:focus_app/widgets/glass_container.dart';

class EmotionalSupportChatScreen extends StatefulWidget {
  const EmotionalSupportChatScreen({super.key});

  @override
  State<EmotionalSupportChatScreen> createState() => _EmotionalSupportChatScreenState();
}

class _EmotionalSupportChatScreenState extends State<EmotionalSupportChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add({
      'role': 'model',
      'text': 'Hello. I\'m here to listen and support you. How are you feeling today?',
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _geminiService.sendMessage(text);
      if (response != null) {
        setState(() {
          _messages.add({'role': 'model', 'text': response});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'model',
          'text': 'I\'m sorry, I\'m having a bit of trouble connecting right now. Please try again in a moment.',
          'isError': true,
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Emotional Support', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () {
              setState(() {
                _geminiService.resetHistory();
                _messages.clear();
                _messages.add({
                  'role': 'model',
                  'text': 'Hello again. I\'ve reset our session. How can I support you now?',
                });
              });
            },
            tooltip: 'Reset Session',
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }

                final message = _messages[index];
                final isUser = message['role'] == 'user';
                final isError = message['isError'] ?? false;

                return TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 300),
                  tween: Tween<double>(begin: 0, end: 1),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: isUser 
                            ? LinearGradient(
                                colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: !isUser ? (isError ? Colors.red[50] : Colors.white) : null,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isUser ? 20 : 0),
                          bottomRight: Radius.circular(isUser ? 0 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: isUser ? null : Border.all(color: isError ? Colors.red[100]! : Colors.grey[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['text'],
                            style: GoogleFonts.outfit(
                              color: isUser ? Colors.white : (isError ? Colors.red[700] : Theme.of(context).colorScheme.onSurface),
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                          if (isError) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                final lastUserMsg = _messages.lastWhere((m) => m['role'] == 'user', orElse: () => {});
                                if (lastUserMsg.isNotEmpty) {
                                  _controller.text = lastUserMsg['text'];
                                  setState(() {
                                    _messages.removeAt(index);
                                  });
                                  _sendMessage();
                                }
                              },
                              icon: Icon(Icons.refresh, size: 16, color: Colors.red[700]),
                              label: Text('Retry', style: GoogleFonts.outfit(color: Colors.red[700], fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey[100]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) => _buildDot(index)),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 300 + (index * 150)),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeInOut,
      onEnd: () {
        // No-op, just creates a simple one-time animation per dot for basic "activity" feel
      },
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3 + (0.4 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: GlassContainer(
                color: Colors.grey[100]!,
                opacity: 0.8,
                borderRadius: BorderRadius.circular(30),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _controller,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Share what\'s on your mind...',
                    border: InputBorder.none,
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                  ),
                  style: GoogleFonts.outfit(),
                  onSubmitted: (_) => _sendMessage(),
                  textInputAction: TextInputAction.send,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isLoading ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isLoading ? Colors.grey[300] : Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!_isLoading)
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
