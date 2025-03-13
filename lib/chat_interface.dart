import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String text;
  final bool isUser;
  final String? messageId;
  final Map<String, dynamic>? toolCall;
  final Map<String, dynamic>? toolResult;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.messageId,
    this.toolCall,
    this.toolResult,
  });
}

class ChatInterface extends StatefulWidget {
  final String authToken;

  const ChatInterface({
    Key? key,
    required this.authToken,
  }) : super(key: key);

  @override
  State<ChatInterface> createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _currentAssistantMessage = '';
  String? _currentMessageId;
  Map<String, dynamic>? _currentToolCall;
  Map<String, dynamic>? _currentToolResult;
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
      _isStreaming = true; // Set streaming to true immediately
      _textController.clear();
      _currentAssistantMessage = '';
      _currentMessageId = null;
      _currentToolCall = null;
      _currentToolResult = null;

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
        Uri.parse('http://localhost:3000/api/chat'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.authToken}',
      });

      // Format the request to match Next.js API expectations
      request.body = jsonEncode({
        'messages': [
          {
            'role': 'user',
            'content': message,
          },
        ],
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

        final stream = response.stream.transform(utf8.decoder);

        await for (var chunk in stream) {
          debugPrint('Received chunk: $chunk');

          // Process the chunk line by line
          final lines = chunk.split('\n');
          for (var line in lines) {
            if (line.isEmpty) continue;
            await _processNextJsChunk(line);
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

  Future<void> _processNextJsChunk(String line) async {
    try {
      if (line.length < 2 || line[1] != ':') {
        debugPrint('Invalid format: $line');
        return;
      }

      final eventType = line[0];
      String data = line.substring(2);

      switch (eventType) {
        case 'f': // Message ID
          try {
            final parsed = jsonDecode(data);
            setState(() {
              _currentMessageId = parsed['messageId'];

              // Update the message with the new message ID
              if (_messages.isNotEmpty && !_messages.last.isUser) {
                _messages[_messages.length - 1] = ChatMessage(
                  text: _currentAssistantMessage,
                  isUser: false,
                  messageId: _currentMessageId,
                  toolCall: _currentToolCall,
                  toolResult: _currentToolResult,
                );
              }
            });
          } catch (e) {
            debugPrint('Error parsing message ID: $e');
          }
          break;

        case '9': // Tool Call
          try {
            final parsed = jsonDecode(data);
            await _updateToolCall(parsed);
          } catch (e) {
            debugPrint('Error parsing tool call: $e');
          }
          break;

        case 'a': // Tool Result
          try {
            final parsed = jsonDecode(data);
            await _updateToolResult(parsed);
          } catch (e) {
            debugPrint('Error parsing tool result: $e');
          }
          break;

        case '0': // Text content - this is what we need for streaming
          // Clean the text content
          if (data.isNotEmpty) {
            // If the data is wrapped in quotes like "text", remove them
            if (data.startsWith('"') &&
                data.endsWith('"') &&
                data.length >= 2) {
              data = data.substring(1, data.length - 1);
            }

            // Unescape any escaped quotes or other characters
            data = data
                .replaceAll('\\"', '"')
                .replaceAll('\\n', '\n')
                .replaceAll('\\r', '\r')
                .replaceAll('\\\\', '\\');

            debugPrint('Processed text chunk: "$data"');

            // Update the message with this chunk
            await _updateAssistantMessage(data);

            // Force UI update
            setState(() {});
          }
          break;

        case 'e': // End of message
          try {
            final parsed = jsonDecode(data);
            debugPrint('End of message: ${parsed['finishReason']}');
          } catch (e) {
            debugPrint('Error parsing end of message: $e');
          }
          break;

        case 'd': // End of conversation
          try {
            final parsed = jsonDecode(data);
            debugPrint('End of conversation: ${parsed['finishReason']}');

            // Mark streaming as complete
            setState(() {
              _isStreaming = false;
              _isLoading = false;
            });
          } catch (e) {
            debugPrint('Error parsing end of conversation: $e');
          }
          break;

        default:
          debugPrint('Unknown event type: $eventType');
      }

      // After processing each line, scroll to bottom to ensure visibility
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error processing chunk: $e');
    }
  }

  Future<void> _updateAssistantMessage(String content) async {
    if (content.isEmpty) return;

    // Use a Completer to make this function awaitable
    final completer = Completer<void>();

    setState(() {
      _currentAssistantMessage += content;

      // Update the last message if it's from the assistant
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        _messages[_messages.length - 1] = ChatMessage(
          text: _currentAssistantMessage,
          isUser: false,
          messageId: _currentMessageId,
          toolCall: _currentToolCall,
          toolResult: _currentToolResult,
        );
      }

      completer.complete();
    });

    // Let's also call scroll to bottom here
    _scrollToBottom();

    return completer.future;
  }

  Future<void> _updateToolCall(Map<String, dynamic> toolCall) async {
    // Use a Completer to make this function awaitable
    final completer = Completer<void>();

    setState(() {
      _currentToolCall = toolCall;

      // Update the last message if it's from the assistant
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        _messages[_messages.length - 1] = ChatMessage(
          text: _currentAssistantMessage,
          isUser: false,
          messageId: _currentMessageId,
          toolCall: _currentToolCall,
          toolResult: _currentToolResult,
        );
      }

      completer.complete();
    });

    // Scroll to show the tool call
    _scrollToBottom();

    return completer.future;
  }

  Future<void> _updateToolResult(Map<String, dynamic> toolResult) async {
    // Use a Completer to make this function awaitable
    final completer = Completer<void>();

    setState(() {
      _currentToolResult = toolResult;

      // Update the last message if it's from the assistant
      if (_messages.isNotEmpty && !_messages.last.isUser) {
        _messages[_messages.length - 1] = ChatMessage(
          text: _currentAssistantMessage,
          isUser: false,
          messageId: _currentMessageId,
          toolCall: _currentToolCall,
          toolResult: _currentToolResult,
        );
      }

      completer.complete();
    });

    // Scroll to show the tool result
    _scrollToBottom();

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Steve'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              child: _messages.isEmpty
                  ? _buildWelcomeMessage()
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final bool isLastMessage =
                            index == _messages.length - 1;
                        final bool showCursor =
                            isLastMessage && !message.isUser && _isStreaming;

                        return _buildMessageBubble(message, showCursor);
                      },
                    ),
            ),
          ),
          if (_isStreaming && _messages.isNotEmpty && !_messages.last.isUser)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                    'Steve is typing...',
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
            'Welcome to Steve Chat',
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
              _buildSuggestionChip('How can you help me?'),
              _buildSuggestionChip("Send email to alvin@walturn.com"),
              _buildSuggestionChip('Tell me a joke'),
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
              child: const Text('S', style: TextStyle(color: Colors.white)),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show blinking cursor only for the assistant's last message when streaming
                  showCursor
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
                            color:
                                message.isUser ? Colors.black87 : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                  if (message.toolCall != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tool: ${message.toolCall!['toolName']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Args: ${jsonEncode(message.toolCall!['args'])}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (message.toolResult != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Result: ${message.toolResult!['result']?['success'] == true ? 'Success' : 'Failed'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: message.toolResult!['result']
                                          ?['success'] ==
                                      true
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                          if (message.toolResult!['result']?['content'] !=
                              null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${message.toolResult!['result']['content']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
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
                hintText:
                    _isStreaming ? 'Steve is typing...' : 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              enabled: !_isStreaming,
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            onPressed: _isStreaming ? null : _sendMessage,
            backgroundColor:
                _isStreaming ? Colors.grey[400] : Colors.deepPurple,
            elevation: 2,
            child: Icon(
              _isStreaming ? Icons.hourglass_top : Icons.send,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({Key? key}) : super(key: key);

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
      child: const Text(
        '|',
        style: TextStyle(
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
