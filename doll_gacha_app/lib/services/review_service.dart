import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';
import 'package:uuid/uuid.dart';

class ReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();

  // 리뷰 생성
  Future<Review> createReview({
    required String userId,
    required String shopId,
    required String content,
    required double rating,
    required List<File> imageFiles,
  }) async {
    // 이미지 업로드
    final imageUrls = await _uploadImages(imageFiles);

    final reviewData = {
      'user_id': userId,
      'shop_id': shopId,
      'content': content,
      'rating': rating,
      'image_urls': imageUrls,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('reviews')
        .insert(reviewData)
        .select()
        .single();

    return Review.fromJson(response);
  }

  // 이미지 업로드 (최대 3개)
  Future<List<String>> _uploadImages(List<File> imageFiles) async {
    if (imageFiles.isEmpty) return [];
    if (imageFiles.length > 3) {
      throw Exception('최대 3개의 이미지만 업로드할 수 있습니다.');
    }

    final List<String> imageUrls = [];

    for (final file in imageFiles) {
      final fileExtension = file.path.split('.').last.toLowerCase();
      final fileName = '${_uuid.v4()}.$fileExtension';
      final filePath = 'reviews/$fileName';

      // Supabase Storage에 업로드
      await _supabase.storage.from('review-images').upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Public URL 가져오기
      final publicUrl = _supabase.storage
          .from('review-images')
          .getPublicUrl(filePath);

      imageUrls.add(publicUrl);
    }

    return imageUrls;
  }

  // 특정 가게의 리뷰 목록 가져오기
  Future<List<Review>> getReviewsByShopId(String shopId) async {
    final response = await _supabase
        .from('reviews')
        .select()
        .eq('shop_id', shopId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Review.fromJson(json)).toList();
  }

  // 리뷰 삭제
  Future<void> deleteReview(String reviewId, List<String> imageUrls) async {
    // 먼저 이미지 삭제
    await _deleteImages(imageUrls);

    // 리뷰 삭제
    await _supabase.from('reviews').delete().eq('id', reviewId);
  }

  // 이미지 삭제
  Future<void> _deleteImages(List<String> imageUrls) async {
    for (final url in imageUrls) {
      try {
        // URL에서 파일 경로 추출
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;

        // 'review-images' 다음의 경로 추출
        final storageIndex = pathSegments.indexOf('review-images');
        if (storageIndex != -1 && storageIndex < pathSegments.length - 1) {
          final filePath = pathSegments.sublist(storageIndex + 1).join('/');
          await _supabase.storage.from('review-images').remove([filePath]);
        }
      } catch (e) {
        print('이미지 삭제 중 오류 발생: $e');
      }
    }
  }
}

