class IngredientAlias {
  final String id;
  final String alias; // 사용자가 실제로 적는 단어 (예: 미림)
  final String canonical; // 통합 검색용 표준어 (예: 맛술)

  IngredientAlias({
    required this.id,
    required this.alias,
    required this.canonical,
  });

  factory IngredientAlias.fromMap(Map<String, dynamic> map) {
    return IngredientAlias(
      id: map['id'] as String,
      alias: map['alias'] as String,
      canonical: map['canonical'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'alias': alias,
      'canonical': canonical,
    };
  }

  factory IngredientAlias.fromJson(Map<String, dynamic> json) {
    return IngredientAlias(
      id: json['id'] as String,
      alias: json['alias'] as String,
      canonical: json['canonical'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alias': alias,
      'canonical': canonical,
    };
  }
}
