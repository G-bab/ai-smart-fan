class UserSession {
  static String userId = "";      // 로그인 아이디
  static String name = "";        // 사용자 이름
  static int selectedTeamId = 1;

  static void clear() {
    userId = "";
    name = "";
    selectedTeamId = 1;
  }
}
