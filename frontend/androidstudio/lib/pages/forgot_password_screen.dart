import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final idController = TextEditingController();
  final nameController = TextEditingController();
  final birthController = TextEditingController();

  static const String baseUrl =
      "https://occupational-evaluate-granny-cartoon.trycloudflare.com/api";

  // 🔹 아이디 찾기
  Future<void> findId(BuildContext context) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/find-id/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": nameController.text.trim(),
        "birth_date": birthController.text.trim(),
      }),
    );

    print("FIND ID STATUS: ${response.statusCode}");
    print("FIND ID BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("아이디 찾기 결과"),
          content: Text("아이디는 ${data["user_id"]} 입니다"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
    } else {
      _showFail(context);
    }
  }

  // 🔹 비밀번호 재설정 → 검증 성공 시 새 비밀번호 입력 화면 이동
  Future<void> verifyUser(BuildContext context) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/reset-password/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": idController.text.trim(),
        "name": nameController.text.trim(),
        "birth_date": birthController.text.trim(),
        "new_password": "temp", // 임시값 (다음 화면에서 실제 변경)
      }),
    );

    print("VERIFY STATUS: ${response.statusCode}");
    print("VERIFY BODY: ${response.body}");

    if (response.statusCode == 200) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            userId: idController.text.trim(),
            name: nameController.text.trim(),
            birth: birthController.text.trim(),
          ),
        ),
      );
    } else {
      _showFail(context);
    }
  }

  void _showFail(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("실패"),
        content: const Text("일치하는 회원 정보가 없습니다"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  // 🔹 날짜 선택 위젯
  Widget _buildDatePicker(BuildContext context) {
    return TextField(
      controller: birthController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: "생년월일",
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );

        if (pickedDate != null) {
          birthController.text =
          "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("계정 찾기"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "아이디 찾기"),
              Tab(text: "비밀번호 재설정"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFindIdTab(context),
            _buildResetPasswordTab(context),
          ],
        ),
      ),
    );
  }

  // 🔹 아이디 찾기
  Widget _buildFindIdTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "이름",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          _buildDatePicker(context),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () => findId(context),
            child: const Text("아이디 찾기"),
          ),
        ],
      ),
    );
  }

  // 🔹 비밀번호 재설정
  Widget _buildResetPasswordTab(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: idController,
              decoration: const InputDecoration(
                labelText: "아이디",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "이름",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            _buildDatePicker(context),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () => verifyUser(context),
              child: const Text("다음"),
            ),
          ],
        ),
      ),
    );
  }
}
