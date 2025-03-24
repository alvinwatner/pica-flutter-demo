import 'package:flutter/material.dart';
import 'package:pica_oauth_client/authkit_dialog.dart';
import 'package:provider/provider.dart';

import '../viewmodels/chat_viewmodel.dart';
import 'widgets/input_area.dart';
import 'widgets/message_bubble.dart';
import 'widgets/welcome_message.dart';

class ChatInterfaceView extends StatefulWidget {
  final String authToken;

  const ChatInterfaceView({
    Key? key,
    required this.authToken,
  }) : super(key: key);

  @override
  State<ChatInterfaceView> createState() => _ChatInterfaceViewState();
}

class _ChatInterfaceViewState extends State<ChatInterfaceView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatViewModel _viewModel;
  bool _isShowingAuthDialog = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel(authToken: widget.authToken);

    // Set up auth URL listener once
    _viewModel.addListener(_handleViewModelUpdate);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_handleViewModelUpdate);
    _textController.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _handleViewModelUpdate() {
    if (!mounted) return;

    // Handle auth URL events only
    if (_viewModel.currentEvent?['type'] == 'auth_url' &&
        !_isShowingAuthDialog) {
      final authUrl = _viewModel.currentEvent!['url'];
      final connectionId = _viewModel.currentEvent!['connectionId'];
      if (connectionId != null) {
        _handleAuthUrl(authUrl, connectionId);
      }
    }
  }

  void _handleAuthUrl(String authUrl, String connectionId) {
    _isShowingAuthDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Start polling with the dialog context after dialog is shown
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _viewModel.startPollingConnectionStatus(connectionId);
        });

        // Set up a listener specifically for this dialog
        void handleStatusChange() {
          if (_viewModel.connectionStatus != null) {
            final status = _viewModel.connectionStatus!;
            if (status == 'success' || status == 'error' || status == 'close') {
              Navigator.of(dialogContext).pop(); // Use dialogContext to close
              _isShowingAuthDialog = false;
              _viewModel
                  .removeListener(handleStatusChange); // Clean up this listener
            }
          }
        }

        _viewModel.addListener(handleStatusChange);

        return AuthKitDialog(
          previewUrl: authUrl,
          onAuthSuccess: (authData) {
            debugPrint("Auth Success callback received: $authData");
            // We don't need to do anything here as we'll poll the status endpoint
          },
          onClose: () {
            // Just stop polling when dialog is closed
            _viewModel.stopPollingConnectionStatus();
            _isShowingAuthDialog = false;
            _viewModel
                .removeListener(handleStatusChange); // Clean up this listener
            debugPrint('Auth dialog closed by user');
          },
        );
      },
    );
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

  void _sendMessage() async {
    final message = _textController.text.trim();
    if (message.isEmpty) return;

    _textController.clear();
    await _viewModel.sendMessage(message);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ChatViewModel>(
        builder: (context, viewModel, child) {
          // Listen for scroll updates
          if (viewModel.messages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }

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
                    child: viewModel.messages.isEmpty
                        ? WelcomeMessage(
                            onSuggestionSelected: (suggestion) {
                              _textController.text = suggestion;
                              _sendMessage();
                            },
                          )
                        : NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollEndNotification) {
                                // You can add logic here to detect when user has scrolled
                                // and maybe show a "scroll to bottom" button
                              }
                              return false;
                            },
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: viewModel.messages.length,
                              itemBuilder: (context, index) {
                                final message = viewModel.messages[index];
                                final bool isLastMessage =
                                    index == viewModel.messages.length - 1;
                                final bool showCursor = isLastMessage &&
                                    !message.isUser &&
                                    viewModel.isStreaming;

                                return MessageBubble(
                                  message: message,
                                  showCursor: showCursor,
                                  viewModel: viewModel,
                                );
                              },
                            ),
                          ),
                  ),
                ),
                if (viewModel.isStreaming &&
                    viewModel.messages.isNotEmpty &&
                    !viewModel.messages.last.isUser)
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
                InputArea(
                  textController: _textController,
                  isStreaming: viewModel.isStreaming,
                  onSend: _sendMessage,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
