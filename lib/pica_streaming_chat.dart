import 'package:flutter/material.dart';
import 'streaming_chat_interface.dart';

class PicaStreamingChat extends StatelessWidget {
  final String authToken;

  const PicaStreamingChat({
    Key? key,
    required this.authToken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PicaOS Streaming Chat'),
        backgroundColor: Colors.purple[800],
      ),
      body: StreamingChatInterface(
        authToken: authToken,
        apiUrl: 'http://localhost:8000/hey-steve/chat/pica-openai-stream',
      ),
    );
  }
}
