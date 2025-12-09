import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/diary.dart';

class DiaryService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ==================== 개인 일기 ====================

  // 일기 저장
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

  // 특정 날짜 일기 불러오기
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

  // 월별 일기 목록 불러오기
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

  // 일기 삭제
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

  // 커플 일기 저장
  Future<bool> saveCoupleDiary(
      String coupleId,
      String userId,
      DateTime date,
      Diary diary,
      File? imageFile,
      ) async {
    try {
      String dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      String imageUrl = diary.imageUrl;

      if (imageFile != null) {
        imageUrl = await _uploadImage(userId, dateStr, imageFile, isCouple: true);
      }

      // 커플 스페이스에 저장
      DatabaseReference diaryRef = _database.ref('couples/$coupleId/diaries/$dateStr');

      await diaryRef.set({
        'diaryId': '$userId-$dateStr',
        'userId': userId, // 누가 작성했는지
        'emotion': diary.emotion,
        'emotionColor': diary.emotionColor,
        'text': diary.text,
        'imageUrl': imageUrl,
        'timestamp': date.millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      print('커플 일기 저장 실패: $e');
      return false;
    }
  }

  // 커플 일기 불러오기 (특정 날짜)
  Future<Diary?> loadCoupleDiary(String coupleId, String date) async {
    try {
      DatabaseReference diaryRef = _database.ref('couples/$coupleId/diaries/$date');
      DataSnapshot snapshot = await diaryRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
        return Diary.fromJson(data);
      }
      return null;
    } catch (e) {
      print('커플 일기 불러오기 실패: $e');
      return null;
    }
  }

  // 커플 월별 일기 목록 (두 사람 모두)
  Future<Map<String, Diary>> loadCoupleMonthDiaries(
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

      Map<String, Diary> diaries = {};
      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map;
        data.forEach((key, value) {
          diaries[key] = Diary.fromJson(Map<String, dynamic>.from(value));
        });
      }

      return diaries;
    } catch (e) {
      print('커플 월별 일기 불러오기 실패: $e');
      return {};
    }
  }

  // 커플 일기 삭제
  Future<bool> deleteCoupleDiary(String coupleId, String userId, String date) async {
    try {
      // 작성자 확인
      DatabaseReference diaryRef = _database.ref('couples/$coupleId/diaries/$date');
      DataSnapshot snapshot = await diaryRef.get();

      if (snapshot.exists) {
        Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
        String authorId = data['userId'] ?? '';

        // 본인이 쓴 일기만 삭제 가능
        if (authorId != userId) {
          throw Exception('본인이 작성한 일기만 삭제할 수 있습니다');
        }
      }

      // 이미지 삭제
      try {
        String fileName = '${date}_img1.jpg';
        Reference storageRef = _storage.ref('couples/$coupleId/$fileName');
        await storageRef.delete();
      } catch (e) {
        print('이미지 삭제 실패 (없을 수 있음): $e');
      }

      await diaryRef.remove();
      return true;
    } catch (e) {
      print('커플 일기 삭제 실패: $e');
      return false;
    }
  }

  // ==================== 공통 ====================

  // 이미지 업로드
  Future<String> _uploadImage(
      String userId,
      String date,
      File imageFile, {
        bool isCouple = false,
      }) async {
    try {
      String fileName = '${date}_img1.jpg';
      Reference storageRef;

      if (isCouple) {
        // 커플 이미지는 couples 폴더에
        storageRef = _storage.ref('couples/$userId/$fileName');
      } else {
        // 개인 이미지는 diaries 폴더에
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