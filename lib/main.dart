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
        previewUrl: 'http://localhost:3000',
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
              'eyJhbGciOiJSUzI1NiIsImtpZCI6IjMwYjIyMWFiNjU2MTdiY2Y4N2VlMGY4NDYyZjc0ZTM2NTIyY2EyZTQiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiQWx2aW4gU2V0aWFkaSIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJU1FRQk1wRmtpWk04RmtPejVUMmxrSTJ1eU0wRUcxUkp6U0c0NkRqLXF5ZHI1TFE9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vc3RldmUtZGV2LTQxZDAxIiwiYXVkIjoic3RldmUtZGV2LTQxZDAxIiwiYXV0aF90aW1lIjoxNzQyODA5NzEyLCJ1c2VyX2lkIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3Iiwic3ViIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3IiwiaWF0IjoxNzQyODA5NzEyLCJleHAiOjE3NDI4MTMzMTIsImVtYWlsIjoiYWx2aW5Ad2FsdHVybi5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJhbHZpbkB3YWx0dXJuLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.MHbOTmxLdKtobr01W2jBDaNvK2qDYqnCxDTjw9aPxRun-rqds-UK3dlI67QqpKAIcFjFqomgjSK76D85sGKilIzOJf3MJHwkIwkm_F715OagaEU7yCJ4xUd3628_BX25wyorjSCfyy6lnCv2-M3PUVJdYEkSiQuSXzVQOqVTAR97M8SFu8SqQjYeXN7iv3ZfIqe6qE4rmPSejXWY3ImmP0o6MVXj3UZMGSX7DkG3fDAwzF23MWgd7DpuEVnlfvAJuXYs5Y-S_J7pQepHXgGkc7nlXVSV8ox5QgPXAQqEoJCDIrUMLW0GYvPi5lLH6vz0Y3IVxNtEdkyWNbjWCOtnLg',
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
