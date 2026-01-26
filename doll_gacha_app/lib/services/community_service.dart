import '../config/constants.dart';
import '../models/community_model.dart';
import '../models/page_response_model.dart';
import 'api_client.dart';

/// 커뮤니티 서비스
class CommunityService {
  final ApiClient _apiClient = ApiClient();

  /// 게시글 목록 조회 (페이징, 검색)
  Future<ApiResult<PageResponse<Community>>> getCommunityList({
    String? searchType,
    String? keyword,
    int page = 0,
    int size = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (searchType != null && searchType.isNotEmpty) {
      queryParams['searchType'] = searchType;
    }
    if (keyword != null && keyword.isNotEmpty) {
      queryParams['keyword'] = keyword;
    }

    return _apiClient.get<PageResponse<Community>>(
      AppConstants.communityEndpoint,
      queryParams: queryParams,
      fromJson: (data) => PageResponse.fromJson(
        data,
        (item) => Community.fromJson(item),
      ),
    );
  }

  /// 게시글 상세 조회
  Future<ApiResult<Community>> getCommunityDetail(int id) async {
    return _apiClient.get<Community>(
      '${AppConstants.communityEndpoint}/$id',
      fromJson: (data) => Community.fromJson(data),
    );
  }

  /// 게시글 작성
  Future<ApiResult<int>> createCommunity(CommunityCreate community) async {
    return _apiClient.post<int>(
      AppConstants.communityEndpoint,
      body: community.toJson(),
      fromJson: (data) => data as int,
    );
  }

  /// 게시글 수정
  Future<ApiResult<void>> updateCommunity(int id, CommunityUpdate community) async {
    return _apiClient.put<void>(
      '${AppConstants.communityEndpoint}/$id',
      body: community.toJson(),
    );
  }

  /// 게시글 삭제
  Future<ApiResult<void>> deleteCommunity(int id) async {
    return _apiClient.delete<void>(
      '${AppConstants.communityEndpoint}/$id',
    );
  }
}

