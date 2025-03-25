import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final String baseUrl = 'http://127.0.0.1:8000';
  late final Dio _dio;

  ChatService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      responseType: ResponseType.stream,
    ));
  }

  /// Sends a message to the chat API and returns a stream of responses
  Stream<Map<String, dynamic>> sendMessage({
    required String message,
    required String authToken,
  }) async* {
    try {
      final response = await _dio.post<ResponseBody>(
        '/hey-steve/chat/pica-stream',
        data: {'message': message},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
            'Accept': 'text/event-stream',
            'Cache-Control': 'no-cache',
          },
          responseType: ResponseType.stream,
        ),
      );

      debugPrint('Sending request to: ${response.requestOptions.uri}');
      debugPrint('Request body: ${response.requestOptions.data}');

      // Transform Uint8List to List<int>
      final uint8Transformer =
          StreamTransformer<Uint8List, List<int>>.fromHandlers(
        handleData: (data, sink) {
          sink.add(List<int>.from(data));
        },
      );

      // Get the response stream and transform it
      final responseStream = response.data!.stream
          .transform(uint8Transformer)
          .transform(utf8.decoder);

      String bufferChunk = '';

      await for (var chunk in responseStream) {
        debugPrint('Received chunk: $chunk');

        // Append chunk to buffer
        bufferChunk += chunk;

        // Process complete lines (each SSE message is a line starting with "data: ")
        while (bufferChunk.contains('\n\n')) {
          final parts = bufferChunk.split('\n\n');
          final completeLine = parts[0]; // Get the complete line
          bufferChunk =
              parts.sublist(1).join('\n\n'); // Keep the rest in buffer

          // Process the line if it starts with "data: "
          if (completeLine.startsWith('data: ')) {
            final dataContent =
                completeLine.substring(6); // Remove "data: " prefix

            // Check for the end of stream marker
            if (dataContent == "[DONE]") {
              yield {'type': 'done'};
              return;
            }

            // Make sure we have a valid format (letter followed by colon)
            if (dataContent.length < 2 || dataContent[1] != ':') {
              debugPrint('Invalid format: $dataContent');
              continue;
            }

            final eventType = dataContent[0];
            String data = dataContent.substring(2);

            switch (eventType) {
              case 'p': // Platform authentication URL
                try {
                  final parsed = jsonDecode(data);
                  if (parsed.containsKey('data')) {
                    final authUrl = parsed['data'];
                    yield {
                      'type': 'auth_url',
                      'url': authUrl,
                    };
                  }
                } catch (e) {
                  debugPrint('Error parsing platform authentication URL: $e');
                }
                break;

              case 'f': // Message ID
                try {
                  final parsed = jsonDecode(data);
                  yield {
                    'type': 'message_id',
                    'messageId': parsed['messageId'],
                  };
                } catch (e) {
                  debugPrint('Error parsing message ID: $e');
                }
                break;

              case '9': // Tool Call
                try {
                  final parsed = jsonDecode(data);
                  Map<String, dynamic> toolCallData = parsed;
                  if (!toolCallData.containsKey('toolName')) {
                    toolCallData['toolName'] = 'unknown';
                  }
                  yield {
                    'type': 'tool_call',
                    'toolCall': toolCallData,
                  };
                } catch (e) {
                  debugPrint('Error parsing tool call: $e');
                }
                break;

              case 'a': // Tool Result
                try {
                  final parsed = jsonDecode(data);
                  yield {
                    'type': 'tool_result',
                    'toolResult': parsed,
                  };
                } catch (e) {
                  debugPrint('Error parsing tool result: $e');
                }
                break;

              case '0': // Text content
                if (data.isNotEmpty) {
                  try {
                    String cleanedText = data;
                    if (data.startsWith('"') &&
                        data.endsWith('"') &&
                        data.length >= 2) {
                      cleanedText = data.substring(1, data.length - 1);
                    }
                    cleanedText = cleanedText
                        .replaceAll('\\"', '"')
                        .replaceAll('\\n', '\n')
                        .replaceAll('\\r', '\r')
                        .replaceAll('\\\\', '\\');

                    debugPrint('Processed text chunk: "$cleanedText"');
                    yield {
                      'type': 'text',
                      'content': cleanedText,
                    };
                  } catch (e) {
                    debugPrint(
                        'Error processing text content: $e - will use raw data');
                    yield {
                      'type': 'text',
                      'content': data,
                    };
                  }
                }
                break;

              case 'e': // End of message
                try {
                  final parsed = jsonDecode(data);
                  debugPrint('End of message: ${parsed['finishReason']}');
                  yield {
                    'type': 'end_message',
                    'finishReason': parsed['finishReason'],
                    'isContinued': parsed['isContinued'] ?? true,
                  };
                } catch (e) {
                  debugPrint('Error parsing end of message: $e');
                }
                break;

              case 'd': // End of conversation
                try {
                  final parsed = jsonDecode(data);
                  yield {
                    'type': 'end_conversation',
                    'finishReason': parsed['finishReason'],
                  };
                } catch (e) {
                  debugPrint('Error parsing end of conversation: $e');
                }
                break;

              default:
                debugPrint('Unknown event type: $eventType');
                break;
            }
          }
        }

        // Handle special case for the last [DONE] message
        if (bufferChunk == 'data: [DONE]') {
          yield {'type': 'done'};
          bufferChunk = '';
        }
      }
    } on DioException catch (e) {
      debugPrint('Dio error: ${e.message}');
      if (e.response != null) {
        throw Exception(
            'Failed to send message: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Failed to send message: ${e.message}');
      }
    }
  }

  /// Extracts connection ID from the auth URL
  String? extractConnectionId(String authUrl) {
    try {
      Uri uri = Uri.parse(authUrl);
      return uri.queryParameters['connection-id'];
    } catch (e) {
      debugPrint('Error extracting connection ID: $e');
      return null;
    }
  }

  /// Polls the connection status endpoint
  Future<Map<String, dynamic>> checkConnectionStatus({
    required String connectionId,
    required String authToken,
  }) async {
    try {
      final response = await _dio.get(
        '/hey-steve/connection-status',
        queryParameters: {'connection_id': connectionId},
        options: Options(
          headers: {'Authorization': 'Bearer $authToken'},
          responseType: ResponseType.json,
        ),
      );
      return response.data;
    } on DioException catch (e) {
      debugPrint('Dio error checking connection status: ${e.message}');
      throw Exception(
          'Failed to check connection status: ${e.response?.statusCode ?? e.message}');
    }
  }

  /// Returns the reconnect URL for a connection
  String getReconnectUrl(String connectionId) {
    return '$baseUrl/hey-steve/reconnect?connection_id=$connectionId';
  }

  void dispose() {
    _dio.close();
  }
}
