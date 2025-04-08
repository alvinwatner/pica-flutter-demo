import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Render markdown even during streaming
                            _buildMarkdownContent(message.text),
                            
                            // Add the blinking cursor at the end
                            const BlinkingCursor(),
                          ],
                        )
                      : _buildMarkdownContent(message.text),
                  
                  // Tool Call Section
                  if (message.toolCall != null) ...[
                    const SizedBox(height: 12),
                    _buildToolCallCard(message.toolCall!),
                  ],
                  
                  // Tool Result Section
                  if (message.toolResult != null) ...[
                    const SizedBox(height: 12),
                    _buildToolResultCard(message.toolResult!),
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

  // Markdown content renderer
  Widget _buildMarkdownContent(String text) {
    return MarkdownBody(
      data: text,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 16, color: Colors.black87),
        code: TextStyle(
          backgroundColor: Colors.grey[200],
          fontFamily: 'monospace',
          fontSize: 14,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
        h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        blockquote: TextStyle(
          color: Colors.grey[700],
          fontStyle: FontStyle.italic,
          fontSize: 16,
        ),
      ),
    );
  }

  // Tool Call Card
  Widget _buildToolCallCard(Map<String, dynamic> toolCall) {
    final String toolName = toolCall['toolName'] ?? 'Unknown Tool';
    final Map<String, dynamic> args = toolCall['args'] ?? {};
    
    // Determine if this is a knowledge or action tool
    final bool isKnowledgeTool = 
        toolName == 'getAvailableActions' || 
        toolName == 'getActionKnowledge';
    
    return Card(
      elevation: 0,
      color: isKnowledgeTool ? Colors.blue[50] : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isKnowledgeTool ? Colors.blue[200]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tool Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isKnowledgeTool ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                toTitleCase(toolName),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isKnowledgeTool ? Colors.blue[800] : Colors.grey[800],
                ),
              ),
            ),
            
            // Only show args for non-knowledge tools if needed
            if (!isKnowledgeTool && args.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Using: ${_formatArgs(args)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Tool Result Card - handles both knowledge results and execute results
  Widget _buildToolResultCard(Map<String, dynamic> toolResult) {
    // Check if this is a knowledge result
    final bool isKnowledgeResult = _isKnowledgeResult(toolResult);
    
    if (isKnowledgeResult) {
      return _buildKnowledgeCard(toolResult);
    } else {
      return _buildExecuteResultCard(toolResult);
    }
  }

  // Knowledge Card for available actions and knowledge
  Widget _buildKnowledgeCard(Map<String, dynamic> result) {
    final Map<String, dynamic> rawResult = result['rawResult'] ?? {};
    final String platform = rawResult['platform'] ?? '';
    final List<dynamic> actions = rawResult['actions'] ?? [];
    
    return Card(
      elevation: 0,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.blue[200]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform Badge
            if (platform.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  platform,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            // Actions Count
            if (actions.isNotEmpty) ...[
              Text(
                '${actions.length} available actions',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Action Chips (show up to 5)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions.take(5).map<Widget>((action) {
                  final String actionName = action['name'] ?? 'Unknown';
                  return Chip(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.blue[200]!),
                    label: Text(
                      actionName,
                      style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                    ),
                  );
                }).toList(),
              ),
              
              // More indicator if there are more than 5 actions
              if (actions.length > 5) ...[
                const SizedBox(height: 4),
                Text(
                  '+ ${actions.length - 5} more',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // Execute Result Card
  Widget _buildExecuteResultCard(Map<String, dynamic> result) {
    final bool isSuccess = result['success'] == true;
    final String content = result['content'] ?? 'No details available';
    final Map<String, dynamic> rawResult = result['rawResult'] ?? {};
    final String action = rawResult['action'] ?? '';
    final String platform = rawResult['platform'] ?? '';
    
    return Card(
      elevation: 0,
      color: isSuccess ? Colors.green[50] : Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSuccess ? Colors.green[200]! : Colors.red[200]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isSuccess ? 'Success' : 'Failed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSuccess ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
                
                if (action.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    action,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                
                if (platform.isNotEmpty) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      platform,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            // Result Content
            if (content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to check if a result is a knowledge result
  bool _isKnowledgeResult(Map<String, dynamic> result) {
    final Map<String, dynamic> rawResult = result['rawResult'] ?? {};
    return rawResult.containsKey('actions') || 
           (rawResult.containsKey('action') && rawResult.containsKey('platform'));
  }

  // Helper method to format args for display
  String _formatArgs(Map<String, dynamic> args) {
    if (args.isEmpty) return '';
    
    // For simple args, just show them directly
    if (args.length == 1 && args.values.first is String) {
      return args.values.first;
    }
    
    // Otherwise show a simplified representation
    return args.keys.map((key) => '$key: ${_simplifyValue(args[key])}').join(', ');
  }

  // Helper to simplify values for display
  String _simplifyValue(dynamic value) {
    if (value is String) {
      return value.length > 20 ? '${value.substring(0, 20)}...' : value;
    } else if (value is Map || value is List) {
      return '...';
    } else {
      return value.toString();
    }
  }
  
  // Helper to convert camelCase or snake_case to Title Case
  String toTitleCase(String text) {
    if (text.isEmpty) return '';
    
    // Convert camelCase to space-separated words
    final String spacedText = text.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}'
    );
    
    // Convert snake_case to space-separated words
    final String normalizedText = spacedText.replaceAll(RegExp(r'[_-]'), ' ');
    
    // Capitalize each word
    return normalizedText
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
}
