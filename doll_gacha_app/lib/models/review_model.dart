class Review {
  final String? id;
  final String userId;
  final String shopId;
  final String content;
  final double rating;
  final List<String> imageUrls;
  final DateTime createdAt;

  Review({
    this.id,
    required this.userId,
    required this.shopId,
    required this.content,
    required this.rating,
    required this.imageUrls,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'shop_id': shopId,
      'content': content,
      'rating': rating,
      'image_urls': imageUrls,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'],
      shopId: json['shop_id'],
      content: json['content'],
      rating: (json['rating'] as num).toDouble(),
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

