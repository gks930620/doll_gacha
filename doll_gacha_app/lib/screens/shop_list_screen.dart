import 'package:flutter/material.dart';
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

/// 정렬 옵션
const List<Map<String, String>> sortOptions = [
  {'value': 'latest', 'label': '최신순'},
  {'value': 'rating', 'label': '평점순'},
  {'value': 'reviewCount', 'label': '리뷰많은순'},
  {'value': 'totalGameMachines', 'label': '기계많은순'},
  {'value': 'machineStrength', 'label': '기계힘순'},
  {'value': 'largeCost', 'label': '대형비용순'},
  {'value': 'mediumCost', 'label': '중형비용순'},
  {'value': 'smallCost', 'label': '소형비용순'},
];

/// 매장 목록 화면
class ShopListScreen extends StatefulWidget {
  const ShopListScreen({super.key});

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  final DollShopService _shopService = DollShopService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<DollShopList> _shops = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;

  // 필터
  String? _selectedGubun1;
  String? _selectedGubun2;
  String? _keyword;
  String _sortBy = 'latest';

  List<String> get _gubun2List =>
      _selectedGubun1 != null ? sigunguData[_selectedGubun1] ?? [] : [];

  @override
  void initState() {
    super.initState();
    _loadShops();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreShops();
      }
    }
  }

  String _getSortParam() {
    switch (_sortBy) {
      case 'latest':
        return 'id,desc';
      case 'rating':
        return 'averageRating,desc';
      case 'reviewCount':
        return 'reviewCount,desc';
      case 'totalGameMachines':
        return 'totalGameMachines,desc';
      case 'machineStrength':
        return 'averageMachineStrength,desc';
      case 'largeCost':
        return 'averageLargeCost,asc';
      case 'mediumCost':
        return 'averageMediumCost,asc';
      case 'smallCost':
        return 'averageSmallCost,asc';
      default:
        return 'id,desc';
    }
  }

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _shops = [];
    });

    final result = await _shopService.searchShops(
      gubun1: _selectedGubun1,
      gubun2: _selectedGubun2,
      keyword: _keyword,
      page: 0,
      size: 20,
      sort: _getSortParam(),
    );

    if (result.isSuccess && result.data != null) {
      setState(() {
        _shops = result.data!.content;
        _hasMore = result.data!.hasMore;
        _currentPage = 0;
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreShops() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final result = await _shopService.searchShops(
      gubun1: _selectedGubun1,
      gubun2: _selectedGubun2,
      keyword: _keyword,
      page: _currentPage + 1,
      size: 20,
      sort: _getSortParam(),
    );

    if (result.isSuccess && result.data != null) {
      setState(() {
        _shops.addAll(result.data!.content);
        _hasMore = result.data!.hasMore;
        _currentPage++;
      });
    }

    setState(() => _isLoading = false);
  }

  void _onSearch() {
    _keyword = _searchController.text.trim().isEmpty
        ? null
        : _searchController.text.trim();
    _loadShops();
  }

  void _resetFilters() {
    setState(() {
      _selectedGubun1 = null;
      _selectedGubun2 = null;
      _keyword = null;
      _sortBy = 'latest';
      _searchController.clear();
    });
    _loadShops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인형뽑기방'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetFilters,
            tooltip: '초기화',
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 섹션
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                // 시/도, 시/군/구 선택
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
                          _loadShops();
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
                          _loadShops();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 검색 및 정렬
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '매장명 검색',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _onSearch(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        items: sortOptions.map((opt) =>
                          DropdownMenuItem(
                            value: opt['value'],
                            child: Text(opt['label']!, style: const TextStyle(fontSize: 13)),
                          )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _sortBy = value);
                            _loadShops();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.deepPurple),
                      onPressed: _onSearch,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.deepPurple.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 매장 목록
          Expanded(
            child: _shops.isEmpty && !_isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('매장이 없습니다', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadShops,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _shops.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _shops.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildShopCard(_shops[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(DollShopList shop) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/shop-detail',
            arguments: shop.id,
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: shop.imagePath != null
                      ? Image.network(
                          shop.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.store, size: 40, color: Colors.grey),
                        )
                      : const Icon(Icons.store, size: 40, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              // 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.businessName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shop.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // 평점
                        if (shop.reviewCount > 0) ...[
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${shop.averageRating.toStringAsFixed(1)} (${shop.reviewCount})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ] else ...[
                          Icon(Icons.star_border, size: 16, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            '리뷰 없음',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          ),
                        ],
                        const Spacer(),
                        // 기계 수
                        if (shop.totalGameMachines != null) ...[
                          const Icon(Icons.games, size: 14, color: Colors.deepPurple),
                          const SizedBox(width: 4),
                          Text(
                            '${shop.totalGameMachines}대',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

