import 'package:flutter/material.dart';
import 'dart:math';
import '../models/diary.dart';
import '../models/diary_space.dart';
import '../services/diary_service.dart';
import '../services/auth_service.dart';
import '../services/couple_service.dart';
import 'diary_write_screen.dart';
import 'personal_diary_detail_screen.dart';
import 'calendar_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DiaryService _diaryService = DiaryService();
  final AuthService _authService = AuthService();
  final CoupleService _coupleService = CoupleService();

  bool _isLoading = true;
  Diary? _todayDiary;
  List<Diary> _recentDiaries = [];
  int _monthlyCount = 0;
  String _topEmotion = '기쁨';
  int _coupleCount = 0;
  bool _coupleModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _authService.getCurrentUserId();
      if (userId == null) return;

      // 커플 상태 확인
      final coupleId = await _coupleService.getCoupleId(userId);
      _coupleModeEnabled = coupleId != null;

      // 오늘 날짜
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // 오늘 일기 로드
      _todayDiary = await _diaryService.loadDiary(userId, todayStr);

      // 이번 달 일기 로드
      final firstDay = DateTime(today.year, today.month, 1);
      final lastDay = DateTime(today.year, today.month + 1, 0);

      Map<String, Diary> monthlyDiaries = {};
      Map<String, int> emotionCount = {};

      for (int day = 1; day <= lastDay.day; day++) {
        final date = DateTime(today.year, today.month, day);
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        final diary = await _diaryService.loadDiary(userId, dateStr);
        if (diary != null) {
          monthlyDiaries[dateStr] = diary;
          emotionCount[diary.emotion] = (emotionCount[diary.emotion] ?? 0) + 1;
        }
      }

      _monthlyCount = monthlyDiaries.length;

      // 가장 많은 감정
      if (emotionCount.isNotEmpty) {
        _topEmotion = emotionCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      // 최근 일기 5개
      _recentDiaries = monthlyDiaries.values.toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _recentDiaries = _recentDiaries.take(5).toList();

      // 커플 일기 개수
      if (_coupleModeEnabled && coupleId != null) {
        int coupleTotal = 0;
        for (int day = 1; day <= lastDay.day; day++) {
          final date = DateTime(today.year, today.month, day);
          final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

          final coupleDiary = await _diaryService.loadCoupleDiary(coupleId, dateStr);
          if (coupleDiary != null && coupleDiary.entries.isNotEmpty) {
            coupleTotal++;
          }
        }
        _coupleCount = coupleTotal;
      }
    } catch (e) {
      print('데이터 로드 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "좋은 아침이에요! ☀️";
    } else if (hour < 18) {
      return "좋은 오후예요! 🌤️";
    } else {
      return "하루 마무리 시간이에요 🌙";
    }
  }

  String _getRandomMessage() {
    final messages = [
      "오늘의 감정을 기록해보세요",
      "오늘도 좋은 하루 보내셨나요?",
      "하루의 순간들을 남겨보세요",
      "소중한 하루를 기억해요",
      "오늘 하루는 어떠셨나요?",
    ];
    return messages[Random().nextInt(messages.length)];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 인사말
                      _buildGreetingSection(),
                      const SizedBox(height: 24),

                      // 오늘 일기 버튼
                      _buildTodayDiaryButton(),
                      const SizedBox(height: 32),

                      // 이번 달 통계
                      _buildMonthlyStats(),
                      const SizedBox(height: 32),

                      // 최근 일기
                      if (_recentDiaries.isNotEmpty) _buildRecentDiaries(),

                      const SizedBox(height: 80), // 하단 네비게이션 공간
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 하단 네비게이션
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _NavButton(
                      icon: Icons.home_rounded,
                      label: '홈',
                      isSelected: true,
                      onTap: () {},
                    ),
                    _NavButton(
                      icon: Icons.calendar_today_rounded,
                      label: '달력',
                      isSelected: false,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalendarScreen(),
                          ),
                        );
                      },
                    ),
                    _NavButton(
                      icon: Icons.settings_rounded,
                      label: '설정',
                      isSelected: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        ).then((_) => _loadData());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getGreeting(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _getRandomMessage(),
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayDiaryButton() {
    final hasTodayDiary = _todayDiary != null;

    return InkWell(
      onTap: () {
        if (hasTodayDiary) {
          // 오늘 일기 보기
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonalDiaryDetailScreen(
                date: DateTime.now(),
                diary: _todayDiary!,
              ),
            ),
          ).then((_) => _loadData());
        } else {
          // 오늘 일기 쓰기
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DiaryWriteScreen(
                date: DateTime.now(),
                currentSpace: DiarySpace.personal,
              ),
            ),
          ).then((_) => _loadData());
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasTodayDiary ? Colors.green[300]! : Colors.purple[200]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (hasTodayDiary ? Colors.green : Colors.purple).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasTodayDiary ? Icons.check_circle : Icons.edit_note,
              color: hasTodayDiary ? Colors.green[400] : Colors.purple[300],
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              hasTodayDiary ? '오늘 일기 보러가기' : '오늘 일기 쓰기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: hasTodayDiary ? Colors.green[700] : Colors.purple[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '이번 달',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${DateTime.now().month}월)',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: '📝',
                value: '$_monthlyCount일',
                label: '작성',
                color: Colors.blue[50]!,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: '😊',
                value: _topEmotion,
                label: '주요감정',
                color: Colors.yellow[50]!,
              ),
            ),
            if (_coupleModeEnabled) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: '💕',
                  value: '$_coupleCount개',
                  label: '커플',
                  color: Colors.pink[50]!,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentDiaries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '최근 일기',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.85),
            itemCount: _recentDiaries.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildRecentDiaryCard(_recentDiaries[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentDiaryCard(Diary diary) {
    final date = DateTime.fromMillisecondsSinceEpoch(diary.timestamp);
    final monthNames = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalDiaryDetailScreen(
              date: date,
              diary: diary,
            ),
          ),
        ).then((_) => _loadData());
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: Row(
          children: [
            // 좌측: 이미지
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: diary.imageUrl.isNotEmpty
                  ? Image.network(
                diary.imageUrl,
                width: 120,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
              )
                  : _buildPlaceholderImage(),
            ),

            // 우측: 날짜 (세로 배치)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      date.year.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monthNames[date.month - 1],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      date.day.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 120,
      height: 140,
      color: Colors.grey[200],
      child: Icon(
        Icons.image,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple[50] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.purple[400] : Colors.grey[400],
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.purple[700] : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
