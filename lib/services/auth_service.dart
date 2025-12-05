import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 구글 로그인
  Future<bool> signInWithGoogle() async {
    try {
      // Google 로그인 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // 사용자가 로그인 취소
        return false;
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Firebase 인증 자격증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      UserCredential result = await _auth.signInWithCredential(credential);
      
      return result.user != null;
    } catch (e) {
      print('구글 로그인 실패: $e');
      return false;
    }
  }

  // 익명 로그인
  Future<bool> signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      return result.user != null;
    } catch (e) {
      print('익명 로그인 실패: $e');
      return false;
    }
  }

  // 현재 사용자 ID 가져오기
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // 현재 사용자 정보 가져오기
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // 익명 사용자인지 확인
  bool isAnonymous() {
    return _auth.currentUser?.isAnonymous ?? false;
  }

  // 로그인 여부 확인
  bool isSignedIn() {
    return _auth.currentUser != null;
  }

  // 로그아웃
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
