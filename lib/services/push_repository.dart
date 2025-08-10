// lib/services/push_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice.dart';

class PushItem {
  final Notice notice;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final bool enabled;
  final int notificationId;

  PushItem({
    required this.notice,
    required this.scheduledAt,
    required this.createdAt,
    required this.enabled,
    required this.notificationId,
  });
}

class PushRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 공지 원본 데이터 컬렉션
  static CollectionReference<Map<String, dynamic>> get _calendarEvents =>
      _firestore.collection('calendarEvents');

  // 사용자별 푸시 설정 컬렉션
  static CollectionReference<Map<String, dynamic>> _userPushes(
    String userUid,
  ) => _firestore.collection('userPushes').doc(userUid).collection('pushes');

  // 사용자별 푸시 아이템 전체 조회
  static Future<List<PushItem>> loadPushItems(String userUid) async {
    final snapshot = await _userPushes(userUid).get();

    List<PushItem> results = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      // enabled 가 true 인 것만 처리
      final enabled = (data['enabled'] ?? false) == true;
      if (!enabled) continue; // false면 건너뛰기

      final noticeId = data['noticeId'] as String?;
      if (noticeId == null) continue;

      final noticeDoc = await _calendarEvents.doc(noticeId).get();
      if (!noticeDoc.exists) continue;
      final noticeData = noticeDoc.data()!;
      noticeData['id'] = noticeDoc.id;
      final notice = Notice.fromJson(noticeData, id: noticeDoc.id);

      final scheduledAt =
          (data['pushScheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final createdAt =
          (data['pushCreatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final notificationId = (data['notificationId'] ?? notice.hashCode) as int;

      results.add(
        PushItem(
          notice: notice,
          scheduledAt: scheduledAt,
          createdAt: createdAt,
          enabled: enabled,
          notificationId: notificationId,
        ),
      );
    }

    return results;
  }

  // 푸시 등록 또는 업데이트 (개인화)
  static Future<void> upsertPush({
    required String userUid,
    required Notice notice,
    required DateTime scheduledAt,
    required int notificationId,
    bool enabled = true,
  }) async {
    final docId = _docId(notice);
    await _userPushes(userUid).doc(docId).set({
      'noticeId': notice.id,
      'enabled': enabled,
      'pushScheduledAt': Timestamp.fromDate(scheduledAt),
      'pushCreatedAt': FieldValue.serverTimestamp(),
      'notificationId': notificationId,
    }, SetOptions(merge: true));
  }

  // 푸시 활성화 상태 변경 (개인화)
  static Future<void> setEnabled(
    String userUid,
    Notice notice,
    bool enabled,
  ) async {
    final docId = _docId(notice);
    await _userPushes(
      userUid,
    ).doc(docId).set({'enabled': enabled}, SetOptions(merge: true));
  }

  // 푸시 제거 (비활성화, 개인화)
  static Future<void> removePush(String userUid, Notice notice) async {
    await setEnabled(userUid, notice, false);
  }

  // 푸시 활성화 여부 확인 (개인화)
  static Future<bool> isPushed(String userUid, Notice notice) async {
    final doc = await _userPushes(userUid).doc(_docId(notice)).get();
    return (doc.data()?['enabled'] ?? false) == true;
  }

  // 문서 ID 생성 (공지 식별용)
  static String _docId(Notice notice) {
    final safeTitle =
        notice.title.replaceAll(RegExp(r'[^\w]+'), '-').toLowerCase();
    final safeDate = notice.startDate.toIso8601String().replaceAll(':', '');
    return '${safeTitle}_$safeDate';
  }
}
