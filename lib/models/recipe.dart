class Recipe {
  final String id;
  final String name;
  final String description; // 짧은 설명/요약
  final String type; // recipe/sauce/pickle/base/other
  final String cuisine; // korean/chinese/italian/french/other
  final List<String> categories; // 한식, 일식 등
  final List<String> tags; // 고단백, 손님접대용 등
  final List<String> cookingMethods; // 굽기, 볶기, 끓이기 등 조리 메소드
  final List<String> ingredients; // 재료 원문 배열
  final List<String> steps; // 조리 단계 배열
  final List<String> notes; // 메모/사유 배열
  final List<String> images; // 이미지 경로 배열
  final int prepMinutes; // 준비 시간
  final int cookMinutes; // 조리 시간
  final int servings; // 인분
  final int effortLevel; // 1: 매우 간단, 2: 간단, 3: 보통, 4: 복잡, 5: 매우 복잡
  final int cookCount; // 조리 완료 횟수
  final bool isFavorite; // 즐겨찾기
  final bool isDraft; // 정리 필요 여부
  final int createdAt;
  final int updatedAt;
  final int lastUsedAt;

  Recipe({
    required this.id,
    required this.name,
    String? description,
    this.type = 'recipe',
    String? cuisine,
    this.categories = const [],
    this.tags = const [],
    List<String>? cookingMethods,
    this.ingredients = const [],
    this.steps = const [],
    this.notes = const [],
    this.images = const [],
    this.prepMinutes = 0,
    this.cookMinutes = 0,
    this.servings = 0,
    this.effortLevel = 2,
    this.cookCount = 0,
    this.isFavorite = false,
    this.isDraft = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt = 0,
  })  : description = description ?? '',
        cookingMethods = cookingMethods ?? _inferCookingMethods(type, categories, tags, steps, notes),
        cuisine = cuisine ?? _inferCuisine(type, categories, tags, name);

  int get totalMinutes => prepMinutes + cookMinutes;

  bool get hasTiming => prepMinutes > 0 || cookMinutes > 0;

  bool get hasServings => servings > 0;

  bool get hasMethods => cookingMethods.isNotEmpty;

  bool get isClearlyStructured {
    return name.trim().isNotEmpty && ingredients.isNotEmpty && steps.isNotEmpty;
  }

  String get timingLabel {
    if (!hasTiming) return '';
    if (prepMinutes > 0 && cookMinutes > 0) {
      return 'Prep ${prepMinutes}m · Cook ${cookMinutes}m · Total ${totalMinutes}m';
    }
    if (prepMinutes > 0) return 'Prep ${prepMinutes}m';
    return 'Cook ${cookMinutes}m';
  }

  String get servingsLabel => servings > 0 ? '$servings servings' : '';

  String get methodLabel => cookingMethods.join(' · ');

  String get searchableText {
    return [
      name,
      description,
      type,
      cuisine,
      ...categories,
      ...tags,
      ...cookingMethods,
      ...ingredients,
      ...steps,
      ...notes,
    ].join(' ').toLowerCase();
  }

  // SQLite에서 불러올 때
  factory Recipe.fromMap(Map<String, dynamic> map) {
    final categories = _parseList(map['categories']);
    final tags = _parseList(map['tags']);
    final steps = _parseList(map['steps']);
    final notes = _parseList(map['notes']);
    final type = map['type'] as String? ?? 'recipe';
    final name = map['name'] as String? ?? '';

    return Recipe(
      id: map['id'] as String,
      name: name,
      description: map['description'] as String? ?? '',
      type: type,
      cuisine: (map['cuisine'] as String?)?.trim().isNotEmpty == true
          ? map['cuisine'] as String
          : null,
      categories: categories,
      tags: tags,
      cookingMethods: _parseList(map['cookingMethods']).isNotEmpty
          ? _parseList(map['cookingMethods'])
          : null,
      ingredients: _parseList(map['ingredients']),
      steps: steps,
      notes: notes,
      images: _parseList(map['images']),
      prepMinutes: _parseInt(map['prepMinutes']),
      cookMinutes: _parseInt(map['cookMinutes']),
      servings: _parseInt(map['servings']),
      effortLevel: _parseInt(map['effortLevel'], fallback: 2),
      cookCount: _parseInt(map['cookCount']),
      isFavorite: _parseBool(map['isFavorite']),
      isDraft: _parseBool(map['isDraft']),
      createdAt: _parseInt(map['createdAt']),
      updatedAt: _parseInt(map['updatedAt']),
      lastUsedAt: _parseInt(map['lastUsedAt']),
    );
  }

  // SQLite에 저장할 때
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'cuisine': cuisine,
      'categories': _stringifyList(categories),
      'tags': _stringifyList(tags),
      'cookingMethods': _stringifyList(cookingMethods),
      'ingredients': _stringifyList(ingredients),
      'steps': _stringifyList(steps),
      'notes': _stringifyList(notes),
      'images': _stringifyList(images),
      'prepMinutes': prepMinutes,
      'cookMinutes': cookMinutes,
      'servings': servings,
      'effortLevel': effortLevel,
      'cookCount': cookCount,
      'isFavorite': isFavorite ? 1 : 0,
      'isDraft': isDraft ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastUsedAt': lastUsedAt,
    };
  }

  // JSON Export/Import용
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'cuisine': cuisine,
      'categories': categories,
      'tags': tags,
      'cookingMethods': cookingMethods,
      'ingredients': ingredients,
      'steps': steps,
      'notes': notes,
      'images': images,
      'prepMinutes': prepMinutes,
      'cookMinutes': cookMinutes,
      'servings': servings,
      'effortLevel': effortLevel,
      'cookCount': cookCount,
      'isFavorite': isFavorite,
      'isDraft': isDraft,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastUsedAt': lastUsedAt,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final categories = _parseList(json['categories']);
    final tags = _parseList(json['tags']);
    final steps = _parseList(json['steps']);
    final notes = _parseList(json['notes']);
    final type = json['type'] as String? ?? 'recipe';
    final name = json['name'] as String? ?? '';

    return Recipe(
      id: json['id'] as String,
      name: name,
      description: json['description'] as String? ?? '',
      type: type,
      cuisine: (json['cuisine'] as String?)?.trim().isNotEmpty == true
          ? json['cuisine'] as String
          : null,
      categories: categories,
      tags: tags,
      cookingMethods: _parseList(json['cookingMethods']).isNotEmpty
          ? _parseList(json['cookingMethods'])
          : null,
      ingredients: _parseList(json['ingredients']),
      steps: steps,
      notes: notes,
      images: _parseList(json['images']),
      prepMinutes: _parseInt(json['prepMinutes']),
      cookMinutes: _parseInt(json['cookMinutes']),
      servings: _parseInt(json['servings']),
      effortLevel: _parseInt(json['effortLevel'], fallback: 2),
      cookCount: _parseInt(json['cookCount']),
      isFavorite: _parseBool(json['isFavorite']),
      isDraft: _parseBool(json['isDraft']),
      createdAt: _parseInt(json['createdAt']),
      updatedAt: _parseInt(json['updatedAt']),
      lastUsedAt: _parseInt(json['lastUsedAt']),
    );
  }

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    String? type,
    String? cuisine,
    List<String>? categories,
    List<String>? tags,
    List<String>? cookingMethods,
    List<String>? ingredients,
    List<String>? steps,
    List<String>? notes,
    List<String>? images,
    int? prepMinutes,
    int? cookMinutes,
    int? servings,
    int? effortLevel,
    int? cookCount,
    bool? isFavorite,
    bool? isDraft,
    int? createdAt,
    int? updatedAt,
    int? lastUsedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      cuisine: cuisine ?? this.cuisine,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      cookingMethods: cookingMethods ?? this.cookingMethods,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      notes: notes ?? this.notes,
      images: images ?? this.images,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      cookMinutes: cookMinutes ?? this.cookMinutes,
      servings: servings ?? this.servings,
      effortLevel: effortLevel ?? this.effortLevel,
      cookCount: cookCount ?? this.cookCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isDraft: isDraft ?? this.isDraft,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  static String _inferCuisine(
    String type,
    List<String> categories,
    List<String> tags,
    String name,
  ) {
    final text = [type, name, ...categories, ...tags].join(' ').toLowerCase();
    if (text.contains('한식') || text.contains('korean') || text.contains('korea')) return 'korean';
    if (text.contains('중식') || text.contains('중국') || text.contains('chinese') || text.contains('china')) return 'chinese';
    if (text.contains('이탈리아') || text.contains('italian') || text.contains('italy') || text.contains('파스타') || text.contains('pasta')) return 'italian';
    if (text.contains('프렌치') || text.contains('french') || text.contains('france') || text.contains('bistro')) return 'french';
    if (type.toLowerCase() == 'sauce' || text.contains('소스') || text.contains('sauce')) return 'sauce';
    return 'other';
  }

  static List<String> _inferCookingMethods(
    String type,
    List<String> categories,
    List<String> tags,
    List<String> steps,
    List<String> notes,
  ) {
    final text = [type, ...categories, ...tags, ...steps, ...notes].join(' ').toLowerCase();
    final methods = <String>[];

    void addIf(bool condition, String method) {
      if (condition && !methods.contains(method)) methods.add(method);
    }

    addIf(text.contains('볶') || text.contains('stir') || text.contains('sauté') || text.contains('saute'), '볶기');
    addIf(text.contains('굽') || text.contains('구이') || text.contains('roast') || text.contains('grill') || text.contains('bake'), '굽기');
    addIf(text.contains('끓') || text.contains('boil') || text.contains('simmer'), '끓이기');
    addIf(text.contains('튀') || text.contains('fry') || text.contains('deep-fry'), '튀기기');
    addIf(text.contains('찐다') || text.contains('찌기') || text.contains('steam'), '찌기');
    addIf(text.contains('무침') || text.contains('버무') || text.contains('mix') || text.contains('dress'), '무치기');
    addIf(text.contains('절임') || text.contains('장아찌') || text.contains('pickle') || text.contains('marinade') || text.contains('재우'), '절임/마리네이드');
    addIf(text.contains('블렌') || text.contains('갈아') || text.contains('갈기') || text.contains('blend') || text.contains('puree'), '블렌딩');
    addIf(type.toLowerCase() == 'sauce' || text.contains('소스') || text.contains('dressing'), '소스 만들기');

    return methods;
  }

  // 리스트를 저장 가능한 문자열로 변환
  static String _stringifyList(List<String> list) {
    return list.join('|||');
  }

  // 문자열 또는 JSON 배열을 리스트로 파싱
  static List<String> _parseList(dynamic value) {
    if (value == null || value == '') return [];
    if (value is List) {
      return value.map((item) => item.toString().trim()).where((s) => s.isNotEmpty).toList();
    }
    if (value is String) {
      return value.split('|||').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    final text = value.toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }
}
