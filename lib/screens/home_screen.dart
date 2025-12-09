import 'package:flutter/material.dart';
import '../models/diary_count.dart';
import 'settings_screen.dart';
import '../models/diary_count.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}class _HomeScreenState extends State<HomeScreen> {
  int get diaryCount => DiaryManager.instance.diaryCount;

  String getBackgroundImage() {
    if (diaryCount < 10) return 'assets/images/6.png';
    if (diaryCount < 20) return 'assets/images/5.png';
    if (diaryCount < 30) return 'assets/images/4.png';
    if (diaryCount < 50) return 'assets/images/3.png';
    if (diaryCount < 100) return 'assets/images/2.png';
    return 'assets/images/1.png';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            // 배경 이미지
            Positioned.fill(
              child: Image.asset(
                getBackgroundImage(),
                fit: BoxFit.cover,
              ),
            ),

            Column(
              children: [
                SizedBox(height: 16),
                // 상단 헤더 (CalendarScreen 스타일)
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '추억을 쌓은 횟수',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$diaryCount',
                            style: const TextStyle(
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                //공간 떄우기
                Expanded(
                  child: Center(
                    child: Text(
                      ' ',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                  ),
                ),

                // 하단바
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
                            onTap: () {
                              // 홈 화면이므로 특별한 동작 없음
                            },
                          ),
                          _NavButton(
                            icon: Icons.calendar_today_rounded,
                            label: '달력',
                            isSelected: false,
                            onTap: () {
                              Navigator.pushNamed(context, '/calendar');
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
          ],
        ),
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