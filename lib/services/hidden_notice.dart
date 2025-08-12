import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice.dart';

class HiddenNotices {
  static final _firestore = FirebaseFirestore.instance;
  static final _calendarEvents = _firestore.collection('calendarEvents');
  static final _userHidden = _firestore.collection('userHiddenNotices');

  static Future<List<Notice>> loadHidden(String userUid) async {
    final hiddenDoc = await _userHidden.doc(userUid).get();
    if (!hiddenDoc.exists) return [];

    final hiddenIds = List<String>.from(hiddenDoc.data()?['hidden'] ?? []);
    if (hiddenIds.isEmpty) return [];

    final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    for (var i = 0; i < hiddenIds.length; i += 30) {
      final chunk = hiddenIds.skip(i).take(30).toList();
      futures.add(
        _calendarEvents.where(FieldPath.documentId, whereIn: chunk).get(),
      );
    }

    final snapshots = await Future.wait(futures);
    return snapshots.expand((qs) {
      return qs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Notice.fromJson(data, id: doc.id)..isHidden = true;
      });
    }).toList();
  }

  static Future<void> add(String userUid, String noticeId) async {
    await _userHidden.doc(userUid).set({
      'hidden': FieldValue.arrayUnion([noticeId]),
    }, SetOptions(merge: true));
  }

  static Future<void> remove(String userUid, String noticeId) async {
    await _userHidden.doc(userUid).set({
      'hidden': FieldValue.arrayRemove([noticeId]),
    }, SetOptions(merge: true));
  }

  static Future<bool> contains(String userUid, String noticeId) async {
    final doc = await _userHidden.doc(userUid).get();
    final ids = List<String>.from(doc.data()?['hidden'] ?? []);
    return ids.contains(noticeId);
  }
}
