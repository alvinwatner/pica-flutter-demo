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
            'eyJhbGciOiJSUzI1NiIsImtpZCI6IjMwYjIyMWFiNjU2MTdiY2Y4N2VlMGY4NDYyZjc0ZTM2NTIyY2EyZTQiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiQWx2aW4gU2V0aWFkaSIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJU1FRQk1wRmtpWk04RmtPejVUMmxrSTJ1eU0wRUcxUkp6U0c0NkRqLXF5ZHI1TFE9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vc3RldmUtZGV2LTQxZDAxIiwiYXVkIjoic3RldmUtZGV2LTQxZDAxIiwiYXV0aF90aW1lIjoxNzQyODIwNjc5LCJ1c2VyX2lkIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3Iiwic3ViIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3IiwiaWF0IjoxNzQyODIwNjc5LCJleHAiOjE3NDI4MjQyNzksImVtYWlsIjoiYWx2aW5Ad2FsdHVybi5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJhbHZpbkB3YWx0dXJuLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.PgNjRgJGA77PyNh2SX87kFmNzVYCFK5utecisfUoB1TtAJgMTVNKeBtYwPU8iifK9yYt5sJY6kXovWHqBmOlS0sKuMzJaYXijLxeE4-StJ_clz64U9Cj1Q9aCTwK8z6xlKo8KismirXRMvJwNZXWC1yKuGHNkXTgrc1VN4ECZ0dHDxsxCAs3m_Tav244wycLiEfUxOFx8NKDPSCyZF18wM5jcCmu3aQpgnwL_1GEY3UJUhAqAeV1zs1zRwshS-cG4GT1Zc2RmPSp3g1ruVpPaRg1i-13wfGwKXpBHYbrfRsW4yL_8D3fWrS9lPM7UR7Fjooa6O0Jfb6o56FoWJ3UrA',
      ),
    );
  }
}
