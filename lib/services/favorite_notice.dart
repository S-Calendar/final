import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notice.dart';

class FavoriteNotices {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _calendarEvents =>
      _firestore.collection('calendarEvents');

  static CollectionReference<Map<String, dynamic>> get _userFavorites =>
      _firestore.collection('userFavorites');

  // 유저별 즐겨찾기 공지 목록 불러오기
  static Future<List<Notice>> loadFavorites(String userUid) async {
    final favDoc = await _userFavorites.doc(userUid).get();
    if (!favDoc.exists) return [];

    final favIds = List<String>.from(favDoc.data()?['favorites'] ?? []);
    if (favIds.isEmpty) return [];

    final querySnapshot =
        await _calendarEvents
            .where(FieldPath.documentId, whereIn: favIds)
            .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Notice.fromJson(data, id: doc.id);
    }).toList();
  }

  // 유저의 특정 공지가 즐겨찾기인지 확인
  static Future<bool> isFavorite(String userUid, String eventId) async {
    final favDoc = await _userFavorites.doc(userUid).get();
    if (!favDoc.exists) return false;

    final favIds = List<String>.from(favDoc.data()?['favorites'] ?? []);
    return favIds.contains(eventId);
  }

  // 즐겨찾기 추가
  static Future<void> addFavorite(String userUid, String eventId) async {
    final docRef = _userFavorites.doc(userUid);
    await docRef.set({
      'favorites': FieldValue.arrayUnion([eventId]),
    }, SetOptions(merge: true));
  }

  // 즐겨찾기 제거
  static Future<void> removeFavorite(String userUid, String eventId) async {
    final docRef = _userFavorites.doc(userUid);
    await docRef.set({
      'favorites': FieldValue.arrayRemove([eventId]),
    }, SetOptions(merge: true));
  }

  // 즐겨찾기 토글 (있으면 제거, 없으면 추가)
  static Future<void> toggleFavorite(String userUid, String eventId) async {
    final isFav = await isFavorite(userUid, eventId);
    if (isFav) {
      await removeFavorite(userUid, eventId);
    } else {
      await addFavorite(userUid, eventId);
    }
  }
}
