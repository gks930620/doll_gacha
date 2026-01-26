/// 리뷰 모델 (ReviewDTO)
class Review {
  final int id;
  final int userId;
  final String username;
  final String nickname;
  final int dollShopId;
  final String content;
  final int rating;
  final int machineStrength;
  final int? largeDollCost;
  final int? mediumDollCost;
  final int? smallDollCost;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Review({
    required this.id,
    required this.userId,
    required this.username,
    required this.nickname,
    required this.dollShopId,
    required this.content,
    required this.rating,
    required this.machineStrength,
    this.largeDollCost,
    this.mediumDollCost,
    this.smallDollCost,
    required this.imageUrls,
    required this.createdAt,
    this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      nickname: json['nickname'] ?? '',
      dollShopId: json['dollShopId'] ?? 0,
      content: json['content'] ?? '',
      rating: json['rating'] ?? 0,
      machineStrength: json['machineStrength'] ?? 0,
      largeDollCost: json['largeDollCost'],
      mediumDollCost: json['mediumDollCost'],
      smallDollCost: json['smallDollCost'],
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

  /// 비용 포맷팅 (원 단위 -> 표시)
  String formatCost(int? cost) {
    if (cost == null || cost == 0) return '';
    return '${cost.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
  }
}

/// 리뷰 생성 DTO
class ReviewCreate {
  final int dollShopId;
  final String content;
  final int rating;
  final int machineStrength;
  final int? largeDollCost;
  final int? mediumDollCost;
  final int? smallDollCost;

  ReviewCreate({
    required this.dollShopId,
    required this.content,
    required this.rating,
    required this.machineStrength,
    this.largeDollCost,
    this.mediumDollCost,
    this.smallDollCost,
  });

  Map<String, dynamic> toJson() {
    return {
      'dollShopId': dollShopId,
      'content': content,
      'rating': rating,
      'machineStrength': machineStrength,
      if (largeDollCost != null) 'largeDollCost': largeDollCost,
      if (mediumDollCost != null) 'mediumDollCost': mediumDollCost,
      if (smallDollCost != null) 'smallDollCost': smallDollCost,
    };
  }
}

/// 리뷰 수정 DTO
class ReviewUpdate {
  final String content;
  final int rating;
  final int machineStrength;
  final int? largeDollCost;
  final int? mediumDollCost;
  final int? smallDollCost;

  ReviewUpdate({
    required this.content,
    required this.rating,
    required this.machineStrength,
    this.largeDollCost,
    this.mediumDollCost,
    this.smallDollCost,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'rating': rating,
      'machineStrength': machineStrength,
      if (largeDollCost != null) 'largeDollCost': largeDollCost,
      if (mediumDollCost != null) 'mediumDollCost': mediumDollCost,
      if (smallDollCost != null) 'smallDollCost': smallDollCost,
    };
  }
}
