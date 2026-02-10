import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TeamJoinPage extends StatefulWidget {
  final String userId;   // 🔥 로그인한 사용자 ID

  const TeamJoinPage({super.key, required this.userId});

  @override
  _TeamJoinPageState createState() => _TeamJoinPageState();
}

class _TeamJoinPageState extends State<TeamJoinPage> {
  final TextEditingController teamNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("팀 참가"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "팀 참가",
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

            TextField(
              controller: teamNameController,
              decoration: const InputDecoration(
                labelText: "비밀번호",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () async {
                final res = await ApiService.joinTeam(
                  teamNameController.text.trim(),
                  widget.userId,
                );

                if (res != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("팀 참가 성공")),
                  );

                  Navigator.pushReplacementNamed(context, '/fan');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("팀 참가 실패")),
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
                "신청하기",
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
