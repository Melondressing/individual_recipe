class Review {
  final String id;
  final String recipeId;
  final String recipeName;
  final String userName;
  final String text;
  final int rating;
  final List<String> photoUrls;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.recipeId,
    required this.recipeName,
    required this.userName,
    required this.text,
    required this.rating,
    this.photoUrls = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'userName': userName,
      'text': text,
      'rating': rating,
      'photoUrls': photoUrls,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      recipeId: json['recipeId'] as String,
      recipeName: json['recipeName'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Me',
      text: json['text'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      photoUrls: (json['photoUrls'] as List?)?.map((e) => e as String).toList() ?? [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'userName': userName,
      'text': text,
      'rating': rating,
      'photoUrls': photoUrls.join('|||'),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String,
      recipeId: map['recipeId'] as String,
      recipeName: map['recipeName'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Me',
      text: map['text'] as String? ?? '',
      rating: map['rating'] as int? ?? 0,
      photoUrls: ((map['photoUrls'] as String?) ?? '').isEmpty
          ? []
          : ((map['photoUrls'] as String?) ?? '').split('|||'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }
}
