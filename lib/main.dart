import 'package:flutter/material.dart';
import 'package:pica_oauth_client/authkit_dialog.dart';
import 'package:pica_oauth_client/chat_interface.dart';
import 'package:pica_oauth_client/pica_streaming_chat.dart';

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
              'eyJhbGciOiJSUzI1NiIsImtpZCI6ImEwODA2N2Q4M2YwY2Y5YzcxNjQyNjUwYzUyMWQ0ZWZhNWI2YTNlMDkiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiQWx2aW4gU2V0aWFkaSIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJU1FRQk1wRmtpWk04RmtPejVUMmxrSTJ1eU0wRUcxUkp6U0c0NkRqLXF5ZHI1TFE9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vc3RldmUtZGV2LTQxZDAxIiwiYXVkIjoic3RldmUtZGV2LTQxZDAxIiwiYXV0aF90aW1lIjoxNzQxODczNDUxLCJ1c2VyX2lkIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3Iiwic3ViIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3IiwiaWF0IjoxNzQxODczNDUxLCJleHAiOjE3NDE4NzcwNTEsImVtYWlsIjoiYWx2aW5Ad2FsdHVybi5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJhbHZpbkB3YWx0dXJuLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.O6U4VoFZ8JAYuoidffykmfBy995ziPXlq_jtcl1sSkOMqxtNDrfRt4NRnAYsASrNuITn2L_yb05xlW3yzUW01numdMvGvEeEKROi-8N0tLOyaPt4yzotfGMKEwKJBWPJcRvwTfvN5oe4a-AxJ8d0qfq50nC9x6wW0rzdA29ES_N8zkKaNrma9aELpDhaHC4vaJfIHmGperxD4RDIYHXBPd-BKevcXQwtOnImowO9eZam70kl5Xa9iSbHahDE8XOLivzTQ5-M8rqhK6TpXGWpBl1HqwVH9O2HjKhxIBD6riyFQGGbJqe0297Nzpm2HcLQ1kxzBavGjrv4aN2VMOWlMw',
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
