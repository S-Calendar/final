import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/push_repository.dart';

class PushPage extends StatefulWidget {
  final FlutterLocalNotificationsPlugin notifications;
  const PushPage({super.key, required this.notifications});

  @override
  State<PushPage> createState() => _PushPageState();
}

class _PushPageState extends State<PushPage> {
  List<PushItem> items = [];
  String? userUid;

  @override
  void initState() {
    super.initState();
    userUid = FirebaseAuth.instance.currentUser?.uid;
    _load();
  }

  Future<void> _load() async {
    if (userUid == null) return; // 사용자 로그인 안 된 경우 무시
    final list = await PushRepository.loadPushItems(userUid!);
    if (!mounted) return;
    setState(() {
      items = List.of(list)
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    });
  }

  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm').format(dt);

  Future<void> _toggle(PushItem item, bool value) async {
    if (userUid == null) return;

    if (value) {
      // 재예약
      await widget.notifications.zonedSchedule(
        item.notificationId,
        '다가오는 공지',
        item.notice.title,
        tz.TZDateTime.from(item.scheduledAt, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails('notice_channel', '공지 알림'),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      await PushRepository.setEnabled(userUid!, item.notice, true);
    } else {
      await widget.notifications.cancel(item.notificationId);
      await PushRepository.setEnabled(userUid!, item.notice, false);
    }
    await _load();
  }

  Future<void> _delete(PushItem item) async {
    if (userUid == null) return;
    await widget.notifications.cancel(item.notificationId);
    await PushRepository.removePush(userUid!, item.notice);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('알림이 취소되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('푸시 알림 편집')),
      body:
          items.isEmpty
              ? const Center(child: Text('예약된 알림이 없습니다.'))
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final e = items[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final urlStr = e.notice.url;
                              if (urlStr == null || urlStr.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('해당 공지에 연결된 URL이 없습니다.'),
                                  ),
                                );
                                return;
                              }
                              final url = Uri.parse(urlStr);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('URL을 열 수 없습니다.'),
                                  ),
                                );
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.notice.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '예약 시각: ${_fmt(e.scheduledAt)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_active),
                          onPressed: () => _delete(e),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
