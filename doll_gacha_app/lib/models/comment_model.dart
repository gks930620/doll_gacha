/// 댓글 모델 (CommentDTO)
class Comment {
  final int id;
  final int communityId;
  final String content;
  final int userId;
  final String username;
  final String nickname;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Comment({
    required this.id,
    required this.communityId,
    required this.content,
    required this.userId,
    required this.username,
    required this.nickname,
    required this.createdAt,
    this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      communityId: json['communityId'] ?? 0,
      content: json['content'] ?? '',
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
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

/// 댓글 생성 DTO
class CommentCreate {
  final int communityId;
  final String content;

  CommentCreate({
    required this.communityId,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'communityId': communityId,
      'content': content,
    };
  }
}

/// 댓글 수정 DTO
class CommentUpdate {
  final String content;

  CommentUpdate({
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }
}

