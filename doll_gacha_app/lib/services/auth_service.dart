import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
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
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
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
}

