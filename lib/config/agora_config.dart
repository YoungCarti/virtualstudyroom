class AgoraConfig {
  // TODO: Replace with your Agora App ID from https://console.agora.io/
  static const String appId = 'd3acf04f1a754ad2a024f913b0498454';
  
  // For production, set this to true and implement token server
  static const bool useToken = false;
  
  // Optional: Token server URL (for production with authentication)
  static const String tokenServerUrl = '';
  
  // Default channel prefix for group calls
  // Removes spaces and special characters from channel name
  static String getChannelName(String classCode, String groupId) {
    // Remove spaces and special characters, only allow alphanumeric and underscores
    final sanitizedClassCode = classCode.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    final sanitizedGroupId = groupId.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    return 'studyroom_${sanitizedClassCode}_$sanitizedGroupId';
  }
}
