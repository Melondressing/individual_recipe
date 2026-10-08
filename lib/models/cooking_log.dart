class CookingLog {
  final String id;
  final String recipeId;
  final String recipeName;
  final DateTime cookedAt;
  final List<String> images; // 조리 완료 인증샷
  final String notes; // 조리 소감, 변경사항
  final int rating; // 1-5 별점
  final List<String> tags; // 성공, 실패, 개선필요 등

  CookingLog({
    required this.id,
    required this.recipeId,
    required this.recipeName,
    required this.cookedAt,
    this.images = const [],
    this.notes = '',
    this.rating = 0,
    this.tags = const [],
  });

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'cookedAt': cookedAt.millisecondsSinceEpoch,
      'images': images,
      'notes': notes,
      'rating': rating,
      'tags': tags,
    };
  }

  // JSON 역직렬화
  factory CookingLog.fromJson(Map<String, dynamic> json) {
    return CookingLog(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      recipeName: json['recipeName'] as String,
      cookedAt: DateTime.fromMillisecondsSinceEpoch(json['cookedAt'] as int),
      images: (json['images'] as List?)?.map((e) => e as String).toList() ?? [],
      notes: json['notes'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
    );
  }

  // Map 변환 (LocalStorage용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'cookedAt': cookedAt.millisecondsSinceEpoch,
      'images': images.join('|||'), // 구분자로 저장
      'notes': notes,
      'rating': rating,
      'tags': tags.join(','),
    };
  }

  factory CookingLog.fromMap(Map<String, dynamic> map) {
    return CookingLog(
      id: map['id'] as String,
      recipeId: map['recipeId'] as String,
      recipeName: map['recipeName'] as String,
      cookedAt: DateTime.fromMillisecondsSinceEpoch(map['cookedAt'] as int),
      images: ((map['images'] as String?) ?? '').isEmpty
          ? []
          : ((map['images'] as String?) ?? '').split('|||'),
      notes: map['notes'] as String? ?? '',
      rating: map['rating'] as int? ?? 0,
      tags: ((map['tags'] as String?) ?? '').isEmpty
          ? []
          : ((map['tags'] as String?) ?? '').split(','),
    );
  }
}
