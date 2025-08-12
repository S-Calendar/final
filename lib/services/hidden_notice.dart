// hidden_notice.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/notice.dart';

class HiddenNotices {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _userHiddenNotices(
    String userUid,
  ) => _firestore
      .collection('userHiddenNotices')
      .doc(userUid)
      .collection('hiddenNotices');

  static Future<List<Notice>> loadHidden(String userUid) async {
    final snapshot = await _userHiddenNotices(userUid).get();
    return snapshot.docs.map((doc) => _noticeFromMap(doc.data())).toList();
  }

  static Future<void> add(String userUid, Notice notice) async {
    notice.isHidden = true;
    await _userHiddenNotices(userUid).doc(notice.id).set(_noticeToMap(notice));
  }

  static Future<void> remove(String userUid, Notice notice) async {
    await _userHiddenNotices(userUid).doc(notice.id).delete();
  }

  static Future<bool> contains(String userUid, String noticeId) async {
    final doc = await _userHiddenNotices(userUid).doc(noticeId).get();
    return doc.exists;
  }

  static Map<String, dynamic> _noticeToMap(Notice n) => {
    'id': n.id,
    'title': n.title,
    'startDate': n.startDate.toIso8601String(),
    'endDate': n.endDate.toIso8601String(),
    'color': n.color.value,
    'url': n.url,
    'memo': n.memo,
    'category': n.category,
    'isHidden': true,
  };

  static Notice _noticeFromMap(Map<String, dynamic> m) => Notice(
    id: m['id'] ?? '',
    title: m['title'] ?? '',
    startDate: DateTime.parse(m['startDate']),
    endDate: DateTime.parse(m['endDate']),
    color: Color(m['color']),
    url: m['url'] ?? '',
    memo: m['memo'] ?? '',
    category: m['category'] ?? '',
    isHidden: true,
  );
}
