import '../config/constants.dart';
import '../models/doll_shop_model.dart';
import '../models/page_response_model.dart';
import 'api_client.dart';

/// 매장 서비스
class DollShopService {
  final ApiClient _apiClient = ApiClient();

  /// 지도용 매장 목록 조회
  Future<ApiResult<List<DollShopMap>>> getShopsForMap({
    String? gubun1,
    String? gubun2,
  }) async {
    final queryParams = <String, String>{};
    if (gubun1 != null) queryParams['gubun1'] = gubun1;
    if (gubun2 != null) queryParams['gubun2'] = gubun2;

    return _apiClient.get<List<DollShopMap>>(
      AppConstants.dollShopsMapEndpoint,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
      fromJson: (data) => (data as List)
          .map((item) => DollShopMap.fromJson(item))
          .toList(),
    );
  }

  /// 매장 목록 검색 (페이징)
  Future<ApiResult<PageResponse<DollShopList>>> searchShops({
    String? gubun1,
    String? gubun2,
    String? keyword,
    int page = 0,
    int size = 10,
    String? sort,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
    };
    if (gubun1 != null) queryParams['gubun1'] = gubun1;
    if (gubun2 != null) queryParams['gubun2'] = gubun2;
    if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
    if (sort != null) queryParams['sort'] = sort;

    return _apiClient.get<PageResponse<DollShopList>>(
      AppConstants.dollShopsSearchEndpoint,
      queryParams: queryParams,
      fromJson: (data) => PageResponse.fromJson(
        data,
        (item) => DollShopList.fromJson(item),
      ),
    );
  }

  /// 매장 상세 조회
  Future<ApiResult<DollShopDetail>> getShopById(int id) async {
    return _apiClient.get<DollShopDetail>(
      '${AppConstants.dollShopsEndpoint}/$id',
      fromJson: (data) => DollShopDetail.fromJson(data),
    );
  }
}

