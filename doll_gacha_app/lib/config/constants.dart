class AppConstants {
  // 운영 서버 URL (Railway)
  static const String baseUrl = 'https://dollgacha-production.up.railway.app';

  // Google OAuth2 Web Client ID (서버와 동일)
  // Google Cloud Console에서 발급받은 Web Client ID
  static const String googleWebClientId = '117898675158-q8av68g6rm9d91988m8umlvjm5u3gnp0.apps.googleusercontent.com';

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
