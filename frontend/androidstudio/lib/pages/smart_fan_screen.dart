import 'dart:math';
import 'package:flutter/material.dart';

class SmartFanScreen extends StatefulWidget {
  const SmartFanScreen({super.key});

  @override
  State<SmartFanScreen> createState() => _SmartFanScreenState();
}

class _SmartFanScreenState extends State<SmartFanScreen>
    with SingleTickerProviderStateMixin {
  // UI 상태값들 (원래 있던 항목들)
  bool followMode = true;
  bool isRotating = false;
  double windLevel = 2; // 풍속 1~3
  int batteryLevel = 85;
  double temperature = 24.0;

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // 기본 duration은 2초 (중간 속도)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 배터리 아이콘 결정 함수
  IconData getBatteryIcon() {
    if (batteryLevel >= 90) return Icons.battery_full;
    if (batteryLevel >= 70) return Icons.battery_6_bar;
    if (batteryLevel >= 50) return Icons.battery_5_bar;
    if (batteryLevel >= 30) return Icons.battery_3_bar;
    if (batteryLevel >= 10) return Icons.battery_1_bar;
    return Icons.battery_alert;
  }

  // 풍속에 따라 애니메이션 속도(컨트롤러 duration) 적용
  void _applyRotationSpeed() {
    // windLevel: 1 => 느림, 2 => 보통, 3 => 빠름
    Duration newDuration;
    if (windLevel.round() == 1) {
      newDuration = const Duration(seconds: 4);
    } else if (windLevel.round() == 2) {
      newDuration = const Duration(seconds: 2);
    } else {
      // 3단
      newDuration = const Duration(seconds: 1);
    }

    // 변경 시 기존 애니메이션을 멈추고 새 duration 적용 후 필요 시 재생
    final wasRunning = _controller.isAnimating;
    _controller.stop();
    _controller.duration = newDuration;
    if (isRotating && wasRunning) {
      _controller.repeat();
    }
  }

  // 회전 토글
  void _toggleRotation() {
    setState(() {
      isRotating = !isRotating;
      if (isRotating) {
        // 배터리 감소(예시)
        batteryLevel = (batteryLevel - 5).clamp(0, 100);
        _applyRotationSpeed();
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  // AI 추천 (간단 예시: 랜덤 혹은 온도/배터리 기반 추천)
  void _applyAiRecommendation() {
    setState(() {
      // 예: 온도가 높으면 세게, 배터리가 낮으면 약하게
      if (batteryLevel < 20) {
        windLevel = 1;
      } else if (temperature >= 26.0) {
        windLevel = 3;
      } else {
        // 랜덤 추천 보조
        windLevel = (Random().nextInt(3) + 1).toDouble();
      }

      // 자동으로 회전 시작
      isRotating = true;
      _applyRotationSpeed();
      _controller.repeat();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("AI가 ${windLevel.round()}단 바람을 추천했습니다."),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // build에서 updateRotationSpeed 직접 호출하면 불필요한 호출 가능성 있으니
    // 풍속이 변경될 때마다 _applyRotationSpeed를 호출하도록 구현했음.

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 상단 타이틀 + 팔로우모드 스위치
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 타이틀 + 온도/배터리
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "AI 스마트 선풍기",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            "${temperature.toInt()}° ",
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            getBatteryIcon(),
                            color: Colors.black87,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "$batteryLevel%",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 팔로우 모드 스위치
                  Column(
                    children: [
                      Switch(
                        activeColor: Colors.blue,
                        value: followMode,
                        onChanged: (val) {
                          setState(() => followMode = val);
                        },
                      ),
                      const Text(
                        "팔로우모드",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 선풍기 이미지 (원래 이미지 사용)
              RotationTransition(
                turns: _controller.drive(Tween(begin: 0.0, end: 1.0)),
                child: Image.asset(
                  'assets/fan.png',
                  width: 200,
                  height: 200,
                ),
              ),

              const SizedBox(height: 12),

              // 회전 상태 텍스트
              Text(
                isRotating ? "회전 중" : "정지",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 28),

              // 풍속 라벨
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "풍속 : ${windLevel.round()}단",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // 풍속 슬라이더
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
                },
              ),

              const SizedBox(height: 32),

              // 회전 토글 + AI 추천 버튼
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor:
                      isRotating ? Colors.grey[200] : Colors.blue,
                      foregroundColor:
                      isRotating ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _toggleRotation,
                    child: Text(
                      isRotating ? "회전 OFF" : "회전 ON",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: Colors.lightBlueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
                    label: const Text(
                      "AI 맞춤 바람 추천",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _applyAiRecommendation,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
