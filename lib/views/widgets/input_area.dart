import 'package:flutter/material.dart';

class InputArea extends StatelessWidget {
  final TextEditingController textController;
  final bool isStreaming;
  final VoidCallback onSend;

  const InputArea({
    Key? key,
    required this.textController,
    required this.isStreaming,
    required this.onSend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              controller: textController,
              decoration: InputDecoration(
                hintText:
                    isStreaming ? 'Steve is typing...' : 'Type a message...',
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
              onSubmitted: (_) => onSend(),
              enabled: !isStreaming,
            ),
          ),
          const SizedBox(width: 8.0),
          FloatingActionButton(
            onPressed: isStreaming ? null : onSend,
            backgroundColor:
                isStreaming ? Colors.grey[400] : Colors.deepPurple,
            elevation: 2,
            child: Icon(
              isStreaming ? Icons.hourglass_top : Icons.send,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
