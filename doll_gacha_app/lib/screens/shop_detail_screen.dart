import 'package:flutter/material.dart';
import '../models/doll_shop_model.dart';
import '../models/review_model.dart';
import '../models/review_stats_model.dart';
import '../services/doll_shop_service.dart';
import '../services/review_service.dart';
import '../services/api_client.dart';

/// 매장 상세 화면
class ShopDetailScreen extends StatefulWidget {
  final int shopId;

  const ShopDetailScreen({super.key, required this.shopId});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  final DollShopService _shopService = DollShopService();
  final ReviewService _reviewService = ReviewService();
  final ApiClient _apiClient = ApiClient();
  final ScrollController _scrollController = ScrollController();

  DollShopDetail? _shop;
  ReviewStats? _stats;
  List<Review> _reviews = [];
  bool _isLoading = true;
  bool _isLoadingReviews = false;
  bool _hasMoreReviews = true;
  int _reviewPage = 0;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingReviews && _hasMoreReviews) {
        _loadMoreReviews();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 로그인 상태 확인
    _isLoggedIn = await _apiClient.isLoggedIn();

    // 매장 정보 로드
    final shopResult = await _shopService.getShopById(widget.shopId);
    if (shopResult.isSuccess && shopResult.data != null) {
      _shop = shopResult.data;
    }

    // 리뷰 통계 로드
    final statsResult = await _reviewService.getReviewStats(widget.shopId);
    if (statsResult.isSuccess && statsResult.data != null) {
      _stats = statsResult.data;
    }

    // 리뷰 목록 로드
    await _loadReviews();

    setState(() => _isLoading = false);
  }

  Future<void> _loadReviews() async {
    final result = await _reviewService.getReviewsByShop(
      widget.shopId,
      page: 0,
      size: 10,
    );

    if (result.isSuccess && result.data != null) {
      setState(() {
        _reviews = result.data!.content;
        _hasMoreReviews = result.data!.hasMore;
        _reviewPage = 0;
      });
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingReviews) return;

    setState(() => _isLoadingReviews = true);

    final result = await _reviewService.getReviewsByShop(
      widget.shopId,
      page: _reviewPage + 1,
      size: 10,
    );

    if (result.isSuccess && result.data != null) {
      setState(() {
        _reviews.addAll(result.data!.content);
        _hasMoreReviews = result.data!.hasMore;
        _reviewPage++;
      });
    }

    setState(() => _isLoadingReviews = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('매장 상세'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_shop == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('매장 상세'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('매장 정보를 불러올 수 없습니다')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_shop!.businessName),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 매장 정보 카드
              _buildShopInfoCard(),
              // 리뷰 통계
              if (_stats != null) _buildStatsCard(),
              // 리뷰 작성 버튼
              if (_isLoggedIn) _buildWriteReviewButton(),
              // 리뷰 목록
              _buildReviewList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[200],
                child: _shop!.imagePath != null
                    ? Image.network(
                        _shop!.imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.store, size: 64, color: Colors.grey),
                      )
                    : const Icon(Icons.store, size: 64, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            // 매장명
            Text(
              _shop!.businessName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // 주소
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _shop!.address,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // 전화번호
            if (_shop!.phone != null)
              Row(
                children: [
                  const Icon(Icons.phone, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _shop!.phone!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            const SizedBox(height: 4),
            // 기계 수
            if (_shop!.totalGameMachines != null)
              Row(
                children: [
                  const Icon(Icons.games, size: 16, color: Colors.deepPurple),
                  const SizedBox(width: 4),
                  Text(
                    '게임기 ${_shop!.totalGameMachines}대',
                    style: const TextStyle(color: Colors.deepPurple),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '리뷰 통계',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  '총 리뷰',
                  '${_stats!.totalReviews}개',
                  Icons.rate_review,
                ),
                _buildStatItem(
                  '평균 별점',
                  _stats!.avgRating.toStringAsFixed(1),
                  Icons.star,
                  color: Colors.amber,
                ),
                _buildStatItem(
                  '기계 힘',
                  '${_stats!.avgMachineStrength.toStringAsFixed(1)}/5',
                  Icons.fitness_center,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 평균 비용
            if (_stats!.avgLargeDollCost != null ||
                _stats!.avgMediumDollCost != null ||
                _stats!.avgSmallDollCost != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('평균 비용', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCostItem('대형', _stats!.avgLargeDollCost),
                      _buildCostItem('중형', _stats!.avgMediumDollCost),
                      _buildCostItem('소형', _stats!.avgSmallDollCost),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, size: 28, color: color ?? Colors.deepPurple),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCostItem(String size, double? cost) {
    return Column(
      children: [
        Text(size, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          cost != null ? '${cost.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원' : '-',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildWriteReviewButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.pushNamed(
              context,
              '/review-write',
              arguments: {'shopId': widget.shopId, 'shopName': _shop!.businessName},
            );
            if (result == true) {
              _loadData(); // 새로고침
            }
          },
          icon: const Icon(Icons.edit),
          label: const Text('리뷰 작성하기'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '리뷰 ${_stats?.totalReviews ?? 0}개',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        if (_reviews.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('아직 리뷰가 없습니다', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length + (_isLoadingReviews ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _reviews.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return _buildReviewItem(_reviews[index]);
            },
          ),
      ],
    );
  }

  Widget _buildReviewItem(Review review) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 작성자 및 날짜
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_circle, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      review.nickname,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  review.formattedDate,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 별점 및 기계 힘
            Row(
              children: [
                // 별점
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < review.rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                ),
                const SizedBox(width: 16),
                // 기계 힘
                Text(
                  '기계힘: ${review.machineStrength}/5',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 비용 정보
            if (review.largeDollCost != null ||
                review.mediumDollCost != null ||
                review.smallDollCost != null)
              Wrap(
                spacing: 8,
                children: [
                  if (review.largeDollCost != null)
                    Chip(
                      label: Text('대형: ${review.formatCost(review.largeDollCost)}'),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (review.mediumDollCost != null)
                    Chip(
                      label: Text('중형: ${review.formatCost(review.mediumDollCost)}'),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (review.smallDollCost != null)
                    Chip(
                      label: Text('소형: ${review.formatCost(review.smallDollCost)}'),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            const SizedBox(height: 8),
            // 내용
            Text(review.content),
            // 이미지
            if (review.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.imageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          review.imageUrls[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

