import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/constants.dart';
import 'dart:convert';

/// 파일 업로드 서비스
class FileService {
  final _storage = const FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();
  static const String _accessTokenKey = 'access_token';

  /// 갤러리에서 이미지 선택
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  /// 카메라로 이미지 촬영
  Future<File?> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  /// 여러 이미지 선택
  Future<List<File>> pickMultipleImages({int maxImages = 3}) async {
    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    // 최대 개수 제한
    final limitedImages = images.take(maxImages).toList();
    return limitedImages.map((xFile) => File(xFile.path)).toList();
  }

  /// 파일 업로드
  Future<FileUploadResult> uploadFiles({
    required List<File> files,
    required int refId,
    required String refType,
    required String usage,
  }) async {
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (token == null) {
        return FileUploadResult.error('로그인이 필요합니다');
      }

      final uri = Uri.parse('${AppConstants.baseUrl}${AppConstants.fileUploadEndpoint}');
      final request = http.MultipartRequest('POST', uri);

      // 헤더 추가
      request.headers['Authorization'] = 'Bearer $token';

      // 파일 추가
      for (final file in files) {
        request.files.add(await http.MultipartFile.fromPath('files', file.path));
      }

      // 파라미터 추가
      request.fields['refId'] = refId.toString();
      request.fields['refType'] = refType;
      request.fields['usage'] = usage;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body);
        final urls = (json['data'] as List?)?.map((e) => e.toString()).toList() ?? [];
        return FileUploadResult.success(urls);
      } else if (response.statusCode == 413) {
        return FileUploadResult.error('파일 크기가 너무 큽니다. 최대 10MB까지 업로드 가능합니다.');
      } else {
        try {
          final json = jsonDecode(response.body);
          return FileUploadResult.error(json['message'] ?? '업로드 실패');
        } catch (e) {
          return FileUploadResult.error('업로드 실패');
        }
      }
    } catch (e) {
      return FileUploadResult.error('네트워크 오류: $e');
    }
  }
}

/// 파일 업로드 결과
class FileUploadResult {
  final List<String>? urls;
  final String? error;
  final bool isSuccess;

  FileUploadResult._({this.urls, this.error, required this.isSuccess});

  factory FileUploadResult.success(List<String> urls) {
    return FileUploadResult._(urls: urls, isSuccess: true);
  }

  factory FileUploadResult.error(String message) {
    return FileUploadResult._(error: message, isSuccess: false);
  }
}

