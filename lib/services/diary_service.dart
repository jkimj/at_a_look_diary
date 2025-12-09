import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/diary.dart';
import '../models/couple_entry.dart';

class DiaryService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== 개인 일기 ====================

  Future<bool> saveDiary(
      String userId,
      DateTime date,
      Diary diary,
      File? imageFile,
      ) async {
    try {
      String dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      String imageUrl = diary.imageUrl;

      if (imageFile != null) {
        imageUrl = await _uploadImage(userId, dateStr, imageFile);
      }

      DatabaseReference diaryRef = _database.ref('users/$userId/diaries/$dateStr');

      await diaryRef.set({
        'diaryId': '$userId-$dateStr',
        'emotion': diary.emotion,
        'emotionColor': diary.emotionColor,
        'text': diary.text,
        'imageUrl': imageUrl,
        'timestamp': date.millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      print('일기 저장 실패: $e');
      return false;
    }
  }

  Future<Diary?> loadDiary(String userId, String date) async {
    try {
      DatabaseReference diaryRef = _database.ref('users/$userId/diaries/$date');
      DataSnapshot snapshot = await diaryRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
        return Diary.fromJson(data);
      }
      return null;
    } catch (e) {
      print('일기 불러오기 실패: $e');
      return null;
    }
  }

  Future<Map<String, Diary>> loadMonthDiaries(
      String userId,
      int year,
      int month,
      ) async {
    try {
      String startDate = '$year-${month.toString().padLeft(2, '0')}-01';
      String endDate = '$year-${month.toString().padLeft(2, '0')}-31';

      DatabaseReference diariesRef = _database.ref('users/$userId/diaries');
      Query query = diariesRef.orderByKey().startAt(startDate).endAt(endDate);

      DataSnapshot snapshot = await query.get();

      Map<String, Diary> diaries = {};
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map;
        data.forEach((key, value) {
          diaries[key] = Diary.fromJson(Map<String, dynamic>.from(value));
        });
      }

      return diaries;
    } catch (e) {
      print('월별 일기 불러오기 실패: $e');
      return {};
    }
  }

  Future<bool> deleteDiary(String userId, String date) async {
    try {
      try {
        String fileName = '${date}_img1.jpg';
        Reference storageRef = _storage.ref('diaries/$userId/$fileName');
        await storageRef.delete();
      } catch (e) {
        print('이미지 삭제 실패 (없을 수 있음): $e');
      }

      DatabaseReference diaryRef = _database.ref('users/$userId/diaries/$date');
      await diaryRef.remove();

      return true;
    } catch (e) {
      print('일기 삭제 실패: $e');
      return false;
    }
  }

  // ==================== 커플 일기 ====================

  // 커플 일기 저장 (내 엔트리만)
  Future<bool> saveCoupleDiary(
      String coupleId,
      String userId,
      DateTime date,
      String emotion,
      String emotionColor,
      String text,
      ) async {
    try {
      String dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // 내 엔트리 저장
      DatabaseReference entryRef = _database.ref('couples/$coupleId/diaries/$dateStr/entries/$userId');

      await entryRef.set({
        'emotion': emotion,
        'emotionColor': emotionColor,
        'text': text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      print('커플 일기 저장 실패: $e');
      return false;
    }
  }

  // 공통 이미지 업로드
  Future<bool> uploadSharedImage(
      String coupleId,
      String date,
      File imageFile,
      ) async {
    try {
      String imageUrl = await _uploadImage(coupleId, date, imageFile, isCouple: true);

      if (imageUrl.isEmpty) return false;

      // 공통 이미지 URL 저장
      DatabaseReference imageRef = _database.ref('couples/$coupleId/diaries/$date/sharedImage');
      await imageRef.set(imageUrl);

      return true;
    } catch (e) {
      print('공통 이미지 업로드 실패: $e');
      return false;
    }
  }

  // 커플 일기 불러오기 (한 날짜의 두 사람 엔트리 + 공통 이미지)
  Future<CoupleDiary?> loadCoupleDiary(String coupleId, String date) async {
    try {
      DatabaseReference diaryRef = _database.ref('couples/$coupleId/diaries/$date');
      DataSnapshot snapshot = await diaryRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
        return CoupleDiary.fromJson(date, data);
      }
      return null;
    } catch (e) {
      print('커플 일기 불러오기 실패: $e');
      return null;
    }
  }

  // 커플 월별 일기 목록 (달력에 표시용)
  Future<Map<String, CoupleDiary>> loadCoupleMonthDiaries(
      String coupleId,
      int year,
      int month,
      ) async {
    try {
      String startDate = '$year-${month.toString().padLeft(2, '0')}-01';
      String endDate = '$year-${month.toString().padLeft(2, '0')}-31';

      DatabaseReference diariesRef = _database.ref('couples/$coupleId/diaries');
      Query query = diariesRef.orderByKey().startAt(startDate).endAt(endDate);

      DataSnapshot snapshot = await query.get();

      Map<String, CoupleDiary> diaries = {};
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map;
        data.forEach((dateKey, value) {
          diaries[dateKey] = CoupleDiary.fromJson(
            dateKey,
            Map<String, dynamic>.from(value),
          );
        });
      }

      return diaries;
    } catch (e) {
      print('커플 월별 일기 불러오기 실패: $e');
      return {};
    }
  }

  // 내 커플 일기 엔트리만 삭제
  Future<bool> deleteMyCoupleDiaryEntry(
      String coupleId,
      String userId,
      String date,
      ) async {
    try {
      // 내 엔트리만 삭제
      DatabaseReference entryRef = _database.ref('couples/$coupleId/diaries/$date/entries/$userId');
      await entryRef.remove();

      // 엔트리가 전부 삭제되었는지 확인
      DatabaseReference diaryRef = _database.ref('couples/$coupleId/diaries/$date');
      DataSnapshot snapshot = await diaryRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);

        // entries가 비어있고 sharedImage만 남았으면 전체 삭제
        if (data['entries'] == null || (data['entries'] as Map).isEmpty) {
          // 공통 이미지도 삭제
          if (data['sharedImage'] != null && (data['sharedImage'] as String).isNotEmpty) {
            try {
              String fileName = '${date}_shared.jpg';
              Reference storageRef = _storage.ref('couples/$coupleId/$fileName');
              await storageRef.delete();
            } catch (e) {
              print('공통 이미지 삭제 실패: $e');
            }
          }

          await diaryRef.remove();
        }
      }

      return true;
    } catch (e) {
      print('커플 일기 엔트리 삭제 실패: $e');
      return false;
    }
  }

  // 공통 이미지 삭제 (둘 중 한 명이 삭제 요청)
  Future<bool> deleteSharedImage(String coupleId, String date) async {
    try {
      // Storage에서 이미지 삭제
      try {
        String fileName = '${date}_shared.jpg';
        Reference storageRef = _storage.ref('couples/$coupleId/$fileName');
        await storageRef.delete();
      } catch (e) {
        print('공통 이미지 파일 삭제 실패: $e');
      }

      // Database에서 URL 삭제
      DatabaseReference imageRef = _database.ref('couples/$coupleId/diaries/$date/sharedImage');
      await imageRef.remove();

      return true;
    } catch (e) {
      print('공통 이미지 삭제 실패: $e');
      return false;
    }
  }

  // ==================== 공통 ====================

  Future<String> _uploadImage(
      String userId,
      String date,
      File imageFile, {
        bool isCouple = false,
      }) async {
    try {
      String fileName;
      Reference storageRef;

      if (isCouple) {
        // 커플 공통 이미지
        fileName = '${date}_shared.jpg';
        storageRef = _storage.ref('couples/$userId/$fileName');
      } else {
        // 개인 이미지
        fileName = '${date}_img1.jpg';
        storageRef = _storage.ref('diaries/$userId/$fileName');
      }

      await storageRef.putFile(imageFile);
      String downloadUrl = await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('이미지 업로드 실패: $e');
      return '';
    }
  }
}