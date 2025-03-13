import 'package:flutter/material.dart';
import 'package:pica_oauth_client/authkit_dialog.dart';
import 'package:pica_oauth_client/chat_interface.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  Future<void> _openAuthKitDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AuthKitDialog(
        onAuthSuccess: (authData) {
          debugPrint("Auth Success: $authData");
        },
      ),
    );

    if (result != null) {
      debugPrint("AuthKit Response: $result");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connected: $result")),
      );
    }
  }

  void _openChatInterface(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatInterface(
          authToken:
              'eyJhbGciOiJSUzI1NiIsImtpZCI6ImJjNDAxN2U3MGE4MWM5NTMxY2YxYjY4MjY4M2Q5OThlNGY1NTg5MTkiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiQWx2aW4gU2V0aWFkaSIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJU1FRQk1wRmtpWk04RmtPejVUMmxrSTJ1eU0wRUcxUkp6U0c0NkRqLXF5ZHI1TFE9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vc3RldmUtZGV2LTQxZDAxIiwiYXVkIjoic3RldmUtZGV2LTQxZDAxIiwiYXV0aF90aW1lIjoxNzQxNzc3MjY0LCJ1c2VyX2lkIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3Iiwic3ViIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3IiwiaWF0IjoxNzQxNzc3MjY0LCJleHAiOjE3NDE3ODA4NjQsImVtYWlsIjoiYWx2aW5Ad2FsdHVybi5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJhbHZpbkB3YWx0dXJuLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.vBO-Jyn0xvZctDGRa3kdX4TiRImGwWgDCwznNVYs0q6heddL3Ywza0F6bJ9zQAnULIY3Ko3r-1VMHvQavjJRyO_YXklUpnP3qE29qPfovnSMiTX2xu3Xiu0zTtg7t76Kicm6EULluEISbKJAcXy2xbz3AfGah05JdDh5guIRx4eyWPdNVXAAPyCfBaBuRX4T2dzjeMJezeuU6rbs4909DV71jnc4UuZTQ9UH49h0C52IFNjIYhJnDjjohq5ThHhtWrBhznjAxI1ttJ6YTaGCuwOuWbtMP_9O7s_luA8sXjDO98Uz3zGhuKxLtvt78AfLvDBQVw4H2vOMivUeIqpIoQ',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _openAuthKitDialog(context),
              child: const Text("Connect Tools"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _openChatInterface(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text("Open Chat Interface"),
            ),
          ],
        ),
      ),
    );
  }
}
