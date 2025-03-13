import 'package:flutter/material.dart';
import 'streaming_chat_interface.dart';

class StreamingChatDemo extends StatelessWidget {
  final String authToken;

  const StreamingChatDemo({
    Key? key,
    this.authToken =
        '', // Default empty token as it might not be needed for this demo
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamingChatInterface(
        authToken: authToken,
        apiUrl:
            'http://localhost:8000/hey-steve/chat/stream', // Update this URL to match your server
      ),
    );
  }
}
