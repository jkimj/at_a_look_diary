import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/diary.dart';
import '../services/diary_service.dart';
import '../services/auth_service.dart';
import 'diary_detail_screen.dart';
import 'diary_write_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DiaryService _diaryService = DiaryService();
  final AuthService _authService = AuthService();

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, Diary> _diaries = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadMonthDiaries();
  }

  Future<void> _loadMonthDiaries() async {
    setState(() => _isLoading = true);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // 커스텀 헤더
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_focusedDay.month}월',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border, size: 28),
                        onPressed: () {
                          // 커플 모드
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz, size: 28),
                        itemBuilder: (context) => [
                          PopupMenuItem<String>(
                            enabled: false,
                            child: Text(
                              _authService.isAnonymous()
                                  ? '익명 사용자'
                                  : _authService.getCurrentUser()?.email ?? '사용자',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Text('로그아웃'),
                          ),
                        ],
                        onSelected: (value) async {
                          if (value == 'logout') {
                            await _authService.signOut();
                            if (mounted) {
                              Navigator.of(context).pushReplacementNamed('/');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 달력 (화면 대부분 차지)
            Expanded(
              child: TableCalendar(
                firstDay: DateTime(2020, 1, 1),
                lastDay: DateTime(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.sunday,
                headerVisible: false,
                daysOfWeekHeight: 40,
                rowHeight: 110, // 셀 높이 크게
                calendarStyle: CalendarStyle(
                  cellMargin: const EdgeInsets.all(4),
                  defaultDecoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  outsideDecoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  defaultTextStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  weekendTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[400],
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                  weekendStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.red[400],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _openDiaryWrite(selectedDay); // 바로 작성 화면으로
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  _loadMonthDiaries();
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    String dateKey = _formatDate(day);
                    Diary? diary = _diaries[dateKey];
                    return _buildDayCell(day, diary);
                  },
                  todayBuilder: (context, day, focusedDay) {
                    String dateKey = _formatDate(day);
                    Diary? diary = _diaries[dateKey];
                    return _buildDayCell(day, diary, isToday: true);
                  },
                  outsideBuilder: (context, day, focusedDay) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 로딩 인디케이터
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day, Diary? diary, {bool isToday = false}) {
    bool hasDiary = diary != null;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Column(
        children: [
          // 날짜
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                color: day.weekday == DateTime.sunday
                    ? Colors.red[400]
                    : day.weekday == DateTime.saturday
                    ? Colors.blue[400]
                    : Colors.black87,
              ),
            ),
          ),

          // 썸네일 이미지 (일기가 있으면)
          if (hasDiary && diary.imageUrl.isNotEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    diary.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            )
          else if (hasDiary)
          // 이미지 없으면 감정 표시
            Expanded(
              child: Center(
                child: Text(
                  diary.emotion,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _openDiaryDetail(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryDetailScreen(date: date),
      ),
    ).then((_) => _loadMonthDiaries());
  }

  void _openDiaryWrite(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiaryWriteScreen(date: date),
      ),
    ).then((_) => _loadMonthDiaries());
  }
}