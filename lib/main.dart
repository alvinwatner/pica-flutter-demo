import 'package:flutter/material.dart';
import 'package:pica_oauth_client/authkit_dialog.dart';
import 'package:pica_oauth_client/chat_interface.dart';
import 'package:pica_oauth_client/pica_streaming_chat.dart';
import 'package:pica_oauth_client/streaming_chat_demo.dart';

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
              'eyJhbGciOiJSUzI1NiIsImtpZCI6ImJjNDAxN2U3MGE4MWM5NTMxY2YxYjY4MjY4M2Q5OThlNGY1NTg5MTkiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiQWx2aW4gU2V0aWFkaSIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJU1FRQk1wRmtpWk04RmtPejVUMmxrSTJ1eU0wRUcxUkp6U0c0NkRqLXF5ZHI1TFE9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vc3RldmUtZGV2LTQxZDAxIiwiYXVkIjoic3RldmUtZGV2LTQxZDAxIiwiYXV0aF90aW1lIjoxNzQxODY5MjM2LCJ1c2VyX2lkIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3Iiwic3ViIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3IiwiaWF0IjoxNzQxODY5MjM2LCJleHAiOjE3NDE4NzI4MzYsImVtYWlsIjoiYWx2aW5Ad2FsdHVybi5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJhbHZpbkB3YWx0dXJuLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.uyDgAjw-z3kGHabKZ_xeeEh64kUB_YGTixnu9J7AsS_L3YQy1Hysag73Ottsc-gJiOcRkkR-nVPhVT2BkEd0MnVE2RWdPbQm2ti3uinLfklcUGlDStRUYZ0LbLrS6bPsJwne1Sxkbl4uztmeZOkqhn3pd3aR_wEgALCqTEsJfCPxF4yabzcQKETQdP1PGfOHg06mxfEp6xZYmuGqzlUm_Sx0MUcybJ12creuqoUJ6iN0MM3YcA3u940pN4nIT3BTdMPA7o3aDgxsvAFfZTV_qW4EBUAPIU2ibIG1-JvLwWrcgfkEBndaFvuCE1WVmKjwd8voye8a4T77y7VkkGrAtg',
        ),
      ),
    );
  }

  void _openStreamingChatDemo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => StreamingChatDemo(
                authToken:
                    'eyJhbGciOiJSUzI1NiIsImtpZCI6ImJjNDAxN2U3MGE4MWM5NTMxY2YxYjY4MjY4M2Q5OThlNGY1NTg5MTkiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiQWx2aW4gU2V0aWFkaSIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJU1FRQk1wRmtpWk04RmtPejVUMmxrSTJ1eU0wRUcxUkp6U0c0NkRqLXF5ZHI1TFE9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vc3RldmUtZGV2LTQxZDAxIiwiYXVkIjoic3RldmUtZGV2LTQxZDAxIiwiYXV0aF90aW1lIjoxNzQxODU0NTc4LCJ1c2VyX2lkIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3Iiwic3ViIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3IiwiaWF0IjoxNzQxODU0NTc4LCJleHAiOjE3NDE4NTgxNzgsImVtYWlsIjoiYWx2aW5Ad2FsdHVybi5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJhbHZpbkB3YWx0dXJuLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.pyEzKeV55MqlF6_qA6JbI_guKGG0cAV7WskQhFjzM9Bu_pWRcGvVWqTm4IRTxVgr08oq5shtShbx0vhKQQ9_X1N7Tc6zAnASeNtVS8-7T9uavaf3nNdOOKVeBJ5fbywDrNexnttcA2hsPf242cZ0THS2_0b3j0Kg55Iahu8sDlx77Ftmet1slKJZWM7q6j3uHFipTcw42XYgMagKAgX0zIN-ZI6dFvFrS0FBcMZj1zBiz7xCi9hQ8cp2Atb4woYnj1wgDtUNbVhCZTqseZvC2cQzQBHEbu9aaNJcPUdMV0HUzZ7mcwmlMk8XYtMzVvUWKMvDeGc9KTH_wlZNqUu5oA',
              )),
    );
  }

  void _openPicaStreamingChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PicaStreamingChat(
          authToken:
              'eyJhbGciOiJSUzI1NiIsImtpZCI6ImJjNDAxN2U3MGE4MWM5NTMxY2YxYjY4MjY4M2Q5OThlNGY1NTg5MTkiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiQWx2aW4gU2V0aWFkaSIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJU1FRQk1wRmtpWk04RmtPejVUMmxrSTJ1eU0wRUcxUkp6U0c0NkRqLXF5ZHI1TFE9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vc3RldmUtZGV2LTQxZDAxIiwiYXVkIjoic3RldmUtZGV2LTQxZDAxIiwiYXV0aF90aW1lIjoxNzQxODU0NTc4LCJ1c2VyX2lkIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3Iiwic3ViIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3IiwiaWF0IjoxNzQxODU0NTc4LCJleHAiOjE3NDE4NTgxNzgsImVtYWlsIjoiYWx2aW5Ad2FsdHVybi5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJhbHZpbkB3YWx0dXJuLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.pyEzKeV55MqlF6_qA6JbI_guKGG0cAV7WskQhFjzM9Bu_pWRcGvVWqTm4IRTxVgr08oq5shtShbx0vhKQQ9_X1N7Tc6zAnASeNtVS8-7T9uavaf3nNdOOKVeBJ5fbywDrNexnttcA2hsPf242cZ0THS2_0b3j0Kg55Iahu8sDlx77Ftmet1slKJZWM7q6j3uHFipTcw42XYgMagKAgX0zIN-ZI6dFvFrS0FBcMZj1zBiz7xCi9hQ8cp2Atb4woYnj1wgDtUNbVhCZTqseZvC2cQzQBHEbu9aaNJcPUdMV0HUzZ7mcwmlMk8XYtMzVvUWKMvDeGc9KTH_wlZNqUu5oA',
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _openStreamingChatDemo(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Open Streaming Chat Demo"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _openPicaStreamingChat(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[800],
                foregroundColor: Colors.white,
              ),
              child: const Text("Open PicaOS Streaming Chat"),
            ),
          ],
        ),
      ),
    );
  }
}
