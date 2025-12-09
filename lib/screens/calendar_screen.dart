import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/diary.dart';
import '../models/couple_entry.dart';
import '../models/diary_space.dart';
import '../services/diary_service.dart';
import '../services/auth_service.dart';
import '../services/couple_service.dart';
import 'diary_write_screen.dart';
import 'personal_diary_detail_screen.dart';
import 'couple_diary_detail_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  final DiaryService _diaryService = DiaryService();
  final AuthService _authService = AuthService();
  final CoupleService _coupleService = CoupleService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 개인 일기
  Map<String, Diary> _personalDiaries = {};
  // 커플 일기
  Map<String, CoupleDiary> _coupleDiaries = {};

  bool _isLoading = false;
  bool _showCalendarTip = true;
  bool _coupleModeEnabled = false;
  String? _partnerId;
  String? _coupleId;

  // 현재 스페이스
  DiarySpace _currentSpace = DiarySpace.personal;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _checkCoupleStatus();
    _loadMonthDiaries();

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

  Future<void> _checkCoupleStatus() async {
    final userId = _authService.getCurrentUserId();
    if (userId != null) {
      final isConnected = await _coupleService.isCoupleConnected(userId);
      if (isConnected) {
        final partnerId = await _coupleService.getPartnerId(userId);
        final coupleId = await _coupleService.getCoupleId(userId);
        setState(() {
          _coupleModeEnabled = true;
          _partnerId = partnerId;
          _coupleId = coupleId;
        });
      }
    }
  }

  Future<void> _loadMonthDiaries() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    String? userId = _authService.getCurrentUserId();
    if (userId != null) {
      if (_currentSpace == DiarySpace.personal) {
        // 개인 일기 로드
        Map<String, Diary> diaries = await _diaryService.loadMonthDiaries(
          userId,
          _focusedDay.year,
          _focusedDay.month,
        );
        setState(() {
          _personalDiaries = diaries;
          _isLoading = false;
        });
      } else if (_currentSpace == DiarySpace.couple && _coupleId != null) {
        // 커플 일기 로드
        Map<String, CoupleDiary> coupleDiaries = await _diaryService.loadCoupleMonthDiaries(
          _coupleId!,
          _focusedDay.year,
          _focusedDay.month,
        );
        setState(() {
          _coupleDiaries = coupleDiaries;
          _isLoading = false;
        });
      }
    }
  }

  void _switchSpace(DiarySpace space) {
    if (_currentSpace == space) return;

    setState(() {
      _currentSpace = space;
    });
    _loadMonthDiaries();
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
        content: Text(
          '• 날짜를 클릭하면 일기를 작성할 수 있어요\n'
              '• 일기가 있는 날짜는 썸네일로 표시돼요\n'
              '• 형광펜 효과로 감정을 확인하세요\n'
              '• ${_coupleModeEnabled ? '하트/개인 아이콘으로 스페이스 전환\n• 커플 일기는 두 개의 감정이 표시돼요\n• ' : ''}좌우로 스와이프해서 월을 이동하세요',
          style: const TextStyle(fontSize: 15, height: 1.7),
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
                  child: Column(
                    children: [
                      Row(
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
                              // 스페이스 전환 버튼
                              if (_coupleModeEnabled) ...[
                                _buildSpaceToggle(),
                                const SizedBox(width: 8),
                              ],
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
                                          Row(
                                            children: [
                                              Text(
                                                _authService.isAnonymous() ? '게스트' : 'Google',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              if (_coupleModeEnabled) ...[
                                                const SizedBox(width: 8),
                                                Icon(Icons.favorite, size: 12, color: Colors.pink[300]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '커플 모드',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.pink[400],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ],
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

                      // 현재 스페이스 표시
                      if (_coupleModeEnabled) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _currentSpace == DiarySpace.couple
                                ? Colors.pink[50]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentSpace == DiarySpace.couple
                                    ? Icons.favorite
                                    : Icons.person,
                                size: 14,
                                color: _currentSpace == DiarySpace.couple
                                    ? Colors.pink[400]
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _currentSpace == DiarySpace.couple ? '커플 일기장' : '개인 일기장',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _currentSpace == DiarySpace.couple
                                      ? Colors.pink[700]
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                          _openDiary(selectedDay);
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
                            Navigator.pushAndRemoveUntil(
                              context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
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
                              ).then((_) {
                                _checkCoupleStatus();
                                _loadMonthDiaries();
                              });
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

  // 스페이스 전환 토글
  Widget _buildSpaceToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSpaceButton(
            icon: Icons.favorite,
            color: Colors.pink,
            isSelected: _currentSpace == DiarySpace.couple,
            onTap: () => _switchSpace(DiarySpace.couple),
          ),
          const SizedBox(width: 4),
          _buildSpaceButton(
            icon: Icons.person,
            color: Colors.grey[700]!,
            isSelected: _currentSpace == DiarySpace.personal,
            onTap: () => _switchSpace(DiarySpace.personal),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceButton({
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? color : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, bool isToday, bool isSelected, {bool isOutside = false}) {
    String dateKey = _formatDate(day);

    if (_currentSpace == DiarySpace.personal) {
      // 개인 일기
      return _buildPersonalDayCell(day, dateKey, isToday, isSelected, isOutside);
    } else {
      // 커플 일기
      return _buildCoupleDayCell(day, dateKey, isToday, isSelected, isOutside);
    }
  }

  // 개인 일기 셀
  Widget _buildPersonalDayCell(DateTime day, String dateKey, bool isToday, bool isSelected, bool isOutside) {
    Diary? diary = _personalDiaries[dateKey];
    bool hasDiary = diary != null && !isOutside;

    Color? emotionColor;
    if (hasDiary && diary.emotionColor.isNotEmpty) {
      emotionColor = Color(int.parse(diary.emotionColor.replaceFirst('#', '0xFF')));
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
          _focusedDay = day;
        });
        _openDiary(day);
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
            if (hasDiary && emotionColor != null)
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: CustomPaint(
                  size: const Size(double.infinity, 8),
                  painter: HighlighterPainter(color: emotionColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 커플 일기 셀 (두 개의 감정 표시)
  Widget _buildCoupleDayCell(DateTime day, String dateKey, bool isToday, bool isSelected, bool isOutside) {
    CoupleDiary? coupleDiary = _coupleDiaries[dateKey];
    bool hasDiary = coupleDiary != null && !isOutside;

    // 두 사람의 감정 색상
    List<Color> emotionColors = [];
    if (hasDiary) {
      for (var entry in coupleDiary.entries.values) {
        if (entry.emotionColor.isNotEmpty) {
          emotionColors.add(Color(int.parse(entry.emotionColor.replaceFirst('#', '0xFF'))));
        }
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = day;
          _focusedDay = day;
        });
        _openDiary(day);
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
            // 공통 이미지
            if (hasDiary && coupleDiary.sharedImageUrl.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.network(
                    coupleDiary.sharedImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.grey[200]);
                    },
                  ),
                ),
              ),

            // 날짜
            Positioned(
              top: 6,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: hasDiary && coupleDiary.sharedImageUrl.isNotEmpty
                      ? Colors.black.withOpacity(0.65)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasDiary && coupleDiary.sharedImageUrl.isNotEmpty
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

            // 두 개의 형광펜 (두 사람의 감정)
            if (hasDiary && emotionColors.isNotEmpty)
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Row(
                  children: [
                    if (emotionColors.isNotEmpty)
                      Expanded(
                        child: CustomPaint(
                          size: const Size(double.infinity, 8),
                          painter: HighlighterPainter(color: emotionColors[0]),
                        ),
                      ),
                    if (emotionColors.length > 1) ...[
                      const SizedBox(width: 2),
                      Expanded(
                        child: CustomPaint(
                          size: const Size(double.infinity, 8),
                          painter: HighlighterPainter(color: emotionColors[1]),
                        ),
                      ),
                    ],
                  ],
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

  void _openDiary(DateTime date) {
    if (_currentSpace == DiarySpace.personal) {
      // 개인 일기 작성/보기
      String dateKey = _formatDate(date);
      Diary? diary = _personalDiaries[dateKey];

      if (diary != null) {
        // 이미 작성된 개인 일기 보기
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonalDiaryDetailScreen(
              date: date,
              diary: diary,
            ),
          ),
        ).then((result) {
          if (result == true) {
            _loadMonthDiaries();
          }
        });
      } else {
        // 새 개인 일기 작성
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryWriteScreen(
              date: date,
              currentSpace: DiarySpace.personal,
            ),
          ),
        ).then((result) {
          if (result == true) {
            _loadMonthDiaries();
          }
        });
      }
    } else {
      // 커플 일기 작성/보기
      String dateKey = _formatDate(date);
      CoupleDiary? coupleDiary = _coupleDiaries[dateKey];

      if (coupleDiary != null) {
        // 이미 작성된 커플 일기 보기
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoupleDiaryDetailScreen(
              date: date,
              coupleDiary: coupleDiary,
              coupleId: _coupleId!,
              myUserId: _authService.getCurrentUserId()!,
            ),
          ),
        ).then((result) {
          if (result == true) {
            _loadMonthDiaries();
          }
        });
      } else {
        // 새 커플 일기 작성
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiaryWriteScreen(
              date: date,
              currentSpace: DiarySpace.couple,
              coupleId: _coupleId,
            ),
          ),
        ).then((result) {
          if (result == true) {
            _loadMonthDiaries();
          }
        });
      }
    }
  }
}

class HighlighterPainter extends CustomPainter {
  final Color color;

  HighlighterPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.3);

    double segments = 8;
    double segmentWidth = size.width / segments;

    for (int i = 0; i <= segments; i++) {
      double x = i * segmentWidth;
      double y = size.height * 0.3 + (i % 2 == 0 ? 0 : size.height * 0.1);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    final topPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final topPath = Path();
    topPath.moveTo(0, 0);
    topPath.lineTo(size.width, 0);
    topPath.lineTo(size.width, size.height * 0.4);

    for (int i = segments.toInt(); i >= 0; i--) {
      double x = i * segmentWidth;
      double y = size.height * 0.4 - (i % 2 == 0 ? size.height * 0.1 : 0);
      topPath.lineTo(x, y);
    }

    topPath.close();
    canvas.drawPath(topPath, topPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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