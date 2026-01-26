import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' as kakao;
import '../config/constants.dart';
import '../models/user_model.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();

  // Keys for storage
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  // Login with username and password
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle both snake_case (JwtLoginFilter) and camelCase (OAuth2LoginSuccessHandler)
        String? accessToken = data['access_token'] ?? data['accessToken'] ?? data['token'];
        String? refreshToken = data['refresh_token'] ?? data['refreshToken'];

        if (accessToken != null) {
          await _storage.write(key: _accessTokenKey, value: accessToken);
          if (refreshToken != null) {
            await _storage.write(key: _refreshTokenKey, value: refreshToken);
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (token != null) {
        await http.post(
          Uri.parse('${AppConstants.baseUrl}${AppConstants.logoutEndpoint}'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      // Always clear tokens on client side
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    }
  }

  // Get User Profile
  Future<User?> getUserProfile() async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.userProfileEndpoint}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
          'Accept-Charset': 'utf-8',
        },
      );

      if (response.statusCode == 200) {
        // UTF-8로 명시적 디코딩
        final responseBody = utf8.decode(response.bodyBytes);
        final json = jsonDecode(responseBody);
        // ApiResponse 형식: { data: {...} }
        final data = json['data'] ?? json;
        return User.fromJson(data);
      }
    } catch (e) {
      print('Get profile error: $e');
    }
    return null;
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null;
  }

  // Save token manually (for OAuth2)
  Future<void> saveToken(String accessToken, {String? refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  // Google Sign-In (Native)
  Future<bool> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: AppConstants.googleWebClientId,  // ID Token을 받기 위해 필요
      );

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        print('Google sign-in cancelled');
        return false;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      final String? accessToken = auth.accessToken;

      if (idToken == null && accessToken == null) {
        print('No tokens from Google');
        return false;
      }

      // 서버에 Google 토큰 전송하여 JWT 토큰 받기
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/oauth2/google/app'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'idToken': idToken,
          'accessToken': accessToken,
          'email': account.email,
          'displayName': account.displayName,
          'id': account.id,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);

        // data 필드가 있으면 그 안에서, 없으면 직접
        final tokenData = data['data'] ?? data;
        String? jwtAccessToken = tokenData['access_token'] ?? tokenData['accessToken'];
        String? jwtRefreshToken = tokenData['refresh_token'] ?? tokenData['refreshToken'];

        if (jwtAccessToken != null) {
          await saveToken(jwtAccessToken, refreshToken: jwtRefreshToken);
          return true;
        }
      }

      print('Server response error: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Google login error: $e');
      return false;
    }
  }

  // Kakao Sign-In (Native)
  Future<bool> loginWithKakao() async {
    try {
      kakao.OAuthToken token;

      // 카카오톡 설치 여부에 따라 로그인 방식 선택
      if (await kakao.isKakaoTalkInstalled()) {
        // 카카오톡으로 로그인
        token = await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        // 카카오 계정으로 로그인 (웹)
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      // 사용자 정보 가져오기
      kakao.User user = await kakao.UserApi.instance.me();

      String kakaoId = user.id.toString();
      String? email = user.kakaoAccount?.email;
      String? nickname = user.kakaoAccount?.profile?.nickname;

      // 서버에 카카오 사용자 정보 전송하여 JWT 토큰 받기
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/oauth2/kakao/app'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'id': kakaoId,
          'email': email,
          'nickname': nickname,
          'accessToken': token.accessToken,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);

        final tokenData = data['data'] ?? data;
        String? jwtAccessToken = tokenData['access_token'] ?? tokenData['accessToken'];
        String? jwtRefreshToken = tokenData['refresh_token'] ?? tokenData['refreshToken'];

        if (jwtAccessToken != null) {
          await saveToken(jwtAccessToken, refreshToken: jwtRefreshToken);
          return true;
        }
      }

      print('Server response error: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Kakao login error: $e');
      return false;
    }
  }
}

