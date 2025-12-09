class DiaryManager {
  DiaryManager._privateConstructor();
  static final DiaryManager instance = DiaryManager._privateConstructor();

  int diaryCount = 0;
  List<String> recordedDates = [];

  void addDiaryIfNew(String dateKey) {
    if (!recordedDates.contains(dateKey)) {
      diaryCount += 1;
      recordedDates.add(dateKey);
    }
  }
}
