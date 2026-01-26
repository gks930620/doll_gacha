import 'package:flutter/material.dart';
import '../models/doll_shop_model.dart';
import '../services/doll_shop_service.dart';

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
  String? _keyword;
  String _sortBy = 'id,desc';

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

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _shops = [];
    });

    final result = await _shopService.searchShops(
      keyword: _keyword,
      page: 0,
      size: 20,
      sort: _sortBy,
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
      keyword: _keyword,
      page: _currentPage + 1,
      size: 20,
      sort: _sortBy,
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
    _keyword = _searchController.text.trim();
    _loadShops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인형뽑기방'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 검색 바
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '매장명 또는 주소 검색',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                // 정렬 버튼
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  onSelected: (value) {
                    setState(() => _sortBy = value);
                    _loadShops();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'id,desc',
                      child: Text('최신순'),
                    ),
                    const PopupMenuItem(
                      value: 'averageRating,desc',
                      child: Text('평점순'),
                    ),
                    const PopupMenuItem(
                      value: 'reviewCount,desc',
                      child: Text('리뷰순'),
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

