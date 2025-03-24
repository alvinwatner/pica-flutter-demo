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
