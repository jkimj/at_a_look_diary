import 'dart:io';
<<<<<<< HEAD
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/diary.dart';

class DiaryService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 일기 저장
  Future<bool> saveDiary(
      String userId,
      DateTime date,
      Diary diary,
      File? imageFile,
      ) async {
    try {
      String dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      String imageUrl = diary.imageUrl; // 기존 이미지 URL

      // 새 이미지가 있으면 업로드
=======
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/diary.dart';

class DiaryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  // ---- 📌 일기 저장 (Firestore 반영 + Storage 이미지 업로드) ----
  Future<bool> saveDiary(String userId, DateTime date, Diary diary, File? imageFile) async {
    try {
      String dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      String imageUrl = diary.imageUrl;

>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
      if (imageFile != null) {
        imageUrl = await _uploadImage(userId, dateStr, imageFile);
      }

<<<<<<< HEAD
      // 일기 데이터 저장
      DatabaseReference diaryRef = _database.ref('users/$userId/diaries/$dateStr');

      await diaryRef.set({
        'diaryId': '$userId-$dateStr',
=======
      await _db
          .collection("diaries")
          .doc(userId)
          .collection("items")
          .doc(dateStr)
          .set({
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
        'emotion': diary.emotion,
        'emotionColor': diary.emotionColor,
        'text': diary.text,
        'imageUrl': imageUrl,
<<<<<<< HEAD
        'timestamp': date.millisecondsSinceEpoch,
=======
        'timestamp': DateTime.now(),
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
      });

      return true;
    } catch (e) {
<<<<<<< HEAD
      print('일기 저장 실패: $e');
=======
      print("일기 저장 실패: $e");
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
      return false;
    }
  }

<<<<<<< HEAD
  // 이미지 업로드
=======
  // ---- 📌 이미지 업로드 ----
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
  Future<String> _uploadImage(String userId, String date, File imageFile) async {
    try {
      String fileName = '${date}_img1.jpg';
      Reference storageRef = _storage.ref('diaries/$userId/$fileName');

      await storageRef.putFile(imageFile);
<<<<<<< HEAD
      String downloadUrl = await storageRef.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('이미지 업로드 실패: $e');
      return '';
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
=======
      return await storageRef.getDownloadURL();
    } catch (e) {
      print("이미지 업로드 실패: $e");
      return "";
    }
  }

  // ---- 📌 특정 날짜 일기 불러오기 ----
  Future<Diary?> loadDiary(String userId, String date) async {
    try {
      final doc = await _db
          .collection("diaries")
          .doc(userId)
          .collection("items")
          .doc(date)
          .get();

      if (!doc.exists) return null;
      return Diary.fromJson(doc.data()!);
    } catch (e) {
      print("일기 불러오기 실패: $e");
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
      return null;
    }
  }

<<<<<<< HEAD
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
      // 이미지 삭제 (있는 경우)
      try {
        String fileName = '${date}_img1.jpg';
        Reference storageRef = _storage.ref('diaries/$userId/$fileName');
        await storageRef.delete();
      } catch (e) {
        print('이미지 삭제 실패 (없을 수 있음): $e');
      }

      // 데이터베이스에서 일기 삭제
      DatabaseReference diaryRef = _database.ref('users/$userId/diaries/$date');
      await diaryRef.remove();

      return true;
    } catch (e) {
      print('일기 삭제 실패: $e');
      return false;
    }
  }
}
=======
  // ---- 📌 월별 일기 불러오기 ----
  Future<Map<String, Diary>> loadMonthDiaries(String userId, int year, int month) async {
    try {
      String prefix = '$year-${month.toString().padLeft(2, '0')}';

      final query = await _db
          .collection("diaries")
          .doc(userId)
          .collection("items")
          .get();

      Map<String, Diary> diaries = {};
      for (var item in query.docs) {
        if (item.id.startsWith(prefix)) {
          diaries[item.id] = Diary.fromJson(item.data());
        }
      }
      return diaries;
    } catch (e) {
      print("월별 일기 불러오기 실패: $e");
      return {};
    }
  }
}
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
