import 'package:flutter/material.dart';
import '../models/diary.dart';
import '../services/diary_service.dart';
import '../services/auth_service.dart';
import 'diary_write_screen.dart';

class DiaryDetailScreen extends StatefulWidget {
  final DateTime date;

  const DiaryDetailScreen({super.key, required this.date});

  @override
  State<DiaryDetailScreen> createState() => _DiaryDetailScreenState();
}

class _DiaryDetailScreenState extends State<DiaryDetailScreen> {
  final DiaryService _diaryService = DiaryService();
  final AuthService _authService = AuthService();

  Diary? _diary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiary();
  }

  Future<void> _loadDiary() async {
    String? userId = _authService.getCurrentUserId();
    if (userId != null) {
      String dateKey = _formatDate(widget.date);
      Diary? diary = await _diaryService.loadDiary(userId, dateKey);

      setState(() {
        _diary = diary;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDisplayDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDisplayDate(widget.date)),
        actions: _diary != null
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editDiary,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteDiary,
          ),
        ]
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _diary == null
          ? _buildEmptyState()
          : _buildDiaryContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            '작성된 일기가 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _writeDiary,
            icon: const Icon(Icons.add),
            label: const Text('일기 작성하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryContent() {
    if (_diary == null) return const SizedBox();

    Color emotionColor = Color(
      int.parse(_diary!.emotionColor.replaceFirst('#', '0xFF')),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 감정 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: emotionColor.withOpacity(0.2),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: emotionColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sentiment_satisfied,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  _diary!.emotion,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 이미지
          if (_diary!.imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _diary!.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // 일기 내용
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '오늘의 기록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _diary!.text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          // 작성 시간
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '작성: ${_formatTimestamp(_diary!.timestamp)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.year}.${dateTime.month}.${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _writeDiary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryWriteScreen(date: widget.date),
      ),
    ).then((_) {
      _loadDiary();
    });
  }

  void _editDiary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryWriteScreen(
          date: widget.date,
          existingDiary: _diary,
        ),
      ),
    ).then((_) {
      _loadDiary();
    });
  }

  void _deleteDiary() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('일기 삭제'),
        content: const Text('정말 이 일기를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              String? userId = _authService.getCurrentUserId();
              if (userId != null) {
                String dateKey = _formatDate(widget.date);
                bool success = await _diaryService.deleteDiary(userId, dateKey);

                if (mounted) {
                  Navigator.pop(context); // 다이얼로그 닫기
                  if (success) {
                    Navigator.pop(context); // 상세 화면 닫기
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('삭제 실패')),
                    );
                  }
                }
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}