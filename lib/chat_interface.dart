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

  // Buffer for accumulating SSE chunks
  String _bufferChunk = '';

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
        Uri.parse('http://127.0.0.1:8000/hey-steve/chat/pica-stream'),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.authToken}',
      });

      // Format the request to match API expectations
      request.body = jsonEncode({
        "message": message // Use the actual user message
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

        // Reset buffer before processing new stream
        _bufferChunk = '';

        // Process the stream
        await for (var chunk in stream) {
          debugPrint('Received chunk: $chunk');

          // Append chunk to buffer
          _bufferChunk += chunk;

          // Process complete lines (each SSE message is a line starting with "data: ")
          while (_bufferChunk.contains('\n\n')) {
            final parts = _bufferChunk.split('\n\n');
            final completeLine = parts[0]; // Get the complete line
            _bufferChunk =
                parts.sublist(1).join('\n\n'); // Keep the rest in buffer

            // Process the line if it starts with "data: "
            if (completeLine.startsWith('data: ')) {
              final dataContent =
                  completeLine.substring(6); // Remove "data: " prefix
              await _processStreamChunk(dataContent);
            }
          }

          // Handle special case for the last [DONE] message
          if (_bufferChunk == 'data: [DONE]') {
            setState(() {
              _isStreaming = false;
              _isLoading = false;
            });
            _bufferChunk = '';
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

  Future<void> _processStreamChunk(String line) async {
    try {
      // Check for the end of stream marker
      if (line == "[DONE]") {
        setState(() {
          _isStreaming = false;
          _isLoading = false;
        });
        return;
      }

      // Make sure we have a valid format (letter followed by colon)
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
              // Store the previous message ID in case we need it
              final String? prevMessageId = _currentMessageId;
              _currentMessageId = parsed['messageId'];

              // If this is a new message ID and we have content,
              // we should consider starting a new message
              if (prevMessageId != null &&
                  prevMessageId != _currentMessageId &&
                  _currentAssistantMessage.isNotEmpty) {
                // Update the last message with current content
                if (_messages.isNotEmpty && !_messages.last.isUser) {
                  _messages[_messages.length - 1] = ChatMessage(
                    text: _currentAssistantMessage,
                    isUser: false,
                    messageId: prevMessageId,
                    toolCall: _currentToolCall,
                    toolResult: _currentToolResult,
                  );
                }

                // Reset state for new message
                _currentAssistantMessage = '';
                _currentToolCall = null;
                _currentToolResult = null;
              }

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
            // Make sure we have a valid toolCall even if structure varies
            Map<String, dynamic> toolCallData = parsed;

            // Set defaults for missing fields if necessary
            if (!toolCallData.containsKey('toolName')) {
              toolCallData['toolName'] = 'unknown';
            }

            await _updateToolCall(toolCallData);
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
            try {
              // Different approach to handle the text tokens
              String cleanedText = data;

              // If it's in quotes but not valid JSON, just strip the quotes
              if (data.startsWith('"') &&
                  data.endsWith('"') &&
                  data.length >= 2) {
                cleanedText = data.substring(1, data.length - 1);
                // No additional JSON parsing, which was causing errors
              }

              // Unescape common escape sequences
              cleanedText = cleanedText
                  .replaceAll('\\"', '"')
                  .replaceAll('\\n', '\n')
                  .replaceAll('\\r', '\r')
                  .replaceAll('\\\\', '\\');

              debugPrint('Processed text chunk: "$cleanedText"');

              // Update the message with this chunk
              await _updateAssistantMessage(cleanedText);

              // Force UI update
              setState(() {});
            } catch (e) {
              debugPrint(
                  'Error processing text content: $e - will use raw data');
              // Still try to use the raw data even if parsing failed
              await _updateAssistantMessage(data);
            }
          }
          break;

        case 'e': // End of message
          try {
            final parsed = jsonDecode(data);
            debugPrint('End of message: ${parsed['finishReason']}');

            // If we have isContinued: false, we know the current message is complete
            if (parsed.containsKey('isContinued') &&
                parsed['isContinued'] == false) {
              // We may need to start a new message after this
              // But we'll wait for the next 'f' message to do that
            }
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

    // Call scroll to bottom here to update UI as text comes in
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

// Better tool result display
  Widget _buildToolResultDisplay(Map<String, dynamic>? toolResult) {
    if (toolResult == null) return Container();

    // Extract result data, handling different structure possibilities
    bool isSuccess = _getToolResultSuccessful(toolResult);
    String content =
        _getToolResultContent(toolResult) ?? 'No details available';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isSuccess ? Colors.green[200]! : Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Result: ${isSuccess ? 'Success' : 'Failed'}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isSuccess ? Colors.green[700] : Colors.red[700],
            ),
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              content,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

// Improved tool result handling
  Future<void> _updateToolResult(Map<String, dynamic> toolResult) async {
    // Use a Completer to make this function awaitable
    final completer = Completer<void>();

    setState(() {
      _currentToolResult = toolResult;

      // Create a normalized version of the tool result
      Map<String, dynamic> normalizedResult = {};

      // Extract success status regardless of where it is in the structure
      bool isSuccess = false;
      String? content;

      if (toolResult.containsKey('result')) {
        // Handle string result that needs parsing
        if (toolResult['result'] is String) {
          try {
            Map<String, dynamic> parsedResult =
                jsonDecode(toolResult['result']);
            isSuccess = parsedResult['success'] == true;
            content = parsedResult['content']?.toString();
            normalizedResult = {
              'success': isSuccess,
              'content': content,
              'rawResult': parsedResult
            };
          } catch (e) {
            debugPrint('Error parsing result string: $e');
            isSuccess = false;
            normalizedResult = {
              'success': false,
              'content': 'Error parsing result',
              'rawResult': toolResult['result']
            };
          }
        }
        // Handle object result
        else if (toolResult['result'] is Map<String, dynamic>) {
          Map<String, dynamic> resultObj = toolResult['result'];
          isSuccess = resultObj['success'] == true;
          content = resultObj['content']?.toString();
          normalizedResult = {
            'success': isSuccess,
            'content': content,
            'rawResult': resultObj
          };
        }
      } else {
        // Direct structure
        isSuccess = toolResult['success'] == true;
        content = toolResult['content']?.toString();
        normalizedResult = {
          'success': isSuccess,
          'content': content,
          'rawResult': toolResult
        };
      }

      _currentToolResult = normalizedResult;

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
                            'Tool: ${message.toolCall!['toolName'] ?? 'unknown'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Args: ${jsonEncode(message.toolCall!['args'] ?? {})}',
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
                    _buildToolResultDisplay(message.toolResult),
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

  // Helper methods for better error handling of tool results
  String _getToolResultStatus(Map<String, dynamic>? toolResult) {
    if (toolResult == null) return 'Unknown';

    try {
      // Handle different result structures
      if (toolResult.containsKey('result')) {
        final result = toolResult['result'];
        if (result is Map<String, dynamic> && result.containsKey('success')) {
          return result['success'] == true ? 'Success' : 'Failed';
        }
      }

      // Fallback if structure is different
      return toolResult.containsKey('success') && toolResult['success'] == true
          ? 'Success'
          : 'Failed';
    } catch (e) {
      debugPrint('Error getting tool result status: $e');
      return 'Unknown';
    }
  }

  bool _getToolResultSuccessful(Map<String, dynamic>? toolResult) {
    if (toolResult == null) return false;

    try {
      // Handle different result structures
      if (toolResult.containsKey('result')) {
        final result = toolResult['result'];
        if (result is Map<String, dynamic> && result.containsKey('success')) {
          return result['success'] == true;
        }
      }

      // Fallback if structure is different
      return toolResult.containsKey('success') && toolResult['success'] == true;
    } catch (e) {
      debugPrint('Error checking if tool result successful: $e');
      return false;
    }
  }

  String? _getToolResultContent(Map<String, dynamic>? toolResult) {
    if (toolResult == null) return null;

    try {
      // Handle different result structures
      if (toolResult.containsKey('result')) {
        final result = toolResult['result'];
        if (result is Map<String, dynamic> && result.containsKey('content')) {
          return result['content']?.toString();
        }
      }

      // Fallback if structure is different
      return toolResult.containsKey('content')
          ? toolResult['content']?.toString()
          : null;
    } catch (e) {
      debugPrint('Error getting tool result content: $e');
      return null;
    }
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
