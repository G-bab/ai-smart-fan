import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../user_session.dart';

class SmartFanScreen extends StatefulWidget {
  const SmartFanScreen({super.key});

  @override
  State<SmartFanScreen> createState() => _SmartFanScreenState();
}

class _SmartFanScreenState extends State<SmartFanScreen>
    with SingleTickerProviderStateMixin {
  bool followMode = true;
  bool isRotating = false;
  double windLevel = 2;
  int batteryLevel = 85;
  double temperature = 24.0;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _loadFanStatus();
  }

  // -------------------------------------------
  // 🔥 서버에서 선풍기 현재 상태 가져오기 (device_id = 1)
  // -------------------------------------------
  Future<void> _loadFanStatus() async {
    final data = await ApiService.getDevice(1);

    if (data != null) {
      setState(() {
        windLevel = (data["fan_speed"] ?? 1).toDouble();
        isRotating = data["power_state"] ?? false;
        temperature = (data["temperature"] ?? 24.0).toDouble();

        if (isRotating) _controller.repeat();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData getBatteryIcon() {
    if (batteryLevel >= 90) return Icons.battery_full;
    if (batteryLevel >= 70) return Icons.battery_6_bar;
    if (batteryLevel >= 50) return Icons.battery_5_bar;
    if (batteryLevel >= 30) return Icons.battery_3_bar;
    if (batteryLevel >= 10) return Icons.battery_1_bar;
    return Icons.battery_alert;
  }

  void _applyRotationSpeed() {
    Duration newDuration;
    if (windLevel.round() == 1) newDuration = const Duration(seconds: 4);
    else if (windLevel.round() == 2) newDuration = const Duration(seconds: 2);
    else newDuration = const Duration(seconds: 1);

    final wasRunning = _controller.isAnimating;
    _controller.stop();
    _controller.duration = newDuration;
    if (isRotating && wasRunning) _controller.repeat();
  }

  // -------------------------------------------
  // 🔥 회전 ON/OFF → 서버에 PATCH 전송
  // -------------------------------------------
  void _toggleRotation() async {
    setState(() {
      isRotating = !isRotating;
      if (isRotating) {
        batteryLevel = (batteryLevel - 5).clamp(0, 100);
        _applyRotationSpeed();
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });

    await ApiService.updateDevice(1, {
      "power_state": isRotating,
      "fan_speed": windLevel.round(),
    });
  }

  // -------------------------------------------
  // 🔥 AI 맞춤 추천 → 서버 AI API 연동
  // -------------------------------------------
  void _applyAiRecommendation() async {
    final body = {
      "mode": followMode ? "follow" : "auto",
      "user_x": 120, // 임시값 (추후 실제 값 사용 가능)
      "temperature": temperature,
      "voice_command": null
    };

    final res = await ApiService.controlAi(body);

    if (res != null) {
      setState(() {
        if (res["fan_speed"] != null) {
          windLevel = (res["fan_speed"]).toDouble();
        }

        isRotating = true;
        _applyRotationSpeed();
        _controller.repeat();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI 추천: ${windLevel.round()}단 바람")),
      );

      await ApiService.updateDevice(1, {
        "power_state": isRotating,
        "fan_speed": windLevel.round(),
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("AI 추천 실패")),
      );
    }
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
          onPressed: () {
            _showTeamSelector(context);
          },
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- UI 그대로 유지 ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "AI 스마트 선풍기",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text("${temperature.toInt()}° ",
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                          Icon(getBatteryIcon(), color: Colors.black87, size: 22),
                          const SizedBox(width: 4),
                          Text("$batteryLevel%",
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Switch(
                        activeColor: Colors.blue,
                        value: followMode,
                        onChanged: (val) => setState(() => followMode = val),
                      ),
                      const Text("팔로우모드", style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              RotationTransition(
                turns: _controller.drive(Tween(begin: 0.0, end: 1.0)),
                child: Image.asset('assets/fan.png', width: 200, height: 200),
              ),

              const SizedBox(height: 12),
              Text(isRotating ? "회전 중" : "정지",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("풍속 : ${windLevel.round()}단",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
                ],
              ),
              Slider(
                value: windLevel,
                min: 1,
                max: 3,
                divisions: 2,
                activeColor: Colors.blue,
                inactiveColor: Colors.grey[300],
                onChanged: (value) {
                  setState(() {
                    windLevel = value;
                    _applyRotationSpeed();
                  });

                  ApiService.updateDevice(1, {
                    "fan_speed": windLevel.round(),
                    "power_state": isRotating,
                  });
                },
              ),

              const SizedBox(height: 32),

              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: isRotating ? Colors.grey[200] : Colors.blue,
                      foregroundColor: isRotating ? Colors.black : Colors.white,
                      shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _toggleRotation,
                    child: Text(
                      isRotating ? "회전 OFF" : "회전 ON",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: Colors.lightBlueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
                    label: const Text(
                      "AI 맞춤 바람 추천",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    onPressed: _applyAiRecommendation,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/fan');
          else if (index == 1) Navigator.pushReplacementNamed(context, '/device');
          else if (index == 2) Navigator.pushReplacementNamed(context, '/team_manager');
          else if (index == 3) Navigator.pushReplacementNamed(context, '/mypage');
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
                      setState(() {
                        UserSession.selectedTeamId =
                        team == "Team A" ? 1 : team == "Team B" ? 2 : 3;
                      });

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("$team 선택됨")),
                      );
                    },


                    child: Text(
                      team,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
