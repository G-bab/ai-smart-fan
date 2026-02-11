import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  // 컨트롤러들
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController passwordConfirmController = TextEditingController();
  final TextEditingController birthController = TextEditingController();


  @override
  Widget build(BuildContext context) {


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
                labelText: "아이디 (영문이랑 숫자만 가능)",
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
                final email = emailController.text.trim();
                final name = nameController.text.trim();
                final birth = birthController.text.trim();
                final pw = passwordController.text.trim();
                final pwConfirm = passwordConfirmController.text.trim();

                if (email.isEmpty) {
                  _showSnack(context, "아이디를 입력해주세요");
                  return;
                }

                final idRegex = RegExp(r'^[a-zA-Z0-9]+$');
                if (!idRegex.hasMatch(email)) {
                  _showSnack(context, "아이디는 영문과 숫자만 가능합니다");
                  return;
                }


                if (name.isEmpty) {
                  _showSnack(context, "이름을 입력해주세요");
                  return;
                }

                if (birth.isEmpty) {
                  _showSnack(context, "생년월일을 선택해주세요");
                  return;
                }

                if (pw.isEmpty) {
                  _showSnack(context, "비밀번호를 입력해주세요");
                  return;
                }

                if (pwConfirm.isEmpty) {
                  _showSnack(context, "비밀번호 확인을 입력해주세요");
                  return;
                }

                if (pw != pwConfirm) {
                  _showSnack(context, "비밀번호가 일치하지 않습니다");
                  return;
                }

                final result = await ApiService.register(
                  email,
                  pw,
                  name,
                  birth,
                );

                if (result != null && result['user_id'] != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("회원가입 성공")),
                  );

                  Navigator.pushReplacementNamed(
                    context,
                    '/team',
                    arguments: result['user_id'],
                  );
                } else {
                  _showSnack(context, "회원가입 실패");
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

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

}
