import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../database/database_helper.dart';
import '../models/cooking_log.dart';

class CookingCompleteScreen extends StatefulWidget {
  final String recipeId;
  final String recipeName;

  const CookingCompleteScreen({
    super.key,
    required this.recipeId,
    required this.recipeName,
  });

  @override
  State<CookingCompleteScreen> createState() => _CookingCompleteScreenState();
}

class _CookingCompleteScreenState extends State<CookingCompleteScreen> {
  final TextEditingController _notesController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _selectedTags = [];
  final List<String> _imageUrls = [];

  int _rating = 0;
  bool _isSaving = false;
  bool _isPickingImage = false;

  static const int _maxImageBytes = 700 * 1024;

  final List<String> _availableTags = const [
    '성공',
    '맛있음',
    '개선필요',
    '시간부족',
    '재료변경',
    '레시피대로',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 65,
        maxWidth: 1200,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.length > _maxImageBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image is too large. Use a smaller image under 700KB.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final extension = picked.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
      final dataUrl = 'data:image/$extension;base64,${base64Encode(bytes)}';

      if (mounted) {
        setState(() => _imageUrls.add(dataUrl));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo added')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Widget _buildImage(String imageUrl, {double size = 150}) {
    try {
      if (imageUrl.startsWith('data:image')) {
        final commaIndex = imageUrl.indexOf(',');
        if (commaIndex == -1) throw const FormatException('Invalid image data');
        final bytes = base64Decode(imageUrl.substring(commaIndex + 1));
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: _imageErrorBuilder,
        );
      }

      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: _imageErrorBuilder,
      );
    } catch (_) {
      return _imageFallback(size);
    }
  }

  Widget _imageErrorBuilder(BuildContext context, Object error, StackTrace? stackTrace) {
    return _imageFallback(150);
  }

  Widget _imageFallback(double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, size: 40),
    );
  }

  Future<void> _saveCookingLog() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final log = CookingLog(
        id: 'log_${now.microsecondsSinceEpoch}',
        recipeId: widget.recipeId,
        recipeName: widget.recipeName,
        cookedAt: now,
        images: _imageUrls,
        notes: _notesController.text.trim(),
        rating: _rating,
        tags: _selectedTags,
      );

      await DatabaseHelper.instance.createCookingLog(log);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save cooking log: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooking Complete'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.recipeName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '조리 완료: ${DateTime.now().toString().substring(0, 16)}',
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text('Rating', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  icon: Icon(
                    value <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () => setState(() => _rating = value),
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text('Tags', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final selected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                  selectedColor: Colors.black,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Photos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isPickingImage ? null : _pickImage,
              icon: _isPickingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate),
              label: Text(_isPickingImage ? 'Adding...' : 'Add Photo'),
            ),
            if (_imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageUrls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildImage(_imageUrls[index]),
                        ),
                        Positioned(
                          right: 4,
                          top: 4,
                          child: InkWell(
                            onTap: () => setState(() => _imageUrls.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text('Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'What worked, what changed, what to improve next time...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveCookingLog,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Cooking Log'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
