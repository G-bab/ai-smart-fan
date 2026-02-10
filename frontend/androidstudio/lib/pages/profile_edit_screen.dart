import 'package:flutter/material.dart';
import '../user_session.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.currentId});

  final String currentId;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController idController;
  bool isEditingId = false;

  @override
  void initState() {
    super.initState();
    idController = TextEditingController(text: widget.currentId);
  }

  @override
  @override
  void dispose() {
    idController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단바
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, size: 28),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "프로필 편집",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 프로필 이미지
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD9D9D9),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "사진 수정",
                        style: TextStyle(color: Colors.blue, fontSize: 16),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 아이디 수정 영역
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("아이디", style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 5),

                            isEditingId
                                ? TextField(
                              controller: idController,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            )
                                : Text(
                              idController.text,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            if (isEditingId) {
                              FocusScope.of(context).unfocus();

                              // ✅ 세션 아이디 업데이트
                              UserSession.userId = idController.text;

                              // ✅ 이전 화면(MyPage)으로 결과 전달
                              Navigator.pop(context, idController.text);
                            }
                            isEditingId = !isEditingId;
                          });
                        },
                        child: Text(isEditingId ? "저장" : "편집"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // 로그아웃 버튼
                InkWell(
                  onTap: () {
                    UserSession.clear();

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                          (route) => false,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 14),
                        Text("로그아웃", style: TextStyle(fontSize: 18)),
                        Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

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
          } else if (index == 3) {

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
