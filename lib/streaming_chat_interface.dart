import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({
    required this.text,
    required this.isUser,
  });
}

class StreamingChatInterface extends StatefulWidget {
  final String authToken;
  final String apiUrl;

  const StreamingChatInterface({
    Key? key,
    required this.authToken,
    this.apiUrl = 'http://localhost:8000/hey-steve/chat/pica-openai-stream',
  }) : super(key: key);

  @override
  State<StreamingChatInterface> createState() => _StreamingChatInterfaceState();
}

class _StreamingChatInterfaceState extends State<StreamingChatInterface> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _currentAssistantMessage = '';
  bool _isStreaming = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // Use a microtask to ensure the scroll happens after the UI updates
    Future.microtask(() {
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
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
      ));
      _isLoading = true;
      _isStreaming = true;
      _textController.clear();
      _currentAssistantMessage = '';

      // Add an empty assistant message right away
      _messages.add(ChatMessage(
        text: '',
        isUser: false,
      ));
    });

    _scrollToBottom();

    try {
      final request = http.Request(
        'POST',
        Uri.parse(widget.apiUrl),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'Authorization': 'Bearer ${widget.authToken}',
      });

      // Format the request to match the endpoint expectations
      request.body = jsonEncode({
        'message': message,
      });

      debugPrint('Sending request to: ${request.url}');
      debugPrint('Request body: ${request.body}');

      final client = http.Client();
      try {
        final response = await client.send(request);

        if (response.statusCode != 200) {
          final errorBody = await response.stream.bytesToString();
          throw Exception(
              'Failed to send message: ${response.statusCode} - $errorBody');
        }

        // Transform the response stream
        final stream = response.stream.transform(utf8.decoder);

        await for (var chunk in stream) {
          debugPrint('Received chunk: $chunk');

          // Process the chunk line by line
          final lines = chunk.split('\n\n');
          for (var line in lines) {
            if (line.isEmpty) continue;
            _processStreamChunk(line);
          }
        }

        setState(() {
          _isLoading = false;
          _isStreaming = false;
        });
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      setState(() {
        // Update the last message if it's from the assistant and empty
        if (_messages.isNotEmpty &&
            !_messages.last.isUser &&
            _messages.last.text.isEmpty) {
          _messages.removeLast();
        }

        _messages.add(ChatMessage(
          text: 'Error: $e',
          isUser: false,
        ));
        _isLoading = false;
        _isStreaming = false;
      });
    }

    _scrollToBottom();
  }

  void _processStreamChunk(String line) {
    try {
      // The line format is expected to be: data: <content>
      if (line.startsWith('data: ')) {
        String content = line.substring(6);

        // Check if it's the end marker
        if (content == '[DONE]') {
          setState(() {
            _isStreaming = false;
            _isLoading = false;
          });
          return;
        }

        // Update the assistant message with this chunk
        _updateAssistantMessage(content);
      }
    } catch (e) {
      debugPrint('Error processing chunk: $e');
    }
  }

  void _updateAssistantMessage(String content) {
    if (content.isEmpty) return;

    setState(() {
      _currentAssistantMessage += content;

      // Update the last message if it's from the assistant
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        _messages[_messages.length - 1] = ChatMessage(
          text: _currentAssistantMessage,
          isUser: false,
        );
      }
    });

    // Scroll to show the latest content
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaming Chat'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcomeMessage()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isLastMessage = index == _messages.length - 1;
                      final showCursor =
                          isLastMessage && !message.isUser && _isStreaming;
                      return _buildMessageBubble(message, showCursor);
                    },
                  ),
          ),
          if (_isLoading && !_isStreaming)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple[300]!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI is thinking...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.deepPurple[200],
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Streaming Chat',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip(
                  'What is the president of the United States?'),
              _buildSuggestionChip('Tell me about LangChain streaming'),
              _buildSuggestionChip('How does text streaming work?'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: Colors.deepPurple[50],
      labelStyle: TextStyle(color: Colors.deepPurple[700]),
      onPressed: () {
        _textController.text = text;
        _sendMessage();
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool showCursor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: const Text('AI', style: TextStyle(color: Colors.white)),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.deepPurple[100] : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: showCursor
                  ? RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: message.text,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                          const WidgetSpan(
                            child: _BlinkingCursor(),
                          ),
                        ],
                      ),
                    )
                  : Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.black87 : Colors.black,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser)
            CircleAvatar(
              backgroundColor: Colors.deepPurple[700],
              child: const Text('U', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isLoading ? null : _sendMessage,
            backgroundColor:
                _isLoading ? Colors.grey[400] : Colors.deepPurple[700],
            elevation: 2,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 2,
        height: 16,
        color: Colors.black,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
