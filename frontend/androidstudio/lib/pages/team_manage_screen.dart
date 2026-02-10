import 'package:flutter/material.dart';
import '../user_session.dart';

class TeamManagerPage extends StatefulWidget {
  const TeamManagerPage({super.key});

  @override
  State<TeamManagerPage> createState() => _TeamManagerPageState();
}

class _TeamManagerPageState extends State<TeamManagerPage> {
  String searchQuery = "";

  final Map<int, List<Map<String, String>>> teamMembers = {
    1: [
      {"name": "김민준", "role": "관리자"},
      {"name": "이서연", "role": "멤버"},
    ],
    2: [
      {"name": "박지호", "role": "관리자"},
      {"name": "최예린", "role": "멤버"},
    ],
    3: [
      {"name": "정도현", "role": "관리자"},
      {"name": "한지민", "role": "멤버"},
    ],
  };

  void _showTeamSelector(BuildContext context) {
    final teams = [1, 2, 3];

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
                    (teamId) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        UserSession.selectedTeamId = teamId;
                      });
                      Navigator.pop(context);
                    },
                    child: Text("팀 $teamId"),
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
    final currentTeamId = UserSession.selectedTeamId;
    final members = teamMembers[currentTeamId] ?? [];

    final filteredMembers = members
        .where((m) => m["name"]!.contains(searchQuery))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, size: 30, color: Colors.black),
          onPressed: () => _showTeamSelector(context),
        ),
        title: const Text(
          "팀 관리",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        automaticallyImplyLeading: false,
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "멤버 검색",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final member = filteredMembers[index];

                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  margin:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundImage:
                        AssetImage("assets/default_profile.png"),
                      ),

                      const SizedBox(width: 16),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member["name"]!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member["role"]!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/fan');
          if (index == 1) Navigator.pushReplacementNamed(context, '/device');
          if (index == 3) Navigator.pushReplacementNamed(context, '/mypage');
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
