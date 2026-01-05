import 'dart:io';

class AppConstants {
  // Android Emulator uses 10.0.2.2 for localhost
  // iOS Simulator uses localhost
  static String get baseUrl {
    if (Platform.isAndroid) {
      // 에뮬레이터 사용 시: 10.0.2.2
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static const String loginEndpoint = '/api/login';
  static const String logoutEndpoint = '/api/logout';
  static const String userProfileEndpoint = '/api/my/info';

  // OAuth2 Endpoints
  static const String kakaoLoginEndpoint = '/custom-oauth2/login/app/kakao';
}

