import 'package:flutter/material.dart';

class TeamPage extends StatelessWidget {
  const TeamPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 회원가입/로그인에서 전달된 userId 받아오기
    final args = ModalRoute.of(context)?.settings.arguments;
    final userId = args is String ? args : "";

    if (userId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("잘못된 접근입니다")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("팀 선택"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 팀 생성 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/team_create',arguments: userId,);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(260, 56),
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                "팀 생성",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 24),

            // 팀 참가 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/team_join',arguments: userId,);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(260, 56),
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                "팀 참가",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
