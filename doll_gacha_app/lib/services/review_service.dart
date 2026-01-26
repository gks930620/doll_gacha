import '../config/constants.dart';
import '../models/page_response_model.dart';
import '../models/review_model.dart';
import '../models/review_stats_model.dart';
import 'api_client.dart';

/// 리뷰 서비스
class ReviewService {
  final ApiClient _apiClient = ApiClient();

  /// 매장별 리뷰 목록 조회 (페이징)
  Future<ApiResult<PageResponse<Review>>> getReviewsByShop(
    int shopId, {
    int page = 0,
    int size = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };

    return _apiClient.get<PageResponse<Review>>(
      AppConstants.reviewsByShopEndpoint(shopId),
      queryParams: queryParams,
      fromJson: (data) => PageResponse.fromJson(
        data,
        (item) => Review.fromJson(item),
      ),
    );
  }

  /// 매장 리뷰 통계 조회
  Future<ApiResult<ReviewStats>> getReviewStats(int shopId) async {
    return _apiClient.get<ReviewStats>(
      AppConstants.reviewStatsEndpoint(shopId),
      fromJson: (data) => ReviewStats.fromJson(data),
    );
  }

  /// 리뷰 작성
  Future<ApiResult<Review>> createReview(ReviewCreate review) async {
    return _apiClient.post<Review>(
      AppConstants.reviewsEndpoint,
      body: review.toJson(),
      fromJson: (data) => Review.fromJson(data),
    );
  }

  /// 리뷰 수정
  Future<ApiResult<Review>> updateReview(int reviewId, ReviewUpdate review) async {
    return _apiClient.put<Review>(
      '${AppConstants.reviewsEndpoint}/$reviewId',
      body: review.toJson(),
      fromJson: (data) => Review.fromJson(data),
    );
  }

  /// 리뷰 삭제
  Future<ApiResult<void>> deleteReview(int reviewId) async {
    return _apiClient.delete<void>(
      '${AppConstants.reviewsEndpoint}/$reviewId',
    );
  }
}
