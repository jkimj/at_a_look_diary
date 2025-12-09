
Future<void> _loadDiary() async {
String? userId = _authService.getCurrentUserId();
if (userId != null) {
String dateKey = _formatDate(widget.date);
Diary? diary = await _diaryService.loadDiary(userId, dateKey);

setState(() {
_diary = diary;
_isLoading = false;

if (diary != null) {
DiaryManager.instance.addDiaryIfNew(dateKey);
}
});
}


import 'screens/home_screen.dart';

'/home': (context) => HomeScreen(),