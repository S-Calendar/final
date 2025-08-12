// summary_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:scalendar_app/models/notice.dart';
import 'package:scalendar_app/services/gemini_service.dart';
import 'package:scalendar_app/services/web_scraper_service.dart';
import 'package:scalendar_app/services/hidden_notice.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/favorite_notice.dart';
import '../services/push_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SummaryPage extends StatefulWidget {
  final Notice notice;
  const SummaryPage({super.key, required this.notice});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final WebScraperService _webScraperService = WebScraperService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService = GeminiService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isLoading = true;
  Map<String, String>? _summaryResults;
  String? _errorMessage;

  bool _isFavorite = false;
  String? _userUid;

  @override
  void initState() {
    super.initState();

    // 타임존 데이터 초기화
    tz_data.initializeTimeZones();

    _userUid = FirebaseAuth.instance.currentUser?.uid;
    _initializeNotification();
    _loadMemo();
    _summarizeFromInitialUrl();
    _loadFavoriteStatus();
    _loadPushStatus(); // 푸시 상태 초기 로딩
  }

  // ===== Notification Initialization =====
  Future<void> _initializeNotification() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  // ===== 푸시 상태 초기 로딩 =====
  Future<void> _loadPushStatus() async {
    if (_userUid == null) return;
    final pushed = await PushRepository.isPushed(_userUid!, widget.notice);
    if (!mounted) return;
    setState(() {
      widget.notice.isPush = pushed;
    });
  }

  String _fmt(DateTime dt) => DateFormat('yyyy-MM-dd HH:mm').format(dt);

  // ===== Compute Schedule Time for Notification =====
  DateTime? _computeScheduleTime(DateTime startDate) {
    if (startDate.year < 2000) return null;
    final schedule = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      8,
      0,
      0,
    ).subtract(const Duration(days: 1));
    if (schedule.isBefore(DateTime.now())) return null;
    return schedule;
  }

  // ===== Schedule Push Notification (with userUid) =====
  Future<void> _scheduleNotification(Notice notice) async {
    if (_userUid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    final scheduledDate = _computeScheduleTime(notice.startDate);
    if (scheduledDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 시작일이 없거나 이미 지난 시간입니다.')),
      );
      return;
    }

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'notice_channel',
        '공지 알림',
        channelDescription: '신청 시작일 하루 전, 오전 8시에 알림',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    final id = notice.hashCode;

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        '다가오는 공지',
        notice.title,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('알림 예약 실패: $e')));
      return;
    }

    await PushRepository.upsertPush(
      userUid: _userUid!,
      notice: notice,
      scheduledAt: scheduledDate,
      notificationId: id,
      enabled: true,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('알림이 예약되었습니다. (${_fmt(scheduledDate)})')),
    );
  }

  // ===== Cancel Push Notification (with userUid) =====
  Future<void> _cancelNotification(Notice notice) async {
    if (_userUid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    final id = notice.hashCode;
    await _notificationsPlugin.cancel(id);

    await PushRepository.removePush(_userUid!, widget.notice);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('알림이 취소되었습니다.')));
  }

  // ===== Toggle Push Notification On/Off =====
  Future<void> _toggleNotificationForNotice() async {
    if (_userUid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (widget.notice.isPush) {
      await _cancelNotification(widget.notice);
      if (!mounted) return;
      setState(() {
        widget.notice.isPush = false;
        _isLoading = false;
      });
    } else {
      await _scheduleNotification(widget.notice);
      if (!mounted) return;
      final pushed = await PushRepository.isPushed(_userUid!, widget.notice);
      if (!mounted) return;
      setState(() {
        widget.notice.isPush = pushed;
        _isLoading = false;
      });
    }
  }

  // ===== Firestore 메모 로드/저장 =====
  Future<String?> _loadMemoFromFirestore(String userUid, String noticeId) async {
    try {
      final doc = await _firestore
          .collection('userMemos')
          .doc(userUid)
          .collection('memos')
          .doc(noticeId)
          .get();
      if (doc.exists) {
        return doc.data()?['memo'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _saveMemoToFirestore(
      String userUid, String noticeId, String memo) async {
    try {
      final docRef = _firestore
          .collection('userMemos')
          .doc(userUid)
          .collection('memos')
          .doc(noticeId);
      if (memo.isEmpty) {
        await docRef.delete();
      } else {
        await docRef.set({'memo': memo});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('메모 저장 실패: $e')));
    }
  }

  Future<void> _loadMemo() async {
    if (_userUid == null) return;
    final memo = await _loadMemoFromFirestore(_userUid!, widget.notice.id);
    if (!mounted) return;
    setState(() {
      widget.notice.memo = memo ?? '';
    });
  }

  Future<void> _saveMemo(String memo) async {
    if (_userUid == null) return;
    await _saveMemoToFirestore(_userUid!, widget.notice.id, memo);
    if (!mounted) return;
    setState(() {
      widget.notice.memo = memo;
    });
  }

  // ===== Summarize from Initial URL =====
  Future<void> _summarizeFromInitialUrl() async {
    try {
      final content =
          await _webScraperService.fetchAndExtractText(widget.notice.url ?? '');
      if (content == null || content.isEmpty) {
        if (!mounted) return;
        setState(() {
          _errorMessage = "웹 페이지 내용을 가져오거나 파싱하는 데 실패했습니다.";
          _isLoading = false;
        });
        return;
      }

      final summary = await _geminiService.summarizeUrlContent(content);
      if (summary == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = "요약 내용을 생성하는 데 실패했습니다.";
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _summaryResults = summary;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "오류 발생: $e";
        _isLoading = false;
      });
    }
  }

  // ===== URL launcher =====
  Future<void> _launchUrl() async {
    final rawUrl = widget.notice.url;
    if (rawUrl == null) return;
    final url = Uri.parse(rawUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("링크를 열 수 없습니다.")));
    }
  }

  // ===== Memo Edit Dialog =====
  void _showMemoDialog() {
    final TextEditingController controller =
        TextEditingController(text: widget.notice.memo ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메모 수정'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: '메모를 입력하세요'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              final memo = controller.text.trim();
              await _saveMemo(memo);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  // ===== Hide notice =====
  void _hideNotice() async {
    if (_userUid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }
    await HiddenNotices.add(_userUid!, widget.notice); // Notice 객체 전달
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('이 공지를 숨겼습니다.')));
    Navigator.pop(context);
  }

  // ===== Favorite =====
  Future<void> _loadFavoriteStatus() async {
    final userUid = _userUid;
    if (userUid == null) return;
    final isFav = await FavoriteNotices.isFavorite(userUid, widget.notice.id);
    if (!mounted) return;
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    final userUid = _userUid;
    if (userUid == null) return;

    if (_isFavorite) {
      await FavoriteNotices.removeFavorite(userUid, widget.notice.id);
    } else {
      await FavoriteNotices.addFavorite(userUid, widget.notice.id);
    }
    if (!mounted) return;
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(_isFavorite ? '관심 공지에 추가되었습니다.' : '관심 공지에서 제거되었습니다.'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ===== Build UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공지 요약'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: Colors.amber,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: Icon(
              widget.notice.isPush
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              color: widget.notice.isPush ? Colors.blue : null,
            ),
            onPressed: _toggleNotificationForNotice,
            tooltip: '푸시 알림 토글',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNoticeHeader(),
                      const SizedBox(height: 24),
                      _buildSummaryItem('참가대상', _summaryResults?["참가대상"]),
                      _buildSummaryItem('신청기간', _summaryResults?["신청기간"]),
                      _buildSummaryItem('신청방법', _summaryResults?["신청방법"]),
                      _buildSummaryItem('내용', _summaryResults?["내용"]),
                      const SizedBox(height: 16),
                      if (widget.notice.url != null)
                        GestureDetector(
                          onTap: _launchUrl,
                          child: const Text(
                            '홈페이지 바로가기',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        '메모:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if ((widget.notice.memo ?? '').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(widget.notice.memo ?? ''),
                        ),
                      const SizedBox(height: 60),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: _showMemoDialog,
                            child: const Text('수정'),
                          ),
                          const SizedBox(width: 40),
                          ElevatedButton(
                            onPressed: _hideNotice,
                            child: const Text('숨기기'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoticeHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 24,
            decoration: BoxDecoration(
              color: widget.notice.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.notice.title,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String? content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title:',
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
          ),
          const SizedBox(height: 4.0),
          Text(content ?? '정보 없음', style: const TextStyle(fontSize: 14.0)),
        ],
      ),
    );
  }
}
