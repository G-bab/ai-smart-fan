import 'package:contant/pages/profile_edit_screen.dart';
import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'pages/forgot_password_screen.dart';
import 'pages/signup_page.dart';
import 'pages/smart_fan_screen.dart';
import 'pages/team_page.dart';
import 'pages/team_create_page.dart';
import 'pages/team_join_page.dart';
import 'pages/team_manage_screen.dart';
import 'pages/my_page.dart';
import 'pages/device_connect_page.dart';

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
        '/forgot_password': (context) => ForgotPasswordScreen(),
        '/signup': (context) => SignupPage(),          // const 제거 (오류 해결)

        '/fan': (context) => const SmartFanScreen(),
        '/device': (context) => const DeviceConnectPage(),
        '/team': (context) => const TeamPage(),

        '/team_create': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String;
          return TeamCreatePage(userId: userId);
        },
        '/team_join': (context) {
          final userId = ModalRoute.of(context)!.settings.arguments as String;
          return TeamJoinPage(userId: userId);
        },

        '/team_manager': (context) => const TeamManagerPage(),
        '/mypage' : (context) => const MyPage(),
      },
    );
  }
}
