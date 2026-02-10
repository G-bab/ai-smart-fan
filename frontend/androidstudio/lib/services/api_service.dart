import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = "https://auditor-nature-pupils-teeth.trycloudflare.com/api";

  // -----------------------------
  // 회원가입
  // -----------------------------
  static Future<Map<String, dynamic>?> register(
      String userId,
      String password,
      String name,
      String birthDate,
      ) async {
    final url = Uri.parse("$baseUrl/auth/register/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "password": password,
        "name": name,
        "birth_date": birthDate,
      }),
    );

    print("REGISTER STATUS: ${response.statusCode}");
    print("REGISTER BODY: ${response.body}");

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // -----------------------------
  // 로그인
  // -----------------------------
  static Future<Map<String, dynamic>?> login(
      String userId, String password) async {
    final url = Uri.parse("$baseUrl/auth/login/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "password": password,
      }),
    );

    print("LOGIN STATUS: ${response.statusCode}");
    print("LOGIN BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  // ==========================================================
  // 🔥 스마트팬 제어 관련 API (스마트팬스크린이 실제 사용하는 기능)
  // ==========================================================

  // -----------------------------
  // 1) 선풍기 상태 조회 (device_id = 1)
  // -----------------------------
  static Future<Map<String, dynamic>?> getDevice(int deviceId) async {
    final url = Uri.parse("$baseUrl/device/$deviceId/");

    final res = await http.get(url);

    print("GET DEVICE STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // -----------------------------
  // 2) 선풍기 상태 업데이트 (PATCH)
  // -----------------------------
  static Future<bool> updateDevice(int deviceId, Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl/device/$deviceId/");

    final res = await http.patch(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("PATCH DEVICE STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    return res.statusCode == 200;
  }

  // -----------------------------
  // 3) AI 제어 (POST /ai/control/)
  // -----------------------------
  static Future<Map<String, dynamic>?> controlAi(Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl/ai/control/");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("AI CONTROL STATUS: ${res.statusCode}");
    print("AI CONTROL BODY: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // -----------------------------
// 팀 생성
// -----------------------------
  static Future<Map<String, dynamic>?> createTeam(String teamName, String userId) async {
    final url = Uri.parse("$baseUrl/team/create/");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "team_name": teamName,
        "user_id": userId,
      }),
    );

    print("TEAM CREATE STATUS: ${res.statusCode}");
    print("TEAM CREATE BODY: ${res.body}");

    if (res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    return null;
  }

// -----------------------------
// 팀 참가
  static Future<Map<String, dynamic>?> joinTeam(String teamName, String userId) async {
    final url = Uri.parse("$baseUrl/team/join/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "team_name": teamName,
        "user_id": userId,
      }),
    );

    print("JOIN TEAM STATUS: ${response.statusCode}");
    print("JOIN TEAM BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }
}
