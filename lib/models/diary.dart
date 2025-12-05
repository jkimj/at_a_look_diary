class Diary {
  final String diaryId;
  final String emotion;
  final String emotionColor;
  final String text;
  final String imageUrl;
  final int timestamp;

  Diary({
    required this.diaryId,
    required this.emotion,
    required this.emotionColor,
    required this.text,
    required this.imageUrl,
    required this.timestamp,
  });

  // Firebase에서 데이터 가져올 때
  factory Diary.fromJson(Map<String, dynamic> json) {
    return Diary(
      diaryId: json['diaryId'] ?? '',
      emotion: json['emotion'] ?? '',
      emotionColor: json['emotionColor'] ?? '',
      text: json['text'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      timestamp: json['timestamp'] ?? 0,
    );
  }

  // Firebase에 데이터 저장할 때
  Map<String, dynamic> toJson() {
    return {
      'diaryId': diaryId,
      'emotion': emotion,
      'emotionColor': emotionColor,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
    };
  }
}
