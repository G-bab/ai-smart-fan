import 'package:flutter/material.dart';
import 'signup_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
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

            const TextField(
              decoration: InputDecoration(
                labelText: "아이디",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            const TextField(
              decoration: InputDecoration(
                labelText: "비밀번호",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            // 🔹 로그인 버튼 (살짝 둥글고 글씨 흰색)
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/fan');
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
                  color: Colors.white, // ← 흰색
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () {},
              child: const Text(
                "비밀번호를 잊으셨나요?",
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
