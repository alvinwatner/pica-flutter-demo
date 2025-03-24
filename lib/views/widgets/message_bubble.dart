import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/chat_message.dart';
import '../../viewmodels/chat_viewmodel.dart';
import 'blinking_cursor.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showCursor;
  final ChatViewModel viewModel;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.showCursor,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                                child: BlinkingCursor(),
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

  // Better tool result display
  Widget _buildToolResultDisplay(Map<String, dynamic>? toolResult) {
    if (toolResult == null) return Container();

    // Extract result data, handling different structure possibilities
    bool isSuccess = viewModel.getToolResultSuccessful(toolResult);
    String content =
        viewModel.getToolResultContent(toolResult) ?? 'No details available';

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
}
