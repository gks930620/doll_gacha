/// 커뮤니티 게시글 모델 (CommunityDTO)
class Community {
  final int id;
  final int userId;
  final String username;
  final String nickname;
  final String title;
  final String content;
  final int viewCount;
  final int commentCount;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Community({
    required this.id,
    required this.userId,
    required this.username,
    required this.nickname,
    required this.title,
    required this.content,
    required this.viewCount,
    required this.commentCount,
    required this.imageUrls,
    required this.createdAt,
    this.updatedAt,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'],
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      viewCount: json['viewCount'] ?? 0,
      commentCount: json['commentCount'] ?? 0,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  /// 시간 포맷팅
  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';

    return '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
  }
}

/// 커뮤니티 생성 DTO
class CommunityCreate {
  final String title;
  final String content;

  CommunityCreate({
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}

/// 커뮤니티 수정 DTO
class CommunityUpdate {
  final String title;
  final String content;

  CommunityUpdate({
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
    };
  }
}

