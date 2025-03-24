import 'package:flutter/material.dart';

class WelcomeMessage extends StatelessWidget {
  final Function(String) onSuggestionSelected;

  const WelcomeMessage({
    Key? key,
    required this.onSuggestionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      onPressed: () => onSuggestionSelected(text),
    );
  }
}
