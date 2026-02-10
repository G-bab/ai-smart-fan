import 'package:flutter/material.dart';

class DeviceConnectPage extends StatelessWidget {
  const DeviceConnectPage({super.key});

  void _showTeamSelector(BuildContext context) {
    final teams = ["팀1", "팀2", "팀3"];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "팀 선택",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              ...teams.map(
                    (team) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$team 선택됨")),
                      );
                    },
                    child: Text(team),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, size: 30, color: Colors.black),
          onPressed: () => _showTeamSelector(context),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 제목
            const Text(
              '기기 연결',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 60),

            // 원형 아이콘
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE8F0FF),
                border: Border.all(
                  color: const Color(0xFF5B7CFA),
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.air,
                size: 80,
                color: Color(0xFF5B7CFA),
              ),
            ),

            const SizedBox(height: 30),

            // 안내 텍스트
            const Text(
              '연결 시작하기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 30),

            // 블루투스 연결 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 블루투스 연결 로직
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B7CFA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '블루투스 연결',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // ----------- 하단 네비게이션 바 -----------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,

        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/fan');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/device');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/team_manager');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/mypage');
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
