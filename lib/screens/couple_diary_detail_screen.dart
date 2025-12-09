import 'package:flutter/material.dart';
import '../models/couple_entry.dart';
import '../models/diary_space.dart';
import '../services/diary_service.dart';
import '../services/auth_service.dart';
import 'diary_write_screen.dart';

class CoupleDiaryDetailScreen extends StatefulWidget {
  final DateTime date;
  final CoupleDiary coupleDiary;
  final String coupleId;
  final String myUserId;

  const CoupleDiaryDetailScreen({
    super.key,
    required this.date,
    required this.coupleDiary,
    required this.coupleId,
    required this.myUserId,
  });

  @override
  State<CoupleDiaryDetailScreen> createState() => _CoupleDiaryDetailScreenState();
}

class _CoupleDiaryDetailScreenState extends State<CoupleDiaryDetailScreen> {
  final DiaryService _diaryService = DiaryService();
  final AuthService _authService = AuthService();

  String _formatDisplayDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String _formatTimestamp(int timestamp) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dateTime.year}.${dateTime.month}.${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final myEntry = widget.coupleDiary.getEntryByUserId(widget.myUserId);
    final partnerEntry = widget.coupleDiary.entries.values
        .firstWhere((entry) => entry.userId != widget.myUserId, orElse: () => CoupleEntry(
      userId: '',
      emotion: '',
      emotionColor: '',
      text: '',
      timestamp: 0,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_formatDisplayDate(widget.date)),
        actions: [
          // 공통 이미지 삭제 버튼 (둘 중 한 명이 삭제 가능)
          if (widget.coupleDiary.sharedImageUrl.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outlined),
              tooltip: '공통 이미지 삭제',
              onPressed: _deleteSharedImage,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 공통 이미지
            if (widget.coupleDiary.sharedImageUrl.isNotEmpty)
              Stack(
                children: [
                  Image.network(
                    widget.coupleDiary.sharedImageUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.pink[400],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.favorite, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            '공통 이미지',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // 내 일기
            if (myEntry != null)
              _buildEntrySection(
                entry: myEntry,
                isMyEntry: true,
                label: '내 일기',
              ),

            // 구분선
            if (myEntry != null && partnerEntry.userId.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.favorite, color: Colors.pink[200], size: 20),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
              ),

            // 파트너 일기
            if (partnerEntry.userId.isNotEmpty)
              _buildEntrySection(
                entry: partnerEntry,
                isMyEntry: false,
                label: '파트너 일기',
              ),

            // 빈 엔트리 안내
            if (myEntry == null)
              _buildEmptyEntry(true),
            if (partnerEntry.userId.isEmpty)
              _buildEmptyEntry(false),

            const SizedBox(height: 40),
          ],
        ),
      ),

      // 내 일기 추가 버튼
      floatingActionButton: myEntry == null
          ? FloatingActionButton.extended(
        onPressed: _writeMyEntry,
        backgroundColor: Colors.pink[400],
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          '내 일기 작성',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      )
          : null,
    );
  }

  Widget _buildEntrySection({
    required CoupleEntry entry,
    required bool isMyEntry,
    required String label,
  }) {
    Color emotionColor = Color(
      int.parse(entry.emotionColor.replaceFirst('#', '0xFF')),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: emotionColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: emotionColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isMyEntry ? Icons.person : Icons.favorite,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.emotion,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // 수정/삭제 버튼 (본인만)
                if (isMyEntry)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: Colors.grey[700]),
                            const SizedBox(width: 12),
                            const Text('수정'),
                          ],
                        ),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red[400]),
                            const SizedBox(width: 12),
                            const Text('삭제'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editMyEntry();
                      } else if (value == 'delete') {
                        _deleteMyEntry();
                      }
                    },
                  ),
              ],
            ),
          ),

          // 일기 내용
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.text,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '작성: ${_formatTimestamp(entry.timestamp)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyEntry(bool isMyEntry) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              isMyEntry ? Icons.person_outline : Icons.favorite_border,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              isMyEntry ? '아직 작성하지 않았어요' : '파트너가 아직 작성하지 않았어요',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            if (isMyEntry) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _writeMyEntry,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('작성하기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[400],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _writeMyEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryWriteScreen(
          date: widget.date,
          currentSpace: DiarySpace.couple,
          coupleId: widget.coupleId,
        ),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.pop(context, true);
      }
    });
  }

  void _editMyEntry() {
    final myEntry = widget.coupleDiary.getEntryByUserId(widget.myUserId);
    if (myEntry == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryWriteScreen(
          date: widget.date,
          currentSpace: DiarySpace.couple,
          coupleId: widget.coupleId,
          existingEntry: myEntry, // 기존 엔트리 전달
        ),
      ),
    ).then((result) {
      if (result == true) {
        Navigator.pop(context, true);
      }
    });
  }

  void _deleteMyEntry() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('내 일기 삭제'),
        content: const Text('내 일기를 삭제하시겠습니까?\n(파트너의 일기는 유지됩니다)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              String dateKey = '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';

              bool success = await _diaryService.deleteMyCoupleDiaryEntry(
                widget.coupleId,
                widget.myUserId,
                dateKey,
              );

              if (mounted) {
                if (success) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('삭제 실패')),
                  );
                }
              }
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteSharedImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공통 이미지 삭제'),
        content: const Text('공통 이미지를 삭제하시겠습니까?\n(두 사람 모두에게 적용됩니다)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              String dateKey = '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';

              bool success = await _diaryService.deleteSharedImage(
                widget.coupleId,
                dateKey,
              );

              if (mounted) {
                if (success) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('삭제 실패')),
                  );
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