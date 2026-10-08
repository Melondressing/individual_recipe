import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/recipe_provider.dart';

class RecipeEditScreen extends StatefulWidget {
  final Recipe? recipe;

  const RecipeEditScreen({super.key, this.recipe});

  @override
  State<RecipeEditScreen> createState() => _RecipeEditScreenState();
}

class _RecipeEditScreenState extends State<RecipeEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _stepsController;
  late final TextEditingController _notesController;
  late final TextEditingController _prepMinutesController;
  late final TextEditingController _cookMinutesController;
  late final TextEditingController _servingsController;

  String _selectedType = 'recipe';
  String _selectedCuisine = 'other';
  List<String> _categories = [];
  List<String> _tags = [];
  List<String> _cookingMethods = [];
  int _effortLevel = 2;
  bool _isDraft = false;
  bool _isFavorite = false;
  bool _isSaving = false;

  final List<String> _typeOptions = const ['recipe', 'sauce', 'pickle', 'base', 'other'];
  final List<String> _cuisineOptions = const ['korean', 'chinese', 'italian', 'french', 'sauce', 'other'];

  final List<String> _suggestedCategories = const [
    '한식',
    '중식',
    '이탈리아',
    '프렌치',
    '소스',
    '반찬',
    '국물',
    '디저트',
    '마리네이드',
    '밑반찬',
  ];

  final List<String> _suggestedMethods = const [
    '굽기',
    '볶기',
    '끓이기',
    '튀기기',
    '찌기',
    '무치기',
    '절임/마리네이드',
    '블렌딩',
    '소스 만들기',
    '오븐',
  ];

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;

    _nameController = TextEditingController(text: recipe?.name ?? '');
    _descriptionController = TextEditingController(text: recipe?.description ?? '');
    _ingredientsController = TextEditingController(text: recipe?.ingredients.join('\n') ?? '');
    _stepsController = TextEditingController(text: recipe?.steps.join('\n') ?? '');
    _notesController = TextEditingController(text: recipe?.notes.join('\n') ?? '');
    _prepMinutesController = TextEditingController(text: _optionalIntText(recipe?.prepMinutes));
    _cookMinutesController = TextEditingController(text: _optionalIntText(recipe?.cookMinutes));
    _servingsController = TextEditingController(text: _optionalIntText(recipe?.servings));

    if (recipe != null) {
      _selectedType = recipe.type;
      _selectedCuisine = _cuisineOptions.contains(recipe.cuisine) ? recipe.cuisine : 'other';
      _categories = List<String>.from(recipe.categories);
      _tags = List<String>.from(recipe.tags);
      _cookingMethods = List<String>.from(recipe.cookingMethods);
      _effortLevel = recipe.effortLevel;
      _isDraft = recipe.isDraft;
      _isFavorite = recipe.isFavorite;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ingredientsController.dispose();
    _stepsController.dispose();
    _notesController.dispose();
    _prepMinutesController.dispose();
    _cookMinutesController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  String _optionalIntText(int? value) {
    if (value == null || value <= 0) return '';
    return value.toString();
  }

  int _parsePositiveInt(String text) {
    final value = int.tryParse(text.trim());
    if (value == null || value < 0) return 0;
    return value;
  }

  List<String> _parseLines(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  Future<void> _saveRecipe() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final recipe = Recipe(
        id: widget.recipe?.id ?? 'recipe_$now',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        cuisine: _selectedCuisine,
        categories: _categories,
        tags: _tags,
        cookingMethods: _cookingMethods,
        ingredients: _parseLines(_ingredientsController.text),
        steps: _parseLines(_stepsController.text),
        notes: _parseLines(_notesController.text),
        prepMinutes: _parsePositiveInt(_prepMinutesController.text),
        cookMinutes: _parsePositiveInt(_cookMinutesController.text),
        servings: _parsePositiveInt(_servingsController.text),
        effortLevel: _effortLevel,
        isDraft: _isDraft,
        isFavorite: _isFavorite,
        cookCount: widget.recipe?.cookCount ?? 0,
        createdAt: widget.recipe?.createdAt ?? now,
        updatedAt: now,
        lastUsedAt: widget.recipe?.lastUsedAt ?? 0,
      );

      final provider = context.read<RecipeProvider>();
      if (widget.recipe == null) {
        await provider.createRecipe(recipe);
      } else {
        await provider.updateRecipe(recipe);
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addCategory() => _showTextInputDialog(
        title: 'Add Category',
        hintText: 'e.g., Korean, Soup, Sauce',
        existingValues: _categories,
        onAdd: (value) => setState(() => _categories.add(value)),
      );

  void _addTag() => _showTextInputDialog(
        title: 'Add Tag',
        hintText: 'e.g., Quick, Party, Spicy',
        existingValues: _tags,
        onAdd: (value) => setState(() => _tags.add(value)),
      );

  void _addCookingMethod() => _showTextInputDialog(
        title: 'Add Cooking Method',
        hintText: 'e.g., Braise, Roast, Steam',
        existingValues: _cookingMethods,
        onAdd: (value) => setState(() => _cookingMethods.add(value)),
      );

  void _showTextInputDialog({
    required String title,
    required String hintText,
    required List<String> existingValues,
    required ValueChanged<String> onAdd,
  }) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hintText),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitDialogValue(dialogContext, controller, existingValues, onAdd),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _submitDialogValue(dialogContext, controller, existingValues, onAdd),
              child: const Text('Add'),
            ),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _submitDialogValue(
    BuildContext dialogContext,
    TextEditingController controller,
    List<String> existingValues,
    ValueChanged<String> onAdd,
  ) {
    final text = controller.text.trim();
    if (text.isNotEmpty && !existingValues.contains(text)) {
      onAdd(text);
    }
    Navigator.pop(dialogContext);
  }

  void _toggleValue(List<String> list, String value) {
    setState(() {
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
    });
  }

  String _effortLabel(int value) {
    switch (value) {
      case 1:
        return 'Very Simple';
      case 2:
        return 'Simple';
      case 3:
        return 'Moderate';
      case 4:
        return 'Complex';
      case 5:
      default:
        return 'Very Complex';
    }
  }

  String _cuisineLabel(String value) {
    switch (value) {
      case 'korean':
        return 'Korean / 한식';
      case 'chinese':
        return 'Chinese / 중식';
      case 'italian':
        return 'Italian / 이탈리아';
      case 'french':
        return 'French / 프렌치';
      case 'sauce':
        return 'Sauce / 소스';
      case 'other':
      default:
        return 'Other / 기타';
    }
  }

  Widget _sectionTitle(BuildContext context, String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  Widget _chipEditor({
    required String title,
    required List<String> values,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...values.map(
              (value) => Chip(
                label: Text(value),
                onDeleted: () => setState(() => values.remove(value)),
              ),
            ),
            ActionChip(label: const Text('+ Add'), onPressed: onAdd),
          ],
        ),
      ],
    );
  }

  Widget _suggestedChipSet({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required ValueChanged<String> onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, title),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((value) {
            final selected = selectedValues.contains(value);
            return FilterChip(
              label: Text(value),
              selected: selected,
              onSelected: (_) => onToggle(value),
              selectedColor: Colors.black,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null;
          final parsed = int.tryParse(value.trim());
          if (parsed == null || parsed < 0) return '0 이상의 숫자만 입력';
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe == null ? 'New Recipe' : 'Edit Recipe'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveRecipe,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(
                context,
                'Basic Information',
                subtitle: '레시피 이름, 설명, 요리권, 타입을 정리합니다.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Recipe Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Short Description',
                  hintText: 'e.g., 매콤한 닭고기 볶음 요리. 재우는 시간이 맛을 좌우한다.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCuisine,
                      decoration: const InputDecoration(
                        labelText: 'Cuisine',
                        border: OutlineInputBorder(),
                      ),
                      items: _cuisineOptions.map((cuisine) {
                        return DropdownMenuItem(
                          value: cuisine,
                          child: Text(_cuisineLabel(cuisine)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedCuisine = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _typeOptions.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type[0].toUpperCase() + type.substring(1)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedType = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _numberField(
                    controller: _prepMinutesController,
                    label: 'Prep min',
                    icon: Icons.timer_outlined,
                  ),
                  const SizedBox(width: 8),
                  _numberField(
                    controller: _cookMinutesController,
                    label: 'Cook min',
                    icon: Icons.local_fire_department_outlined,
                  ),
                  const SizedBox(width: 8),
                  _numberField(
                    controller: _servingsController,
                    label: 'Servings',
                    icon: Icons.people_outline,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _suggestedChipSet(
                title: 'Suggested Categories',
                options: _suggestedCategories,
                selectedValues: _categories,
                onToggle: (value) => _toggleValue(_categories, value),
              ),
              const SizedBox(height: 16),
              _chipEditor(title: 'Categories', values: _categories, onAdd: _addCategory),
              const SizedBox(height: 16),
              _suggestedChipSet(
                title: 'Cooking Methods',
                options: _suggestedMethods,
                selectedValues: _cookingMethods,
                onToggle: (value) => _toggleValue(_cookingMethods, value),
              ),
              const SizedBox(height: 16),
              _chipEditor(title: 'Custom Methods', values: _cookingMethods, onAdd: _addCookingMethod),
              const SizedBox(height: 16),
              _chipEditor(title: 'Tags', values: _tags, onAdd: _addTag),
              const SizedBox(height: 16),
              _sectionTitle(context, 'Effort Level'),
              Slider(
                value: _effortLevel.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '${_effortLabel(_effortLevel)} ($_effortLevel/5)',
                onChanged: (value) => setState(() => _effortLevel = value.toInt()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ingredientsController,
                decoration: const InputDecoration(
                  labelText: 'Ingredients (one per line)',
                  hintText: '닭다리살 500g\n고추장 3큰술\n양배추 200g',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stepsController,
                decoration: const InputDecoration(
                  labelText: 'Method / Steps (one per line)',
                  hintText: '[준비 5분] 닭고기를 한입 크기로 자른다.\n[양념 3분] 양념장을 섞는다.\n[볶기 10분] 중강불에서 볶는다.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: '불 조절, 대체 재료, 보관법, 실패 포인트 등을 적는다.',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Mark as Draft'),
                subtitle: const Text('Show in Inbox for organizing later'),
                value: _isDraft,
                onChanged: (value) => setState(() => _isDraft = value),
              ),
              SwitchListTile(
                title: const Text('Favorite'),
                value: _isFavorite,
                onChanged: (value) => setState(() => _isFavorite = value),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveRecipe,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: Text(_isSaving ? 'Saving...' : 'Save Recipe'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
