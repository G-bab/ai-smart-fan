import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TeamCreatePage extends StatefulWidget {
  final String userId;   // 🔥 로그인/회원가입 후 전달되는 user_id

  const TeamCreatePage({super.key, required this.userId});

  @override
  _TeamCreatePageState createState() => _TeamCreatePageState();
}

class _TeamCreatePageState extends State<TeamCreatePage> {
  final TextEditingController teamNameController = TextEditingController();
  final TextEditingController fanIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("팀 생성"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              "팀 생성",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: teamNameController,
              decoration: const InputDecoration(
                labelText: "팀 이름",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: fanIdController,
              decoration: const InputDecoration(
                labelText: "선풍기 ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: "비밀번호 설정",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () async {

                final res = await ApiService.createTeam(
                  teamName: teamNameController.text.trim(),
                  teamPassword: passwordController.text.trim(),
                  userId: widget.userId,
                  deviceId: fanIdController.text.trim(),
                );



                if (res != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("팀 생성 성공!")),
                  );

                  // 팀 생성 후 팬 화면 이동
                  Navigator.pushReplacementNamed(context, '/fan');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("팀 생성 실패")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "팀 생성하기",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
