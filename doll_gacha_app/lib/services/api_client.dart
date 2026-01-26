import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

/// 공통 API 클라이언트 - 토큰 자동 추가 및 에러 처리
class ApiClient {
  final _storage = const FlutterSecureStorage();
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// GET 요청
  Future<ApiResult<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint')
          .replace(queryParameters: queryParams);

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.error('네트워크 오류: $e');
    }
  }

  /// POST 요청
  Future<ApiResult<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();

      final response = await http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.error('네트워크 오류: $e');
    }
  }

  /// PUT 요청
  Future<ApiResult<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();

      final response = await http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.error('네트워크 오류: $e');
    }
  }

  /// DELETE 요청
  Future<ApiResult<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final headers = await _getHeaders();

      final response = await http.delete(uri, headers: headers);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResult.error('네트워크 오류: $e');
    }
  }

  /// 헤더 생성 (토큰 포함)
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    final token = await _storage.read(key: _accessTokenKey);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// 응답 처리
  ApiResult<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return ApiResult.success(null as T);
      }

      final json = jsonDecode(response.body);

      // ApiResponse 형식: { success, message, data }
      if (json is Map<String, dynamic> && json.containsKey('data')) {
        final data = json['data'];
        if (fromJson != null) {
          return ApiResult.success(fromJson(data));
        }
        return ApiResult.success(data as T);
      }

      // 직접 데이터 반환
      if (fromJson != null) {
        return ApiResult.success(fromJson(json));
      }
      return ApiResult.success(json as T);
    } else if (response.statusCode == 401) {
      return ApiResult.error('로그인이 필요합니다', statusCode: 401);
    } else if (response.statusCode == 403) {
      return ApiResult.error('권한이 없습니다', statusCode: 403);
    } else if (response.statusCode == 404) {
      return ApiResult.error('데이터를 찾을 수 없습니다', statusCode: 404);
    } else {
      try {
        final json = jsonDecode(response.body);
        final message = json['message'] ?? '요청 처리 중 오류가 발생했습니다';
        return ApiResult.error(message, statusCode: response.statusCode);
      } catch (e) {
        return ApiResult.error('서버 오류', statusCode: response.statusCode);
      }
    }
  }

  /// 토큰 저장
  Future<void> saveTokens(String accessToken, {String? refreshToken}) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  /// 토큰 삭제
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  /// 로그인 여부 확인
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null;
  }
}

/// API 결과 래퍼
class ApiResult<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool isSuccess;

  ApiResult._({
    this.data,
    this.error,
    this.statusCode,
    required this.isSuccess,
  });

  factory ApiResult.success(T data) {
    return ApiResult._(data: data, isSuccess: true);
  }

  factory ApiResult.error(String message, {int? statusCode}) {
    return ApiResult._(
      error: message,
      statusCode: statusCode,
      isSuccess: false,
    );
  }
}

