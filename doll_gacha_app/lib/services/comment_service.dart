import '../config/constants.dart';
import '../models/comment_model.dart';
import '../models/page_response_model.dart';
import 'api_client.dart';

/// 댓글 서비스
class CommentService {
  final ApiClient _apiClient = ApiClient();

  /// 게시글별 댓글 목록 조회 (페이징)
  Future<ApiResult<PageResponse<Comment>>> getCommentsByCommunity(
    int communityId, {
    int page = 0,
    int size = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };

    return _apiClient.get<PageResponse<Comment>>(
      AppConstants.commentsByCommunityEndpoint(communityId),
      queryParams: queryParams,
      fromJson: (data) => PageResponse.fromJson(
        data,
        (item) => Comment.fromJson(item),
      ),
    );
  }

  /// 댓글 작성
  Future<ApiResult<Comment>> createComment(CommentCreate comment) async {
    return _apiClient.post<Comment>(
      AppConstants.commentsEndpoint,
      body: comment.toJson(),
      fromJson: (data) => Comment.fromJson(data),
    );
  }

  /// 댓글 수정
  Future<ApiResult<Comment>> updateComment(int commentId, CommentUpdate comment) async {
    return _apiClient.put<Comment>(
      '${AppConstants.commentsEndpoint}/$commentId',
      body: comment.toJson(),
      fromJson: (data) => Comment.fromJson(data),
    );
  }

  /// 댓글 삭제
  Future<ApiResult<void>> deleteComment(int commentId) async {
    return _apiClient.delete<void>(
      '${AppConstants.commentsEndpoint}/$commentId',
    );
  }
}

