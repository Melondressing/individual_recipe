import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import 'cooking_complete_screen.dart';

class CookingModeScreen extends StatefulWidget {
  final Recipe recipe;

  const CookingModeScreen({super.key, required this.recipe});

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  int _currentStep = 0;

  List<String> get _steps => widget.recipe.steps.isEmpty
      ? const ['No cooking steps have been added yet.']
      : widget.recipe.steps;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _previousStep() {
    if (_currentStep <= 0) return;
    setState(() => _currentStep--);
    HapticFeedback.lightImpact();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      HapticFeedback.lightImpact();
    } else {
      _showCompletionDialog();
    }
  }

  Future<void> _showCompletionDialog() async {
    final provider = context.read<RecipeProvider>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CookingCompleteScreen(
          recipeId: widget.recipe.id,
          recipeName: widget.recipe.name,
        ),
      ),
    );

    if (result != true) return;
    await provider.markAsUsed(widget.recipe.id);
    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Great job! Cooking log saved.')),
    );
  }

  List<Widget> _extractTimers(String stepText) {
    final timePattern = RegExp(
      r'(\d+)\s*(minutes?|mins?|seconds?|secs?|hours?)',
      caseSensitive: false,
    );
    final matches = timePattern.allMatches(stepText);
    if (matches.isEmpty) return [];

    return matches.map((match) {
      final duration = int.parse(match.group(1)!);
      final unit = match.group(2)!.toLowerCase();
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.timer),
          label: Text('Timer found: $duration ${unit[0].toUpperCase()}${unit.substring(1)}'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Use your phone timer for $duration $unit.'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final int stepIndex = _currentStep.clamp(0, _steps.length - 1);
    final currentStepText = _steps[stepIndex];
    final timerButtons = _extractTimers(currentStepText);
    final progress = (_currentStep + 1) / _steps.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade900,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.recipe.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade800,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of ${_steps.length}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        currentStepText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (timerButtons.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        ...timerButtons,
                      ],
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade900,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _currentStep > 0 ? _previousStep : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        side: const BorderSide(color: Colors.white),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _nextStep,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.green.shade600,
                      ),
                      child: Text(_currentStep < _steps.length - 1 ? 'Next' : 'Complete'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
