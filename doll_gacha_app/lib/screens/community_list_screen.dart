import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';

/// 커뮤니티 목록 화면
class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  final CommunityService _communityService = CommunityService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<Community> _communities = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _keyword;
  String _searchType = 'title';

  @override
  void initState() {
    super.initState();
    _loadCommunities();
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
        _loadMoreCommunities();
      }
    }
  }

  Future<void> _loadCommunities() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _communities = [];
    });

    final result = await _communityService.getCommunityList(
      searchType: _keyword != null ? _searchType : null,
      keyword: _keyword,
      page: 0,
      size: 20,
    );

    if (result.isSuccess && result.data != null) {
      setState(() {
        _communities = result.data!.content;
        _hasMore = result.data!.hasMore;
        _currentPage = 0;
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreCommunities() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final result = await _communityService.getCommunityList(
      searchType: _keyword != null ? _searchType : null,
      keyword: _keyword,
      page: _currentPage + 1,
      size: 20,
    );

    if (result.isSuccess && result.data != null) {
      setState(() {
        _communities.addAll(result.data!.content);
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
    _loadCommunities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
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
                // 검색 타입
                DropdownButton<String>(
                  value: _searchType,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'title', child: Text('제목')),
                    DropdownMenuItem(value: 'nickname', child: Text('작성자')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _searchType = value);
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '검색어 입력',
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
              ],
            ),
          ),
          // 게시글 목록
          Expanded(
            child: _communities.isEmpty && !_isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('게시글이 없습니다', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCommunities,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _communities.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _communities.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        return _buildCommunityCard(_communities[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/community-write');
          if (result == true) {
            _loadCommunities();
          }
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildCommunityCard(Community community) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.pushNamed(
            context,
            '/community-detail',
            arguments: community.id,
          );
          if (result == true) {
            _loadCommunities();
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                community.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 내용 미리보기
              Text(
                community.content.replaceAll(RegExp(r'<[^>]*>'), ''), // HTML 태그 제거
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // 메타 정보
              Row(
                children: [
                  // 작성자
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        community.nickname,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // 날짜
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        community.formattedDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // 조회수
                  Row(
                    children: [
                      const Icon(Icons.visibility, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${community.viewCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // 댓글수
                  Row(
                    children: [
                      const Icon(Icons.comment, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${community.commentCount}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

