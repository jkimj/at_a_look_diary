import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 Firestore에 사용자 문서 생성 (없으면 새로 만들기)
  Future<void> _createUserDocIfNotExists(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        "uid": user.uid,
        "email": user.email ?? "",
        "displayName": user.displayName ?? "사용자",
        "profileImage": user.photoURL ?? "",
        "isAnonymous": user.isAnonymous,
        "coupleMode": false,      // 커플 모드 기본 OFF
        "coupleCode": null,       // 초대 코드
        "partnerUid": null,       // 상대 UID
        "coupleId": null,         // 필요하면 커플 고유 ID
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }

  // ✅ 구글 로그인
  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 로그인 창만 열고 취소한 경우
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result =
      await _auth.signInWithCredential(credential);

      final user = result.user;
      if (user == null) return false;

      // 🔥 Firestore 유저 문서 생성 / 갱신
      await _createUserDocIfNotExists(user);
      return true;
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
    } catch (e) {
      print('구글 로그인 실패: $e');
      return false;
    }
  }
  // ✅ 익명 로그인
  Future<bool> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      final user = result.user;
      if (user == null) return false;

      // 🔥 Firestore 유저 문서 생성 / 갱신
      await _createUserDocIfNotExists(user);
      return true;
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
    } catch (e) {
      print('익명 로그인 실패: $e');
      return false;
    }
  }

  // ✅ 현재 사용자 ID 가져오기
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // ✅ 현재 사용자 정보 가져오기
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ✅ 익명 사용자인지 확인
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
  bool isAnonymous() {
    return _auth.currentUser?.isAnonymous ?? false;
  }

  // ✅ 로그인 여부 확인
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
  bool isSignedIn() {
    return _auth.currentUser != null;
  }

  // ✅ 로그아웃
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // 구글 계정 안 붙어있을 수도 있어서 무시해도 됨
    }
>>>>>>> abbc0af (Refactor: Firestore user mode & couple base setup)
    await _auth.signOut();
  }
}
