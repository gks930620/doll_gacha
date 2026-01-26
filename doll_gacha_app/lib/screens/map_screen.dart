import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/doll_shop_model.dart';
import '../services/doll_shop_service.dart';

/// 시도별 시군구 데이터
const Map<String, List<String>> sigunguData = {
  '서울특별시': ['강남구', '강동구', '강북구', '강서구', '관악구', '광진구', '구로구', '금천구', '노원구', '도봉구', '동대문구', '동작구', '마포구', '서대문구', '서초구', '성동구', '성북구', '송파구', '양천구', '영등포구', '용산구', '은평구', '종로구', '중구', '중랑구'],
  '부산광역시': ['강서구', '금정구', '기장군', '남구', '동구', '동래구', '부산진구', '북구', '사상구', '사하구', '서구', '수영구', '연제구', '영도구', '중구', '해운대구'],
  '대구광역시': ['남구', '달서구', '달성군', '동구', '북구', '서구', '수성구', '중구'],
  '인천광역시': ['강화군', '계양구', '남동구', '동구', '미추홀구', '부평구', '서구', '연수구', '옹진군', '중구'],
  '광주광역시': ['광산구', '남구', '동구', '북구', '서구'],
  '대전광역시': ['대덕구', '동구', '서구', '유성구', '중구'],
  '울산광역시': ['남구', '동구', '북구', '울주군', '중구'],
  '세종특별자치시': ['세종시'],
  '경기도': ['가평군', '고양시', '과천시', '광명시', '광주시', '구리시', '군포시', '김포시', '남양주시', '동두천시', '부천시', '성남시', '수원시', '시흥시', '안산시', '안성시', '안양시', '양주시', '양평군', '여주시', '연천군', '오산시', '용인시', '의왕시', '의정부시', '이천시', '파주시', '평택시', '포천시', '하남시', '화성시'],
  '강원특별자치도': ['강릉시', '고성군', '동해시', '삼척시', '속초시', '양구군', '양양군', '영월군', '원주시', '인제군', '정선군', '철원군', '춘천시', '태백시', '평창군', '홍천군', '화천군', '횡성군'],
  '충청북도': ['괴산군', '단양군', '보은군', '영동군', '옥천군', '음성군', '제천시', '증평군', '진천군', '청주시', '충주시'],
  '충청남도': ['계룡시', '공주시', '금산군', '논산시', '당진시', '보령시', '부여군', '서산시', '서천군', '아산시', '예산군', '천안시', '청양군', '태안군', '홍성군'],
  '전북특별자치도': ['고창군', '군산시', '김제시', '남원시', '무주군', '부안군', '순창군', '완주군', '익산시', '임실군', '장수군', '전주시', '정읍시', '진안군'],
  '전라남도': ['강진군', '고흥군', '곡성군', '광양시', '구례군', '나주시', '담양군', '목포시', '무안군', '보성군', '순천시', '신안군', '여수시', '영광군', '영암군', '완도군', '장성군', '장흥군', '진도군', '함평군', '해남군', '화순군'],
  '경상북도': ['경산시', '경주시', '고령군', '구미시', '군위군', '김천시', '문경시', '봉화군', '상주시', '성주군', '안동시', '영덕군', '영양군', '영주시', '영천시', '예천군', '울릉군', '울진군', '의성군', '청도군', '청송군', '칠곡군', '포항시'],
  '경상남도': ['거제시', '거창군', '고성군', '김해시', '남해군', '밀양시', '사천시', '산청군', '양산시', '의령군', '진주시', '창녕군', '창원시', '통영시', '하동군', '함안군', '함양군', '합천군'],
  '제주특별자치도': ['서귀포시', '제주시'],
};

/// 시도별 중심 좌표
const Map<String, List<double>> sidoCenter = {
  '서울특별시': [37.5665, 126.9780],
  '부산광역시': [35.1796, 129.0756],
  '대구광역시': [35.8714, 128.6014],
  '인천광역시': [37.4563, 126.7052],
  '광주광역시': [35.1595, 126.8526],
  '대전광역시': [36.3504, 127.3845],
  '울산광역시': [35.5384, 129.3114],
  '세종특별자치시': [36.4800, 127.2890],
  '경기도': [37.4138, 127.5183],
  '강원특별자치도': [37.8228, 128.1555],
  '충청북도': [36.6357, 127.4917],
  '충청남도': [36.5184, 126.8000],
  '전북특별자치도': [35.8203, 127.1086],
  '전라남도': [34.8679, 126.9910],
  '경상북도': [36.4919, 128.8889],
  '경상남도': [35.4606, 128.2132],
  '제주특별자치도': [33.4890, 126.4983],
};

/// 카카오맵 지도 화면
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final DollShopService _shopService = DollShopService();

  KakaoMapController? _mapController;
  List<DollShopMap> _shops = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  LatLng _currentCenter = LatLng(37.5665, 126.9780); // 서울 시청 기본값
  DollShopMap? _selectedShop;

  // 필터
  String? _selectedGubun1;
  String? _selectedGubun2;
  bool _showFilter = false;

  List<String> get _gubun2List =>
      _selectedGubun1 != null ? sigunguData[_selectedGubun1] ?? [] : [];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  /// 위치 권한 요청 및 현재 위치 가져오기
  Future<void> _initLocation() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
        });
      } catch (e) {
        debugPrint('위치 가져오기 실패: $e');
      }
    }

    await _loadShops();
  }

  /// 매장 데이터 로드
  Future<void> _loadShops() async {
    setState(() => _isLoading = true);

    final result = await _shopService.getShopsForMap(
      gubun1: _selectedGubun1,
      gubun2: _selectedGubun2,
    );

    if (result.isSuccess && result.data != null) {
      setState(() {
        _shops = result.data!;
        _createMarkers();
      });
    }

    setState(() => _isLoading = false);
  }

  /// 필터 적용 및 지도 이동
  void _applyFilter() {
    _loadShops();

    // 선택한 시/도의 중심으로 지도 이동
    if (_selectedGubun1 != null && sidoCenter.containsKey(_selectedGubun1)) {
      final center = sidoCenter[_selectedGubun1]!;
      _mapController?.setCenter(LatLng(center[0], center[1]));
      _mapController?.setLevel(8);
    }

    setState(() => _showFilter = false);
  }

  /// 필터 초기화
  void _resetFilter() {
    setState(() {
      _selectedGubun1 = null;
      _selectedGubun2 = null;
    });
    _loadShops();
  }

  /// 마커 생성
  void _createMarkers() {
    _markers = _shops.map((shop) {
      return Marker(
        markerId: shop.id.toString(),
        latLng: LatLng(shop.latitude, shop.longitude),
        infoWindowContent: shop.businessName,
        infoWindowFirstShow: false,
      );
    }).toSet();
  }

  /// 마커 클릭 시 매장 정보 표시
  void _onMarkerTap(String markerId) {
    final shop = _shops.firstWhere(
      (s) => s.id.toString() == markerId,
      orElse: () => _shops.first,
    );
    setState(() => _selectedShop = shop);
  }

  /// 매장 상세 페이지로 이동
  void _goToShopDetail(int shopId) {
    Navigator.pushNamed(context, '/shop-detail', arguments: shopId);
  }

  /// 현재 위치로 이동
  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _mapController?.setCenter(LatLng(position.latitude, position.longitude));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 위치를 가져올 수 없습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인형뽑기방 지도'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showFilter ? Icons.filter_alt_off : Icons.filter_alt),
            onPressed: () => setState(() => _showFilter = !_showFilter),
            tooltip: '지역 필터',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _resetFilter();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 카카오맵
          KakaoMap(
            onMapCreated: (controller) {
              _mapController = controller;
            },
            center: _currentCenter,
            currentLevel: 5,
            markers: _markers.toList(),
            onMarkerTap: (markerId, latLng, zoomLevel) {
              _onMarkerTap(markerId);
            },
          ),

          // 필터 패널
          if (_showFilter)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGubun1,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: '시/도',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('전체')),
                              ...sigunguData.keys.map((key) =>
                                DropdownMenuItem(value: key, child: Text(key, overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedGubun1 = value;
                                _selectedGubun2 = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGubun2,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: '시/군/구',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('전체')),
                              ..._gubun2List.map((item) =>
                                DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis))),
                            ],
                            onChanged: _selectedGubun1 == null ? null : (value) {
                              setState(() => _selectedGubun2 = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _applyFilter,
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text('검색'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              _resetFilter();
                              setState(() => _showFilter = false);
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('초기화'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // 로딩 인디케이터
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // 현재 위치 버튼
          Positioned(
            right: 16,
            bottom: _selectedShop != null ? 180 : 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _moveToCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.deepPurple),
            ),
          ),

          // 선택된 매장 정보 카드
          if (_selectedShop != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildShopInfoCard(_selectedShop!),
            ),
        ],
      ),
    );
  }

  Widget _buildShopInfoCard(DollShopMap shop) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _goToShopDetail(shop.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      shop.businessName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _selectedShop = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      shop.address,
                      style: TextStyle(color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (shop.phone != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      shop.phone!,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  if (shop.totalGameMachines != null) ...[
                    const Icon(Icons.games, size: 16, color: Colors.deepPurple),
                    const SizedBox(width: 4),
                    Text('${shop.totalGameMachines}대'),
                    const SizedBox(width: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: shop.isOperating ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      shop.isOperating ? '영업중' : '휴업',
                      style: TextStyle(
                        color: shop.isOperating ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
