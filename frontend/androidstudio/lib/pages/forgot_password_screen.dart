import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'reset_password_screen.dart';


// 날짜 자동 입력 formatter
class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 3 || i == 5) buffer.write('-');
    }

    final result = buffer.toString();

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  ForgotPasswordScreen({super.key});

  final idController = TextEditingController();
  final nameController = TextEditingController();
  final birthController = TextEditingController();
  final newPwController = TextEditingController();

  // 🔹 아이디 찾기
  Future<void> findId(BuildContext context) async {
    final response = await http.post(
      Uri.parse("http://YOUR_SERVER_URL/auth/find-id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": nameController.text.trim(),
        "birth": birthController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("아이디 찾기 결과"),
          content: Text("아이디는 ${data["userId"]} 입니다"),
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

  // 🔹 비밀번호 재설정
  Future<void> verifyUser(BuildContext context) async {
    final response = await http.post(
      Uri.parse("http://YOUR_SERVER_URL/auth/verify-user"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": idController.text.trim(),
        "name": nameController.text.trim(),
        "birth": birthController.text.trim(),
      }),
    );

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
            // 🔹 아이디 찾기 탭
            _buildFindIdTab(context),

            // 🔹 비밀번호 재설정 탭
            _buildResetPasswordTab(context),
          ],
        ),
      ),
    );
  }

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

          TextField(
            controller: birthController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              DateInputFormatter(),
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: const InputDecoration(
              labelText: "생년월일",
              hintText: "YYYY-MM-DD",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () => findId(context),
            child: const Text("아이디 찾기"),
          ),
        ],
      ),
    );
  }

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

            TextField(
              controller: birthController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                DateInputFormatter(),
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: "생년월일",
                hintText: "YYYY-MM-DD",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () => verifyUser(context),
              child: const Text("비밀번호 재설정"),
            ),

          ],
        ),
      ),
    );
  }
}
