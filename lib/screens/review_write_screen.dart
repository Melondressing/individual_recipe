import 'package:flutter/material.dart';

import '../models/review.dart';

class ReviewWriteScreen extends StatefulWidget {
  final String recipeId;
  final String recipeName;

  const ReviewWriteScreen({
    super.key,
    required this.recipeId,
    required this.recipeName,
  });

  @override
  State<ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<ReviewWriteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController(text: 'Me');
  final _reviewController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _userNameController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a rating.')),
      );
      return;
    }

    final now = DateTime.now();
    final review = Review(
      id: 'review_${now.microsecondsSinceEpoch}',
      recipeId: widget.recipeId,
      recipeName: widget.recipeName,
      userName: _userNameController.text.trim().isEmpty
          ? 'Me'
          : _userNameController.text.trim(),
      text: _reviewController.text.trim(),
      rating: _rating,
      createdAt: now,
    );

    Navigator.pop(context, review);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Write Review'),
        actions: [
          IconButton(
            onPressed: _submit,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.recipeName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _userNameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Rating', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = value),
                    icon: Icon(
                      value <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _reviewController,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Review',
                  hintText: 'Write what changed, what worked, and what to improve.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Review text is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: const Text('Save Review'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
