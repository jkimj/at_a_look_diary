// lib/models/couple_entry.dart

class CoupleEntry {
  final String userId;
  final String emotion;
  final String emotionColor;
  final String text;
  final int timestamp;

  CoupleEntry({
    required this.userId,
    required this.emotion,
    required this.emotionColor,
    required this.text,
    required this.timestamp,
  });

  factory CoupleEntry.fromJson(Map<String, dynamic> json, String userId) {
    return CoupleEntry(
      userId: userId,
      emotion: json['emotion'] ?? '',
      emotionColor: json['emotionColor'] ?? '',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'emotionColor': emotionColor,
      'text': text,
      'timestamp': timestamp,
    };
  }
}

// 커플 일기 데이터 (한 날짜에 두 사람 엔트리 + 공통 이미지)
class CoupleDiary {
  final String date;
  final Map<String, CoupleEntry> entries; // userId -> CoupleEntry
  final String sharedImageUrl;

  CoupleDiary({
    required this.date,
    required this.entries,
    required this.sharedImageUrl,
  });

  factory CoupleDiary.fromJson(String date, Map<String, dynamic> json) {
    Map<String, CoupleEntry> entries = {};

    if (json['entries'] != null) {
      Map<dynamic, dynamic> entriesData = json['entries'] as Map;
      entriesData.forEach((userId, entryData) {
        entries[userId] = CoupleEntry.fromJson(
          Map<String, dynamic>.from(entryData as Map),
          userId,
        );
      });
    }

    return CoupleDiary(
      date: date,
      entries: entries,
      sharedImageUrl: json['sharedImage'] ?? '',
    );
  }

  // 특정 유저의 엔트리 가져오기
  CoupleEntry? getEntryByUserId(String userId) {
    return entries[userId];
  }

  // 두 사람 모두 작성했는지 확인
  bool isBothWritten() {
    return entries.length == 2;
  }

  // 내가 작성했는지 확인
  bool hasMyEntry(String myUserId) {
    return entries.containsKey(myUserId);
  }

  // 파트너가 작성했는지 확인
  bool hasPartnerEntry(String myUserId) {
    return entries.keys.any((userId) => userId != myUserId);
  }
}