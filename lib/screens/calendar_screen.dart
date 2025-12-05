import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/diary.dart';
import '../services/diary_service.dart';
import '../services/auth_service.dart';
import 'diary_write_screen.dart';
import 'settings_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  final DiaryService _diaryService = DiaryService();
  final AuthService _authService = AuthService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, Diary> _diaries = {};
  bool _isLoading = false;
  bool _showCalendarTip = true;
  bool _coupleModeEnabled = false;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMonthDiaries();

    // FAB 애니메이션
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fabAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadMonthDiaries() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    String? userId = _authService.getCurrentUserId();
    if (userId != null) {
      Map<String, Diary> diaries = await _diaryService.loadMonthDiaries(
        userId,
        _focusedDay.year,
        _focusedDay.month,
      );
      setState(() {
        _diaries = diaries;
        _isLoading = false;
      });
    }
  }

  void _showCalendarTipDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.orange[600]),
            const SizedBox(width: 12),
            const Text('캘린더 팁'),
          ],
        ),
        content: const Text(
          '• 날짜를 클릭하면 일기를 작성할 수 있어요\n'
              '• 일기가 있는 날짜는 썸네일로 표시돼요\n'
              '• 우측 상단 색상 배지로 감정을 확인하세요\n'
              '• 좌우로 스와이프해서 월을 이동하세요',
          style: TextStyle(fontSize: 15, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_focusedDay.year}년',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_focusedDay.month}월',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                              letterSpacing: -0.8,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // 커플 모드 하트 아이콘
                          if (_coupleModeEnabled)
                            Container(
                              margin: const EdgeInsets.only(right: 4),
                              child: IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.pink, size: 26),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SettingsScreen(openCoupleMode: true),
                                    ),
                                  ).then((_) {
                                    setState(() {});
                                  });
                                },
                              ),
                            ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, size: 24, color: Colors.grey[700]),
                            offset: const Offset(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem<String>(
                                enabled: false,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _authService.isAnonymous()
                                            ? '익명 사용자'
                                            : _authService.getCurrentUser()?.email ?? '사용자',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF212121),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _authService.isAnonymous() ? '게스트' : 'Google',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, size: 20, color: Colors.red[400]),
                                    const SizedBox(width: 12),
                                    const Text('로그아웃'),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'logout') {
                                await _authService.signOut();
                                if (mounted) {
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/login',
                                        (route) => false,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 달력
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: TableCalendar(
                        firstDay: DateTime(2020, 1, 1),
                        lastDay: DateTime(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        calendarFormat: CalendarFormat.month,
                        startingDayOfWeek: StartingDayOfWeek.sunday,
                        headerVisible: false,
                        daysOfWeekHeight: 48,
                        rowHeight: (screenHeight - 320) / 6,
                        availableGestures: AvailableGestures.horizontalSwipe,
                        calendarStyle: const CalendarStyle(
                          cellMargin: EdgeInsets.all(4),
                          cellPadding: EdgeInsets.zero,
                          defaultDecoration: BoxDecoration(),
                          todayDecoration: BoxDecoration(),
                          selectedDecoration: BoxDecoration(),
                          outsideDecoration: BoxDecoration(),
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          weekendStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.red[400],
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });
                          _openDiaryWrite(selectedDay);
                        },
                        onPageChanged: (focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                          });
                          _loadMonthDiaries();
                        },
                        calendarBuilders: CalendarBuilders(
                          defaultBuilder: (context, day, focusedDay) {
                            return _buildDayCell(day, false, false);
                          },
                          todayBuilder: (context, day, focusedDay) {
                            return _buildDayCell(day, true, false);
                          },
                          selectedBuilder: (context, day, focusedDay) {
                            return _buildDayCell(day, false, true);
                          },
                          outsideBuilder: (context, day, focusedDay) {
                            return _buildDayCell(day, false, false, isOutside: true);
                          },
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
                            isSelected: false,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('홈 화면 준비 중')),
                              );
                            },
                          ),
                          _NavButton(
                            icon: Icons.calendar_today_rounded,
                            label: '달력',
                            isSelected: true,
                            onTap: () {},
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
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 플로팅 캘린더 팁 버튼
            if (_showCalendarTip)
              Positioned(
                bottom: 90,
                right: 20,
                child: ScaleTransition(
                  scale: _fabScaleAnimation,
                  child: GestureDetector(
                    onTap: _showCalendarTipDialog,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange[400]!,
                            Colors.orange[600]!,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(
                              Icons.lightbulb_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showCalendarTip = false;
                                });
                              },
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.red[500],
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday, bool isSelected, {bool isOutside = false}) {
    String dateKey = _formatDate(day);
    Diary? diary = _diaries[dateKey];
    bool hasDiary = diary != null && !isOutside;

    // 감정 색상
    Color? emotionColor;
    if (hasDiary && diary.emotionColor.isNotEmpty) {
      emotionColor = Color(
        int.parse(diary.emotionColor.replaceFirst('#', '0xFF')),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
          _focusedDay = day;
        });
        _openDiaryWrite(day);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isOutside ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isToday
              ? Border.all(color: const Color(0xFFB39DDB), width: 2.5)
              : isSelected
              ? Border.all(color: const Color(0xFFB39DDB).withOpacity(0.3), width: 2)
              : Border.all(color: Colors.grey[100]!, width: 1),
          boxShadow: hasDiary && !isOutside
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Stack(
          children: [
            // 썸네일 이미지
            if (hasDiary && diary.imageUrl.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.network(
                    diary.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.grey[200]);
                    },
                  ),
                ),
              ),

            // 날짜 (왼쪽 상단)
            Positioned(
              top: 6,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: hasDiary && diary.imageUrl.isNotEmpty
                      ? Colors.black.withOpacity(0.65)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasDiary && diary.imageUrl.isNotEmpty
                        ? Colors.white
                        : isOutside
                        ? Colors.grey[400]
                        : day.weekday == DateTime.sunday
                        ? Colors.red[400]
                        : day.weekday == DateTime.saturday
                        ? Colors.blue[400]
                        : const Color(0xFF212121),
                  ),
                ),
              ),
            ),

            // 감정 색상 배지 (우측 상단)
            if (hasDiary && emotionColor != null)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: emotionColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: emotionColor.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _openDiaryWrite(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryWriteScreen(date: date),
      ),
    ).then((result) {
      if (result == true) {
        _loadMonthDiaries();
      }
    });
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? const Color(0xFFB39DDB) : Colors.grey[400],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? const Color(0xFFB39DDB) : Colors.grey[500],
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}