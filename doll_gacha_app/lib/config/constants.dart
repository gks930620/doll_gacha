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

  // 운영 서버 URL (Railway)
  static const String prodBaseUrl = 'https://dollcatch.store';

  // Auth Endpoints
  static const String loginEndpoint = '/api/login';
  static const String logoutEndpoint = '/api/logout';
  static const String userProfileEndpoint = '/api/my/info';
  static const String joinEndpoint = '/api/join';
  static const String refreshEndpoint = '/api/refresh/reissue';

  // OAuth2 Endpoints
  static const String kakaoLoginEndpoint = '/custom-oauth2/login/app/kakao';
  static const String googleLoginEndpoint = '/custom-oauth2/login/app/google';

  // DollShop Endpoints
  static const String dollShopsEndpoint = '/api/doll-shops';
  static const String dollShopsMapEndpoint = '/api/doll-shops/map';
  static const String dollShopsSearchEndpoint = '/api/doll-shops/search';

  // Review Endpoints
  static const String reviewsEndpoint = '/api/reviews';
  static String reviewsByShopEndpoint(int shopId) => '/api/reviews/doll-shop/$shopId';
  static String reviewStatsEndpoint(int shopId) => '/api/reviews/doll-shop/$shopId/stats';

  // Community Endpoints
  static const String communityEndpoint = '/api/community';

  // Comment Endpoints
  static const String commentsEndpoint = '/api/comments';
  static String commentsByCommunityEndpoint(int communityId) => '/api/comments/community/$communityId';

  // File Endpoints
  static const String filesEndpoint = '/api/files';
  static const String fileUploadEndpoint = '/api/files/upload';
  static const String fileDownloadEndpoint = '/api/files/download';

  // Default image
  static const String defaultShopImage = '/images/default-shop.png';
}
