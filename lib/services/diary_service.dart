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
        'timestamp': DateTime.now(),
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
      });

      return true;
    } catch (e) {

      print("일기 저장 실패: $e");
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
      return false;
    }
  }
  // ---- 📌 이미지 업로드 ----
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
  Future<String> _uploadImage(String userId, String date, File imageFile) async {
    try {
      String fileName = '${date}_img1.jpg';
      Reference storageRef = _storage.ref('diaries/$userId/$fileName');

      await storageRef.putFile(imageFile);
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
