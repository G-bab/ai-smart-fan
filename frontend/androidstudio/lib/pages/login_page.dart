import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'signup_page.dart';
import '../user_session.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TextField 컨트롤러 추가
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "로그인",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // 아이디 TextField
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "아이디",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 비밀번호 TextField
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: "비밀번호",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            // 로그인 버튼 → API 연동
            ElevatedButton(
              onPressed: () async {
                final result = await ApiService.login(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                );

                if (result != null && result['user_id'] != null) {
                  // ✅ 로그인한 아이디 저장
                  UserSession.userId = result['user_id'];
                  UserSession.name = result['name'];

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("로그인 성공")),
                  );

                  Navigator.pushReplacementNamed(context, '/fan');
                }
                else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("로그인 실패")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "로그인",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/forgot_password');
              },
              child: const Text(
                "아이디 찾기/비밀번호 재설정",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("계정이 없으신가요? "),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text(
                    "회원가입",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
