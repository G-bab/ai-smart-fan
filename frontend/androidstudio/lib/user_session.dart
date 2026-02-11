class UserSession {
  static String userId = "";
  static String name = "";

  static int? selectedTeamId;
  static String? selectedTeamName;
  static String? selectedDeviceId;

  static void clear() {
    userId = "";
    name = "";
    selectedTeamId = null;
    selectedTeamName = null;
    selectedDeviceId = null;
  }
}
