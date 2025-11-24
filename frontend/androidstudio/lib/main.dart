import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/smart_fan_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 스마트 선풍기',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Pretendard',
      ),

      // 앱 시작 화면
      initialRoute: '/login',

      // 라우트 등록
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => SignupPage(),          // const 제거 (오류 해결)
        '/fan': (context) => const SmartFanScreen(),
      },
    );
  }
}
