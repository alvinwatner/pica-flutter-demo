import 'package:flutter/material.dart';

import 'package:pica_oauth_client/views/chat_interface_view.dart';

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
      home: const ChatInterfaceView(
        authToken:
            'eyJhbGciOiJSUzI1NiIsImtpZCI6IjMwYjIyMWFiNjU2MTdiY2Y4N2VlMGY4NDYyZjc0ZTM2NTIyY2EyZTQiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiQWx2aW4gU2V0aWFkaSIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJU1FRQk1wRmtpWk04RmtPejVUMmxrSTJ1eU0wRUcxUkp6U0c0NkRqLXF5ZHI1TFE9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vc3RldmUtZGV2LTQxZDAxIiwiYXVkIjoic3RldmUtZGV2LTQxZDAxIiwiYXV0aF90aW1lIjoxNzQyODczNTUxLCJ1c2VyX2lkIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3Iiwic3ViIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3IiwiaWF0IjoxNzQyODczNTUxLCJleHAiOjE3NDI4NzcxNTEsImVtYWlsIjoiYWx2aW5Ad2FsdHVybi5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJhbHZpbkB3YWx0dXJuLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.EZo8KCuT8jiRYeiDdrY9FTK9uA1INchoIsgGfkIHsqhphQAPBcK2CIiarfhJ7kbmOU_WaCgNUW1n6JYrgYwkN1Ww8aT3whFxIo_eO7D8fFh0YhofiU3MzyaXRf0Mhq0XNa47Ai36aHeYqD-44ik_wQ5JBM8adg07rwqW9PzrXvJewISv4koEi17ODtW7s_6XMRZUibVPopec1qXaUn6eU04FYFRc0W364bsurg544pcXiWLTi7x2FE2F5BplfCy_ciRdCK5burNFoh4pkoxtjzgJMHhwfEJ1CQOEUP_sHec0P9NzP9xSkm2dVw2CAI-rS9jxHNCeuPP8ccTEV0i8SA',
      ),
    );
  }
}
