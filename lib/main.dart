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
            'eyJhbGciOiJSUzI1NiIsImtpZCI6IjcxMTE1MjM1YTZjNjE0NTRlZmRlZGM0NWE3N2U0MzUxMzY3ZWViZTAiLCJ0eXAiOiJKV1QifQ.eyJuYW1lIjoiQWx2aW4gU2V0aWFkaSIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NJU1FRQk1wRmtpWk04RmtPejVUMmxrSTJ1eU0wRUcxUkp6U0c0NkRqLXF5ZHI1TFE9czk2LWMiLCJpc3MiOiJodHRwczovL3NlY3VyZXRva2VuLmdvb2dsZS5jb20vc3RldmUtZGV2LTQxZDAxIiwiYXVkIjoic3RldmUtZGV2LTQxZDAxIiwiYXV0aF90aW1lIjoxNzQ0MDk5MTE4LCJ1c2VyX2lkIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3Iiwic3ViIjoiNjcxYjY5MWEyYTdkOGI4YjFlNzY2MzU3IiwiaWF0IjoxNzQ0MDk5MTE4LCJleHAiOjE3NDQxMDI3MTgsImVtYWlsIjoiYWx2aW5Ad2FsdHVybi5jb20iLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiZmlyZWJhc2UiOnsiaWRlbnRpdGllcyI6eyJlbWFpbCI6WyJhbHZpbkB3YWx0dXJuLmNvbSJdfSwic2lnbl9pbl9wcm92aWRlciI6InBhc3N3b3JkIn19.AKRHvD3vrZKkKBWop-WhabGK6NsIK2J9BqhhBkf38cfXj3ZKkVnAEz_8Tuq4RzLY_ysqA0i9RYaMbE8AyMPuGxk_HYDbsbIk4mNlTinJEn1tHUbQ2rSlooik1ZN1DTzjmh_XDgeLq3l8ZocNXDBU89AH9BM8ZctlwjFwr2SbZTPv67wBham2STF6WSZWWaswrbNGEPLHuXzzDenpNQ6WK_my2NZaAl7xC7Othh2L4qOtQIJcxr557xPiLFr3AeGvFzRZu7s6hpE-tbge_FMG1f70zHGjrplcOGFYwufKFEarYzDZhysKwxXCKSTFJ5d-CxmPkFVOofHOUS3-yymlkQ',
      ),
    );
  }
}
