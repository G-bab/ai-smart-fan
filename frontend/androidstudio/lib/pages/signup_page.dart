import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 컨트롤러 추가
    final TextEditingController emailController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController passwordConfirmController = TextEditingController();
    final TextEditingController birthController = TextEditingController();


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("회원가입"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // 아이디
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "아이디",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 이름
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "이름",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 생년월일
            TextField(
              controller: birthController,
              readOnly: true, // 직접 입력 막기
              decoration: const InputDecoration(
                labelText: "생년월일",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime(2000), // 기본 선택 날짜
                  firstDate: DateTime(1900),   // 최소 연도
                  lastDate: DateTime.now(),    // 오늘까지만 선택
                );

                if (pickedDate != null) {
                  birthController.text =
                  "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                }
              },
            ),
            const SizedBox(height: 16),

            // 비밀번호
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: "비밀번호",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // 비밀번호 확인
            TextField(
              controller: passwordConfirmController,
              decoration: const InputDecoration(
                labelText: "비밀번호 확인",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 32),

            // 🔹 가입하기 버튼
            ElevatedButton(
              onPressed: () async {
                // 비밀번호 확인 체크
                if (passwordController.text != passwordConfirmController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("비밀번호가 일치하지 않습니다.")),
                  );
                  return;
                }

                final result = await ApiService.register(
                  emailController.text.trim(),   // user_id
                  passwordController.text.trim(),
                  nameController.text.trim(),    // name
                  birthController.text.trim(),   // birth_date
                );


                if (result != null && result['user_id'] != null) {
                  final String userId = result['user_id']; // 👈 여기서 userId 정의

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("회원가입 성공")),
                  );

                  Navigator.pushReplacementNamed(
                    context,
                    '/team',
                    arguments: userId,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("회원가입 실패")),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                "가입하기",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
