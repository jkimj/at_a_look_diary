import 'package:flutter/material.dart';
import '../models/diary.dart';
import '../models/diary_space.dart';
import '../services/diary_service.dart';
import '../services/auth_service.dart';
import 'diary_write_screen.dart';
import '../models/diary_count.dart';


class PersonalDiaryDetailScreen extends StatefulWidget {
  final DateTime date;
  final Diary diary;

  const PersonalDiaryDetailScreen({
    super.key,
    required this.date,
    required this.diary,
  });

  @override
  State<PersonalDiaryDetailScreen> createState() => _PersonalDiaryDetailScreenState();
}

class _PersonalDiaryDetailScreenState extends State<PersonalDiaryDetailScreen> {
  final DiaryService _diaryService = DiaryService();
  final AuthService _authService = AuthService();
  @override
  void initState() {
    super.initState();

    final dateKey =
        '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';

    DiaryManager.instance.addDiaryIfNew(dateKey);
  }

  String _formatDisplayDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String _formatTimestamp(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.year}.${dateTime.month}.${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getEmotionColor() {
    try {
      return Color(int.parse(widget.diary.emotionColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _formatDisplayDate(widget.date),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                _editDiary();
              } else if (value == 'delete') {
                _showDeleteDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('수정'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outlined, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('삭제', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지
            if (widget.diary.imageUrl.isNotEmpty)
              Image.network(
                widget.diary.imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                    ),
                  );
                },
              ),

            // 내용
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 감정
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getEmotionColor().withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getEmotionColor(),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sentiment_satisfied,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.diary.emotion,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '작성: ${_formatTimestamp(widget.diary.timestamp)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 일기 내용
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.diary.text,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
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

  void _editDiary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryWriteScreen(
          date: widget.date,
          existingDiary: widget.diary,
          currentSpace: DiarySpace.personal,
        ),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.pop(context, true);
      }
    });
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일기 삭제'),
        content: const Text('이 일기를 삭제하시겠습니까?\n삭제된 일기는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDiary();
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDiary() async {
    try {
      final userId = _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('로그인이 필요합니다');
      }

      String dateStr = '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';
      bool success = await _diaryService.deleteDiary(userId, dateStr);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('일기가 삭제되었습니다')),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('삭제에 실패했습니다');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }
}