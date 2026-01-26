/// 매장 모델 - 지도용 (DollShopMapDTO)
class DollShopMap {
  final int id;
  final String businessName;
  final String address;
  final String? phone;
  final double longitude;
  final double latitude;
  final int? totalGameMachines;
  final String? approvalDate;
  final bool isOperating;

  DollShopMap({
    required this.id,
    required this.businessName,
    required this.address,
    this.phone,
    required this.longitude,
    required this.latitude,
    this.totalGameMachines,
    this.approvalDate,
    required this.isOperating,
  });

  factory DollShopMap.fromJson(Map<String, dynamic> json) {
    return DollShopMap(
      id: json['id'],
      businessName: json['businessName'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      longitude: (json['longitude'] ?? 0).toDouble(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      totalGameMachines: json['totalGameMachines'],
      approvalDate: json['approvalDate'],
      isOperating: json['isOperating'] ?? true,
    );
  }
}

/// 매장 모델 - 목록용 (DollShopListDTO)
class DollShopList {
  final int id;
  final String businessName;
  final double longitude;
  final double latitude;
  final String address;
  final int? totalGameMachines;
  final String? phone;
  final bool isOperating;
  final String? approvalDate;
  final String? gubun1;
  final String? gubun2;
  final String? imagePath;
  final double averageRating;
  final int reviewCount;
  final double? averageMachineStrength;
  final double? averageLargeCost;
  final double? averageMediumCost;
  final double? averageSmallCost;

  DollShopList({
    required this.id,
    required this.businessName,
    required this.longitude,
    required this.latitude,
    required this.address,
    this.totalGameMachines,
    this.phone,
    required this.isOperating,
    this.approvalDate,
    this.gubun1,
    this.gubun2,
    this.imagePath,
    required this.averageRating,
    required this.reviewCount,
    this.averageMachineStrength,
    this.averageLargeCost,
    this.averageMediumCost,
    this.averageSmallCost,
  });

  factory DollShopList.fromJson(Map<String, dynamic> json) {
    return DollShopList(
      id: json['id'],
      businessName: json['businessName'] ?? '',
      longitude: (json['longitude'] ?? 0).toDouble(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      address: json['address'] ?? '',
      totalGameMachines: json['totalGameMachines'],
      phone: json['phone'],
      isOperating: json['isOperating'] ?? true,
      approvalDate: json['approvalDate'],
      gubun1: json['gubun1'],
      gubun2: json['gubun2'],
      imagePath: json['imagePath'],
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      averageMachineStrength: json['averageMachineStrength']?.toDouble(),
      averageLargeCost: json['averageLargeCost']?.toDouble(),
      averageMediumCost: json['averageMediumCost']?.toDouble(),
      averageSmallCost: json['averageSmallCost']?.toDouble(),
    );
  }
}

/// 매장 모델 - 상세용 (DollShopDTO)
class DollShopDetail {
  final int id;
  final String businessName;
  final double longitude;
  final double latitude;
  final String address;
  final int? totalGameMachines;
  final String? phone;
  final bool isOperating;
  final String? approvalDate;
  final String? gubun1;
  final String? gubun2;
  final String? imagePath;
  final double? averageRating;
  final int? reviewCount;

  DollShopDetail({
    required this.id,
    required this.businessName,
    required this.longitude,
    required this.latitude,
    required this.address,
    this.totalGameMachines,
    this.phone,
    required this.isOperating,
    this.approvalDate,
    this.gubun1,
    this.gubun2,
    this.imagePath,
    this.averageRating,
    this.reviewCount,
  });

  factory DollShopDetail.fromJson(Map<String, dynamic> json) {
    return DollShopDetail(
      id: json['id'],
      businessName: json['businessName'] ?? '',
      longitude: (json['longitude'] ?? 0).toDouble(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      address: json['address'] ?? '',
      totalGameMachines: json['totalGameMachines'],
      phone: json['phone'],
      isOperating: json['isOperating'] ?? true,
      approvalDate: json['approvalDate'],
      gubun1: json['gubun1'],
      gubun2: json['gubun2'],
      imagePath: json['imagePath'],
      averageRating: json['averageRating']?.toDouble(),
      reviewCount: json['reviewCount'],
    );
  }
}

