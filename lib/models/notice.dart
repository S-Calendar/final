import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id; // Firestore 문서 ID (필수)
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final Color color;
  final String? url;
  final String? writer;
  final String category;

  bool isFavorite;
  bool isHidden;
  String? memo;
  bool isPush;

  Notice({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.color,
    required this.category,
    this.url,
    this.writer,
    this.isFavorite = false,
    this.isHidden = false,
    this.memo,
    this.isPush = false,
  });

  // Firestore Timestamp 또는 String을 DateTime으로 변환하는 헬퍼
  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  // fromJson에서 id는 필수로 받도록 수정
  factory Notice.fromJson(Map<String, dynamic> json, {required String id}) {
    return Notice(
      id: id,
      title: json['title'] ?? '',
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      color: Color(json['color'] ?? 0xFF000000),
      category: json['category'] ?? '',
      url: json['url'],
      writer: json['writer'],
      isFavorite: json['isFavorite'] ?? false,
      isHidden: json['isHidden'] ?? false,
      memo: json['memo'],
      isPush: json['isPush'] ?? false,
    );
  }

  // toJson에는 id를 포함하지 않음 (Firestore 문서 ID로 별도 관리)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'color': color.value,
      'category': category,
      'url': url,
      'writer': writer,
      'isFavorite': isFavorite,
      'isHidden': isHidden,
      'memo': memo,
      'isPush': isPush,
    };
  }

  @override
  bool operator ==(Object other) => other is Notice && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// 기존 Notice 클래스 끝난 뒤에 추가

extension NoticeExtension on Notice {
  /// 주어진 날짜가 공지 기간(startDate ~ endDate)에 포함되는지 확인
  bool includes(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return dateOnly.isAtSameMomentAs(start) ||
        dateOnly.isAtSameMomentAs(end) ||
        (dateOnly.isAfter(start) && dateOnly.isBefore(end));
  }

  /// 공지 기간 일수 반환 (종료일 - 시작일)
  int get duration {
    return endDate.difference(startDate).inDays;
  }
}
