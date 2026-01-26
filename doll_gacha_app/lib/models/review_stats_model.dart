/// 리뷰 통계 모델 (ReviewStatsDTO)
class ReviewStats {
  final int totalReviews;
  final double avgRating;
  final double avgMachineStrength;
  final double? avgLargeDollCost;
  final double? avgMediumDollCost;
  final double? avgSmallDollCost;

  ReviewStats({
    required this.totalReviews,
    required this.avgRating,
    required this.avgMachineStrength,
    this.avgLargeDollCost,
    this.avgMediumDollCost,
    this.avgSmallDollCost,
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      totalReviews: json['totalReviews'] ?? 0,
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      avgMachineStrength: (json['avgMachineStrength'] ?? 0).toDouble(),
      avgLargeDollCost: json['avgLargeDollCost']?.toDouble(),
      avgMediumDollCost: json['avgMediumDollCost']?.toDouble(),
      avgSmallDollCost: json['avgSmallDollCost']?.toDouble(),
    );
  }

  factory ReviewStats.empty() {
    return ReviewStats(
      totalReviews: 0,
      avgRating: 0.0,
      avgMachineStrength: 0.0,
    );
  }

  /// 비용을 천원 단위로 포맷팅
  String formatCost(double? cost) {
    if (cost == null || cost == 0) return '데이터 없음';
    return '${cost.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}원';
  }
}

