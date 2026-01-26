import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/doll_shop_model.dart';
import '../services/doll_shop_service.dart';

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

    final result = await _shopService.getShopsForMap();

    if (result.isSuccess && result.data != null) {
      setState(() {
        _shops = result.data!;
        _createMarkers();
      });
    }

    setState(() => _isLoading = false);
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadShops,
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
