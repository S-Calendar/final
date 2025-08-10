//notice_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/notice.dart';

class NoticeData {
  static Future<List<Notice>> loadNoticesFromFirestore() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('calendarEvents').get();
    List<Notice> all = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      try {
        final start = DateTime.parse(data['startDate']);
        final end = DateTime.parse(data['endDate']);

        Color color;
        switch (data['category']) {
          case '학사공지':
            color = const Color(0x83ABC9FF);
            break;
          case 'ai학과공지':
            color = const Color(0x83FFABAB);
            break;
          case '취업공지':
            color = const Color(0x83A5FAA5);
            break;
          default:
            color = const Color.fromARGB(131, 171, 200, 255);
        }

        all.add(
          Notice(
            id: doc.id,
            title: data['title'] ?? '제목 없음',
            startDate: start,
            endDate: end,
            color: color,
            url: data['url'],
            writer: data['writer'],
            isFavorite: data['isFavorite'] ?? false,
            isHidden: data['isHidden'] ?? false,
            memo: data['memo'],
            category: data['category'] ?? '',
          ),
        );
      } catch (e) {
        continue;
      }
    }

    return all;
  }
}
