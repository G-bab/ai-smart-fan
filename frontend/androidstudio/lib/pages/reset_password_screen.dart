import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPasswordScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String birth;

  const ResetPasswordScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.birth,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // 🔥 서버 주소
  final String baseUrl = "http://YOUR_SERVER_URL";

  Future<void> resetPassword() async {
    final newPw = newPasswordController.text.trim();
    final confirmPw = confirmPasswordController.text.trim();

    if (newPw.isEmpty || confirmPw.isEmpty) {
      _showDialog("오류", "비밀번호를 모두 입력해주세요");
      return;
    }

    if (newPw != confirmPw) {
      _showDialog("오류", "비밀번호가 일치하지 않습니다");
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.userId,
          "name": widget.name,
          "birth": widget.birth,
          "new_password": newPw,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["message"] == "비밀번호 변경 성공") {
          _showDialog("완료", "비밀번호가 재설정되었습니다", success: true);
        } else {
          _showDialog("실패", data["message"] ?? "비밀번호 재설정 실패");
        }
      } else {
        _showDialog("실패", "서버 오류 (${response.statusCode})");
      }
    } catch (e) {
      _showDialog("오류", "네트워크 오류 발생");
    }
  }

  void _showDialog(String title, String message, {bool success = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (success) {
                Navigator.pop(context); // 이전 화면으로
              }
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("비밀번호 재설정"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "새 비밀번호",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "비밀번호 확인",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: resetPassword,
                child: const Text("비밀번호 재설정"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
