import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import '../services/community_service.dart';
import '../services/comment_service.dart';
import '../services/auth_service.dart';

/// 커뮤니티 상세 화면
class CommunityDetailScreen extends StatefulWidget {
  final int communityId;

  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final CommunityService _communityService = CommunityService();
  final CommentService _commentService = CommentService();
  final AuthService _authService = AuthService();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Community? _community;
  List<Comment> _comments = [];
  User? _currentUser;
  bool _isLoading = true;
  bool _isLoadingComments = false;
  bool _hasMoreComments = true;
  int _commentPage = 0;
  bool _isSubmittingComment = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingComments && _hasMoreComments) {
        _loadMoreComments();
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 로그인 정보 확인
    _currentUser = await _authService.getUserProfile();

    // 게시글 상세 로드
    final communityResult =
        await _communityService.getCommunityDetail(widget.communityId);
    if (communityResult.isSuccess && communityResult.data != null) {
      _community = communityResult.data;
    }

    // 댓글 로드
    await _loadComments();

    setState(() => _isLoading = false);
  }

  Future<void> _loadComments() async {
    final result = await _commentService.getCommentsByCommunity(
      widget.communityId,
      page: 0,
      size: 20,
    );

    if (result.isSuccess && result.data != null) {
      setState(() {
        _comments = result.data!.content;
        _hasMoreComments = result.data!.hasMore;
        _commentPage = 0;
      });
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingComments) return;

    setState(() => _isLoadingComments = true);

    final result = await _commentService.getCommentsByCommunity(
      widget.communityId,
      page: _commentPage + 1,
      size: 20,
    );

    if (result.isSuccess && result.data != null) {
      setState(() {
        _comments.addAll(result.data!.content);
        _hasMoreComments = result.data!.hasMore;
        _commentPage++;
      });
    }

    setState(() => _isLoadingComments = false);
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    setState(() => _isSubmittingComment = true);

    final result = await _commentService.createComment(
      CommentCreate(
        communityId: widget.communityId,
        content: content,
      ),
    );

    setState(() => _isSubmittingComment = false);

    if (result.isSuccess) {
      _commentController.clear();
      _loadComments();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? '댓글 작성에 실패했습니다')),
        );
      }
    }
  }

  Future<void> _deleteComment(int commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('댓글 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await _commentService.deleteComment(commentId);
      if (result.isSuccess) {
        _loadComments();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? '댓글 삭제에 실패했습니다')),
          );
        }
      }
    }
  }

  Future<void> _deleteCommunity() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final result =
          await _communityService.deleteCommunity(widget.communityId);
      if (result.isSuccess) {
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.error ?? '게시글 삭제에 실패했습니다')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('게시글'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_community == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('게시글'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('게시글을 불러올 수 없습니다')),
      );
    }

    final isAuthor =
        _currentUser != null && _currentUser!.username == _community!.username;

    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: isAuthor
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/community-write',
                      arguments: _community,
                    );
                    if (result == true) {
                      _loadData();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _deleteCommunity,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 게시글 내용
                    _buildPostContent(),
                    const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
                    // 댓글 목록
                    _buildCommentList(),
                  ],
                ),
              ),
            ),
          ),
          // 댓글 입력
          if (_currentUser != null) _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목
          Text(
            _community!.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          // 메타 정보
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                _community!.nickname,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                _community!.formattedDate,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.visibility, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${_community!.viewCount}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          // 내용 (HTML 태그 간단히 제거)
          Text(
            _community!.content.replaceAll(RegExp(r'<[^>]*>'), ''),
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
          // 이미지
          if (_community!.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              children: _community!.imageUrls.map((url) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '댓글 ${_community!.commentCount}개',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        if (_comments.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('아직 댓글이 없습니다', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length + (_isLoadingComments ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _comments.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return _buildCommentItem(_comments[index]);
            },
          ),
      ],
    );
  }

  Widget _buildCommentItem(Comment comment) {
    final isMyComment =
        _currentUser != null && _currentUser!.username == comment.username;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_circle, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    comment.nickname,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    comment.formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              if (isMyComment)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteComment(comment.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('삭제', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(comment.content),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: '댓글을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isSubmittingComment ? null : _submitComment,
            icon: _isSubmittingComment
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send, color: Colors.deepPurple),
          ),
        ],
      ),
    );
  }
}

