import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

class CoupleService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // 랜덤 커플 코드 생성 (예: A2B9-77LQ)
  String generateCoupleCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 혼동되는 문자 제외 (I,O,0,1)
    final random = Random();
    final part1 = List.generate(4, (index) => chars[random.nextInt(chars.length)]).join();
    final part2 = List.generate(4, (index) => chars[random.nextInt(chars.length)]).join();
    return '$part1-$part2';
  }

  // 커플 코드 생성 및 저장
  Future<String> createCoupleCode(String userId) async {
    try {
      // 이미 커플이 있는지 확인
      final existingCoupleId = await getCoupleId(userId);
      if (existingCoupleId != null) {
        throw Exception('이미 연결된 파트너가 있습니다');
      }

      // 새 코드 생성
      String code = generateCoupleCode();

      // 코드 중복 확인 (중복이면 재생성)
      while (await _isCodeExists(code)) {
        code = generateCoupleCode();
      }

      // 코드 저장 (24시간 유효)
      await _database.ref('coupleCodes/$code').set({
        'userId': userId,
        'createdAt': ServerValue.timestamp,
        'expiresAt': DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
      });

      return code;
    } catch (e) {
      print('커플 코드 생성 실패: $e');
      rethrow;
    }
  }

  // 코드 존재 확인
  Future<bool> _isCodeExists(String code) async {
    final snapshot = await _database.ref('coupleCodes/$code').get();
    return snapshot.exists;
  }

  // 커플 코드로 매칭
  Future<bool> connectWithCode(String currentUserId, String code) async {
    try {
      // 본인 코드로 연결 시도하는지 확인
      final codeSnapshot = await _database.ref('coupleCodes/$code').get();

      if (!codeSnapshot.exists) {
        throw Exception('유효하지 않은 코드입니다');
      }

      final codeData = Map<String, dynamic>.from(codeSnapshot.value as Map);
      final partnerUserId = codeData['userId'] as String;

      // 본인 코드로 연결 시도
      if (partnerUserId == currentUserId) {
        throw Exception('본인의 코드로는 연결할 수 없습니다');
      }

      // 코드 만료 확인
      final expiresAt = codeData['expiresAt'] as int;
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        await _database.ref('coupleCodes/$code').remove();
        throw Exception('만료된 코드입니다');
      }

      // 이미 커플이 있는지 확인
      final currentUserCoupleId = await getCoupleId(currentUserId);
      final partnerCoupleId = await getCoupleId(partnerUserId);

      if (currentUserCoupleId != null) {
        throw Exception('이미 연결된 파트너가 있습니다');
      }

      if (partnerCoupleId != null) {
        throw Exception('상대방이 이미 다른 파트너와 연결되어 있습니다');
      }

      // 새 커플 생성
      final coupleId = '${partnerUserId}_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}';

      await _database.ref('couples/$coupleId').set({
        'user1': partnerUserId,
        'user2': currentUserId,
        'createdAt': ServerValue.timestamp,
        'status': 'connected',
      });

      // 사용자들에게 커플 ID 저장
      await _database.ref('users/$partnerUserId/coupleId').set(coupleId);
      await _database.ref('users/$currentUserId/coupleId').set(coupleId);

      // 사용된 코드 삭제
      await _database.ref('coupleCodes/$code').remove();

      return true;
    } catch (e) {
      print('커플 연결 실패: $e');
      rethrow;
    }
  }

  // 현재 사용자의 커플 ID 가져오기
  Future<String?> getCoupleId(String userId) async {
    try {
      final snapshot = await _database.ref('users/$userId/coupleId').get();
      if (snapshot.exists) {
        return snapshot.value as String;
      }
      return null;
    } catch (e) {
      print('커플 ID 가져오기 실패: $e');
      return null;
    }
  }

  // 파트너 정보 가져오기
  Future<String?> getPartnerId(String userId) async {
    try {
      final coupleId = await getCoupleId(userId);
      if (coupleId == null) return null;

      final snapshot = await _database.ref('couples/$coupleId').get();
      if (!snapshot.exists) return null;

      final coupleData = Map<String, dynamic>.from(snapshot.value as Map);
      final user1 = coupleData['user1'] as String;
      final user2 = coupleData['user2'] as String;

      return user1 == userId ? user2 : user1;
    } catch (e) {
      print('파트너 ID 가져오기 실패: $e');
      return null;
    }
  }

  // 커플 연결 해제
  Future<bool> disconnectCouple(String userId) async {
    try {
      final coupleId = await getCoupleId(userId);
      if (coupleId == null) {
        throw Exception('연결된 파트너가 없습니다');
      }

      final snapshot = await _database.ref('couples/$coupleId').get();
      if (!snapshot.exists) {
        throw Exception('커플 정보를 찾을 수 없습니다');
      }

      final coupleData = Map<String, dynamic>.from(snapshot.value as Map);
      final user1 = coupleData['user1'] as String;
      final user2 = coupleData['user2'] as String;

      // 커플 데이터 삭제
      await _database.ref('couples/$coupleId').remove();

      // 사용자들의 커플 ID 삭제
      await _database.ref('users/$user1/coupleId').remove();
      await _database.ref('users/$user2/coupleId').remove();

      return true;
    } catch (e) {
      print('커플 연결 해제 실패: $e');
      rethrow;
    }
  }

  // 커플 상태 확인
  Future<bool> isCoupleConnected(String userId) async {
    final coupleId = await getCoupleId(userId);
    return coupleId != null;
  }

  // 만료된 코드 정리 (앱 시작 시 호출)
  Future<void> cleanupExpiredCodes() async {
    try {
      final snapshot = await _database.ref('coupleCodes').get();
      if (!snapshot.exists) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      final codes = Map<String, dynamic>.from(snapshot.value as Map);

      for (var entry in codes.entries) {
        final codeData = Map<String, dynamic>.from(entry.value as Map);
        final expiresAt = codeData['expiresAt'] as int;

        if (now > expiresAt) {
          await _database.ref('coupleCodes/${entry.key}').remove();
        }
      }
    } catch (e) {
      print('만료된 코드 정리 실패: $e');
    }
  }
}