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

  // 사용자별 푸시 설정 컬렉션 (userPushes/{userUid}/pushes)
  static CollectionReference<Map<String, dynamic>> _userPushes(
    String userUid,
  ) => _firestore.collection('userPushes').doc(userUid).collection('pushes');

  // 사용자별 활성화된 푸시 아이템 전체 조회 (병렬 로딩)
  static Future<List<PushItem>> loadPushItems(String userUid) async {
    final snapshot = await _userPushes(userUid).get();

    // enabled == true인 문서만 필터링
    final enabledDocs =
        snapshot.docs
            .where((d) => (d.data()['enabled'] ?? false) == true)
            .toList();

    if (enabledDocs.isEmpty) return [];

    // noticeId 리스트 추출
    final noticeIds =
        enabledDocs.map((d) => d.data()['noticeId'] as String).toList();

    // Firestore whereIn 조건은 최대 30개 제한 -> 30개씩 나누어 병렬 조회
    final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    for (var i = 0; i < noticeIds.length; i += 30) {
      final chunk = noticeIds.skip(i).take(30).toList();
      futures.add(
        _calendarEvents.where(FieldPath.documentId, whereIn: chunk).get(),
      );
    }

    // 병렬로 데이터 조회 후 합치기
    final snapshots = await Future.wait(futures);
    final noticeMap = {
      for (var doc in snapshots.expand((qs) => qs.docs))
        doc.id: Notice.fromJson(doc.data(), id: doc.id),
    };

    // PushItem 리스트 생성
    return enabledDocs.map((doc) {
      final data = doc.data();
      final notice = noticeMap[data['noticeId']]!;
      return PushItem(
        notice: notice,
        scheduledAt: (data['pushScheduledAt'] as Timestamp).toDate(),
        createdAt:
            (data['pushCreatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        enabled: true,
        notificationId: data['notificationId'] as int,
      );
    }).toList();
  }

  // 푸시 등록 또는 업데이트
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

  // 푸시 활성화 상태 변경
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

  // 푸시 제거 (비활성화)
  static Future<void> removePush(String userUid, Notice notice) async {
    await setEnabled(userUid, notice, false);
  }

  // 푸시 활성화 여부 확인
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
