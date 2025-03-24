import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  final String authToken;

  // State variables
  final List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isStreaming = false;
  String currentAssistantMessage = '';
  String? currentMessageId;
  Map<String, dynamic>? currentToolCall;
  Map<String, dynamic>? currentToolResult;
  String lastUserMessage = '';
  Map<String, dynamic>? currentEvent;
  String? connectionStatus;

  // For connection status polling
  Timer? connectionStatusTimer;

  ChatViewModel({required this.authToken});

  @override
  void dispose() {
    stopPollingConnectionStatus();
    super.dispose();
  }

  // Add a message to the chat
  void addUserMessage(String message) {
    if (message.isEmpty) return;

    // Store for potential resending
    lastUserMessage = message;

    // Add user message
    messages.add(ChatMessage(
      text: message,
      isUser: true,
    ));

    // Add empty assistant message
    messages.add(ChatMessage(
      text: '',
      isUser: false,
    ));

    isLoading = true;
    isStreaming = true;
    currentAssistantMessage = '';
    currentMessageId = null;
    currentToolCall = null;
    currentToolResult = null;

    notifyListeners();
  }

  // Send message to API
  Future<void> sendMessage(String message) async {
    if (message.isEmpty) return;

    addUserMessage(message);

    try {
      final stream = _chatService.sendMessage(
        message: message,
        authToken: authToken,
      );

      await for (final event in stream) {
        await processStreamEvent(event);
      }

      isLoading = false;
      isStreaming = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending message: $e');

      // Remove empty assistant message if it exists
      if (messages.isNotEmpty &&
          !messages.last.isUser &&
          messages.last.text.isEmpty) {
        messages.removeLast();
      }

      // Add error message
      messages.add(ChatMessage(
        text: 'Error: $e',
        isUser: false,
      ));

      isLoading = false;
      isStreaming = false;
      notifyListeners();
    }
  }

  // Process stream events from the API
  Future<void> processStreamEvent(Map<String, dynamic> event) async {
    currentEvent = event;
    final eventType = event['type'];

    switch (eventType) {
      case 'done':
        isStreaming = false;
        isLoading = false;
        notifyListeners();
        break;

      case 'auth_url':
        final authUrl = event['url'];
        debugPrint('Received platform authentication URL: $authUrl');

        // Extract connection ID
        String? connectionId = _chatService.extractConnectionId(authUrl);
        if (connectionId != null) {
          debugPrint('Extracted connection ID: $connectionId');
          event['connectionId'] = connectionId;

          // Mark streaming as complete since we're handling auth separately
          isStreaming = false;
          isLoading = false;
          notifyListeners();
        } else {
          debugPrint('Could not extract connection ID from URL: $authUrl');
        }
        break;

      case 'message_id':
        final String? prevMessageId = currentMessageId;
        currentMessageId = event['messageId'];

        // If this is a new message ID and we have content,
        // we should consider starting a new message
        if (prevMessageId != null &&
            prevMessageId != currentMessageId &&
            currentAssistantMessage.isNotEmpty) {
          // Update the last message with current content
          if (messages.isNotEmpty && !messages.last.isUser) {
            messages[messages.length - 1] = ChatMessage(
              text: currentAssistantMessage,
              isUser: false,
              messageId: prevMessageId,
              toolCall: currentToolCall,
              toolResult: currentToolResult,
            );
          }

          // Reset state for new message
          currentAssistantMessage = '';
          currentToolCall = null;
          currentToolResult = null;
        }

        // Update the message with the new message ID
        if (messages.isNotEmpty && !messages.last.isUser) {
          messages[messages.length - 1] = ChatMessage(
            text: currentAssistantMessage,
            isUser: false,
            messageId: currentMessageId,
            toolCall: currentToolCall,
            toolResult: currentToolResult,
          );
        }

        notifyListeners();
        break;

      case 'tool_call':
        await updateToolCall(event['toolCall']);
        break;

      case 'tool_result':
        await updateToolResult(event['toolResult']);
        break;

      case 'text':
        await updateAssistantMessage(event['content']);
        break;

      case 'end_message':
        // Handle end of message
        debugPrint('End of message: ${event['finishReason']}');
        break;

      case 'end_conversation':
        isStreaming = false;
        isLoading = false;
        notifyListeners();
        break;
    }

    notifyListeners();
  }

  // Handle authentication URL
  void _handleAuthUrl(Map<String, dynamic> event) {
    // This is just a notification - the view will handle showing the dialog
    // Mark streaming as complete since we're handling auth separately
    isStreaming = false;
    isLoading = false;
    notifyListeners();
  }

  // Update assistant message with new content
  Future<void> updateAssistantMessage(String content) async {
    if (content.isEmpty) return;

    currentAssistantMessage += content;

    // Update the last message if it's from the assistant
    if (messages.isNotEmpty && !messages.last.isUser) {
      messages[messages.length - 1] = ChatMessage(
        text: currentAssistantMessage,
        isUser: false,
        messageId: currentMessageId,
        toolCall: currentToolCall,
        toolResult: currentToolResult,
      );
    }

    notifyListeners();
  }

  // Update tool call data
  Future<void> updateToolCall(Map<String, dynamic> toolCall) async {
    currentToolCall = toolCall;

    // Update the last message if it's from the assistant
    if (messages.isNotEmpty && !messages.last.isUser) {
      messages[messages.length - 1] = ChatMessage(
        text: currentAssistantMessage,
        isUser: false,
        messageId: currentMessageId,
        toolCall: currentToolCall,
        toolResult: currentToolResult,
      );
    }

    notifyListeners();
  }

  // Update tool result data
  Future<void> updateToolResult(Map<String, dynamic> toolResult) async {
    // Create a normalized version of the tool result
    Map<String, dynamic> normalizedResult = {};

    // Extract success status regardless of where it is in the structure
    bool isSuccess = false;
    String? content;

    if (toolResult.containsKey('result')) {
      // Handle string result that needs parsing
      if (toolResult['result'] is String) {
        try {
          Map<String, dynamic> parsedResult = jsonDecode(toolResult['result']);
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

    currentToolResult = normalizedResult;

    // Update the last message if it's from the assistant
    if (messages.isNotEmpty && !messages.last.isUser) {
      messages[messages.length - 1] = ChatMessage(
        text: currentAssistantMessage,
        isUser: false,
        messageId: currentMessageId,
        toolCall: currentToolCall,
        toolResult: currentToolResult,
      );
    }

    notifyListeners();
  }

  // Start polling for connection status
  void startPollingConnectionStatus(String connectionId) {
    // Cancel any existing timer
    stopPollingConnectionStatus();

    debugPrint('Starting to poll connection status for ID: $connectionId');

    // Start a new timer to poll every 2 seconds
    connectionStatusTimer =
        Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final data = await _chatService.checkConnectionStatus(
          connectionId: connectionId,
          authToken: authToken,
        );

        final status = data['status'];
        debugPrint('Connection status: $status');
        connectionStatus = status;

        if (status == 'success') {
          // Stop polling
          stopPollingConnectionStatus();

          // Add success message
          messages.add(ChatMessage(
            text: "✅ Successfully connected to platform",
            isUser: false,
          ));

          notifyListeners();

          // Resend the last user message after a small delay
          if (lastUserMessage.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 300), () {
              sendMessage(lastUserMessage);
            });
          }
        } else if (status == 'error' || status == 'close') {
          // Stop polling and notify view to close dialog
          stopPollingConnectionStatus();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error polling connection status: $e');
        connectionStatus = 'error';
        notifyListeners();
      }
    });
  }

  void stopPollingConnectionStatus() {
    connectionStatusTimer?.cancel();
    connectionStatusTimer = null;
  }

  // Helper methods for tool results
  String getToolResultStatus(Map<String, dynamic>? toolResult) {
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

  bool getToolResultSuccessful(Map<String, dynamic>? toolResult) {
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

  String? getToolResultContent(Map<String, dynamic>? toolResult) {
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

  // Get reconnect URL
  String getReconnectUrl(String connectionId) {
    return _chatService.getReconnectUrl(connectionId);
  }
}
