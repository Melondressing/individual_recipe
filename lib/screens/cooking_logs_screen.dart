import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../models/cooking_log.dart';
import '../database/database_helper.dart';

class CookingLogsScreen extends StatefulWidget {
  final String? recipeId; // Optional: show logs for specific recipe

  const CookingLogsScreen({super.key, this.recipeId});

  @override
  State<CookingLogsScreen> createState() => _CookingLogsScreenState();
}

class _CookingLogsScreenState extends State<CookingLogsScreen> {
  List<CookingLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);

    try {
      final db = DatabaseHelper.instance;
      List<CookingLog> logs;
      
      if (widget.recipeId != null) {
        logs = await db.getCookingLogsByRecipe(widget.recipeId!);
      } else {
        logs = await db.getAllCookingLogs();
      }

      setState(() {
        _logs = logs;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [Cooking Logs] Failed to load logs: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImage(String imageUrl) {
    try {
      if (imageUrl.startsWith('data:image')) {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        
        return Image.memory(
          bytes,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 24),
            );
          },
        );
      } else {
        return Image.network(
          imageUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 80,
              height: 80,
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 24),
            );
          },
        );
      }
    } catch (e) {
      return Container(
        width: 80,
        height: 80,
        color: Colors.grey[300],
        child: const Icon(Icons.broken_image, size: 24),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipeId != null ? '조리 기록' : '전체 조리 기록'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '아직 조리 기록이 없습니다',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '레시피를 조리하고 인증샷을 남겨보세요!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLogs,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return _buildLogCard(log);
                    },
                  ),
                ),
    );
  }

  Widget _buildLogCard(CookingLog log) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Recipe name and date
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.recipeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(log.cookedAt),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (log.rating > 0)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${log.rating}/5',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            
            // Tags
            if (log.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: log.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            
            // Images
            if (log.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: log.images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImage(log.images[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Notes
            if (log.notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  log.notes,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '방금 전';
        }
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    }
  }
}
