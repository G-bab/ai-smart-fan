import 'package:flutter/material.dart';
import 'profile_edit_screen.dart';
import '../user_session.dart';
import '../services/api_service.dart';


class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  String? userId;
  String? userName;


  @override
  void initState() {
    super.initState();
    userId = UserSession.userId;// ✅ 로그인한 아이디 가져오기
    userName = UserSession.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "마이페이지",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // 프로필 카드
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // 프로필 이미지
                    Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD9D9D9),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // 아이디
                    Expanded(
                      child: Text(
                        "${userName ?? ""} (${userId ?? ""})",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    ),

                    // 편집 버튼
                    OutlinedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileEditScreen(currentId: userId ?? ""),
                          ),
                        );

                        if (result != null && result is String) {
                          setState(() {
                            userId = result;
                            UserSession.userId = result;
                          });
                        }
                      },
                      child: const Text("편집"),
                    )
                  ],
                ),
              ),

              const Spacer(),

              // 탈퇴하기
              Center(
                child: TextButton(
                  onPressed: () async {
                    if (userId == null) return;

                    final ok = await ApiService.withdraw(userId!);

                    if (ok) {
                      UserSession.clear();

                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                            (route) => false,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("탈퇴 실패")),
                      );
                    }
                  },


                  child: const Text(
                    "탈퇴하기",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // 하단바
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/fan');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/device');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/team_manager');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.devices), label: "기기"),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: "팀"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "MY"),
        ],
      ),
    );
  }
}
