import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CoupleService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _generateCode() {
    const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ123456789";
    final rand = Random();
    return List.generate(9, (_) => chars[rand.nextInt(chars.length)])
        .join()
        .replaceRange(3, 3, "-")
        .replaceRange(7, 7, "-");
  }

  Future<String?> enableCoupleMode() async {
    String uid = _auth.currentUser!.uid;
    String code = _generateCode();

    await _db.collection("users").doc(uid).update({
      "coupleMode": true,
      "invitationCode": code,
    });

    return code;
  }

  Future<String?> connectPartner(String partnerCode) async {
    String myUid = _auth.currentUser!.uid;

    final query = await _db
        .collection("users")
        .where("invitationCode", isEqualTo: partnerCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return "초대 코드를 찾을 수 없습니다";

    final partnerUid = query.docs.first.id;

    if (partnerUid == myUid) return "본인 코드는 사용할 수 없습니다";

    final myData = await _db.collection("users").doc(myUid).get();
    final partnerData = await _db.collection("users").doc(partnerUid).get();

    if (myData["partnerUid"] != null || partnerData["partnerUid"] != null) {
      return "이미 연결된 사용자입니다";
    }

    await _db.collection("users").doc(myUid).update({
      "partnerUid": partnerUid,
    });

    await _db.collection("users").doc(partnerUid).update({
      "partnerUid": myUid,
    });

    return null; // 성공
  }
}
