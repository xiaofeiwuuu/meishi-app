class Recipe {
  final String id;
  final String name;
  final String author;
  final String authorId;
  final String desc;
  final String cover;
  final Ingredients ingredients;
  final List<RecipeStep> steps;
  final String tips;
  final Map<String, String> attrs;
  final String? category;

  Recipe({
    required this.id,
    required this.name,
    this.author = '',
    this.authorId = '',
    this.desc = '',
    this.cover = '',
    required this.ingredients,
    required this.steps,
    this.tips = '',
    this.attrs = const {},
    this.category,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      author: json['author'] ?? '',
      authorId: json['authorId'] ?? '',
      desc: json['desc'] ?? '',
      cover: json['cover'] ?? '',
      ingredients: Ingredients.fromJson(json['ingredients'] ?? {}),
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => RecipeStep.fromJson(e))
              .toList() ??
          [],
      tips: json['tips'] ?? '',
      attrs: Map<String, String>.from(json['attrs'] ?? {}),
      category: json['category'],
    );
  }

  String get coverUrl {
    if (cover.isEmpty) return '';
    if (cover.startsWith('http')) return cover;
    return 'https://cdn.jsdelivr.net/gh/xiaofeiwuuu/recipe@main/$cover';
  }

  int get estimatedTime => steps.length * 5;
}

class Ingredients {
  final List<Ingredient> main;
  final List<Ingredient> sub;

  Ingredients({this.main = const [], this.sub = const []});

  factory Ingredients.fromJson(Map<String, dynamic> json) {
    return Ingredients(
      main: (json['main'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromJson(e))
              .toList() ??
          [],
      sub: (json['sub'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromJson(e))
              .toList() ??
          [],
    );
  }

  List<Ingredient> get all => [...main, ...sub];
}

class Ingredient {
  final String name;
  final String amount;

  Ingredient({required this.name, this.amount = ''});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: json['name'] ?? '',
      amount: json['amount'] ?? '',
    );
  }
}

class RecipeStep {
  final int step;
  final String desc;
  final String img;

  RecipeStep({required this.step, required this.desc, this.img = ''});

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      step: json['step'] ?? 0,
      desc: json['desc'] ?? '',
      img: json['img'] ?? '',
    );
  }

  String get imageUrl {
    if (img.isEmpty) return '';
    if (img.startsWith('http')) return img;
    return 'https://cdn.jsdelivr.net/gh/xiaofeiwuuu/recipe@main/$img';
  }
}

class RecipeCategory {
  final String id;
  final String name;
  final String? parent;
  final int total;

  RecipeCategory({
    required this.id,
    required this.name,
    this.parent,
    this.total = 0,
  });

  factory RecipeCategory.fromJson(Map<String, dynamic> json) {
    return RecipeCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      parent: json['parent'],
      total: json['total'] ?? 0,
    );
  }
}

class RecipeSummary {
  final String id;
  final String name;
  final String cover;
  final String author;
  final String? category;

  RecipeSummary({
    required this.id,
    required this.name,
    this.cover = '',
    this.author = '',
    this.category,
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> json) {
    return RecipeSummary(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      cover: json['cover'] ?? '',
      author: json['author'] ?? '',
      category: json['category'],
    );
  }

  String get coverUrl {
    if (cover.isEmpty) return '';
    if (cover.startsWith('http')) return cover;
    return 'https://cdn.jsdelivr.net/gh/xiaofeiwuuu/recipe@main/$cover';
  }
}
