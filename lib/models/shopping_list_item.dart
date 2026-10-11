class ShoppingListItem {
  final String id;
  final String name;
  final bool isChecked;
  final String? recipeId; // 레시피에서 추가된 경우 원본 레시피 id
  final String? recipeName; // 원본 레시피 이름 (표시용)
  final int createdAt;

  ShoppingListItem({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.recipeId,
    this.recipeName,
    required this.createdAt,
  });

  ShoppingListItem copyWith({
    String? name,
    bool? isChecked,
  }) {
    return ShoppingListItem(
      id: id,
      name: name ?? this.name,
      isChecked: isChecked ?? this.isChecked,
      recipeId: recipeId,
      recipeName: recipeName,
      createdAt: createdAt,
    );
  }

  // JSON 직렬화 (Export/Import, Web LocalStorage용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isChecked': isChecked,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'createdAt': createdAt,
    };
  }

  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: json['id'] as String,
      name: json['name'] as String,
      isChecked: json['isChecked'] == true || json['isChecked'] == 1,
      recipeId: json['recipeId'] as String?,
      recipeName: json['recipeName'] as String?,
      createdAt: _parseInt(json['createdAt']),
    );
  }

  // Map 변환 (SQLite용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isChecked': isChecked ? 1 : 0,
      'recipeId': recipeId,
      'recipeName': recipeName,
      'createdAt': createdAt,
    };
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'] as String,
      name: map['name'] as String,
      isChecked: (map['isChecked'] as int? ?? 0) == 1,
      recipeId: map['recipeId'] as String?,
      recipeName: map['recipeName'] as String?,
      createdAt: _parseInt(map['createdAt']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
