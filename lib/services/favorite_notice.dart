import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice.dart';

class FavoriteNotices {
  static final _firestore = FirebaseFirestore.instance;
  static final _calendarEvents = _firestore.collection('calendarEvents');
  static final _userFavorites = _firestore.collection('userFavorites');

  static Future<bool> isFavorite(String userUid, String eventId) async {
    final doc = await _userFavorites.doc(userUid).get();
    if (!doc.exists) return false;

    final favIds = List<String>.from(doc.data()?['favorites'] ?? []);
    return favIds.contains(eventId);
  }

  static Future<List<Notice>> loadFavorites(String userUid) async {
    final favDoc = await _userFavorites.doc(userUid).get();
    if (!favDoc.exists) return [];

    final favIds = List<String>.from(favDoc.data()?['favorites'] ?? []);
    if (favIds.isEmpty) return [];

    // Firestore whereIn 최대 30개 제한 → 여러 번 병렬 호출
    final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
    for (var i = 0; i < favIds.length; i += 30) {
      final chunk = favIds.skip(i).take(30).toList();
      futures.add(
        _calendarEvents.where(FieldPath.documentId, whereIn: chunk).get(),
      );
    }

    final snapshots = await Future.wait(futures);
    return snapshots.expand((qs) {
      return qs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Notice.fromJson(data, id: doc.id);
      });
    }).toList();
  }

  static Future<void> addFavorite(String userUid, String eventId) async {
    await _userFavorites.doc(userUid).set({
      'favorites': FieldValue.arrayUnion([eventId]),
    }, SetOptions(merge: true));
  }

  static Future<void> removeFavorite(String userUid, String eventId) async {
    await _userFavorites.doc(userUid).set({
      'favorites': FieldValue.arrayRemove([eventId]),
    }, SetOptions(merge: true));
  }

  static Future<void> toggleFavorite(String userUid, String eventId) async {
    final favDoc = await _userFavorites.doc(userUid).get();
    final favIds = List<String>.from(favDoc.data()?['favorites'] ?? []);
    if (favIds.contains(eventId)) {
      await removeFavorite(userUid, eventId);
    } else {
      await addFavorite(userUid, eventId);
    }
  }
}
