// lib/pages/hidden_items_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notice.dart';
import '../services/hidden_notice.dart';

class HiddenItemsPage extends StatefulWidget {
  const HiddenItemsPage({super.key});

  @override
  State<HiddenItemsPage> createState() => _HiddenItemsPageState();
}

class _HiddenItemsPageState extends State<HiddenItemsPage> {
  List<Notice> hiddenItems = [];
  String? userUid;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    userUid = FirebaseAuth.instance.currentUser?.uid;
    _loadHiddenItemsAsync();
  }

  Future<void> _loadHiddenItemsAsync() async {
    // 로그인 안 되어 있으면 로딩 종료 + 빈 목록
    if (userUid == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        hiddenItems = [];
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final hidden = await HiddenNotices.loadHidden(userUid!);
      if (!mounted) return;
      setState(() {
        hiddenItems = hidden;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('숨긴 공지 불러오기 실패: $e')),
      );
    }
  }

  Future<void> _unhideItem(Notice notice) async {
    if (userUid == null) return;
    try {
      await HiddenNotices.remove(userUid!, notice); // ← Notice 전체를 넘김
      if (!mounted) return;
      setState(() {
        hiddenItems.removeWhere((n) => n.id == notice.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('공지를 복원했습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('복원 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: const Text('숨기기 편집'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
    );

    if (_loading) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 로그인 안 된 상태 안내
    if (userUid == null) {
      return Scaffold(
        appBar: appBar,
        body: const Center(child: Text('로그인 후 이용 가능합니다.')),
      );
    }

    return Scaffold(
      appBar: appBar,
      body: RefreshIndicator(
        onRefresh: _loadHiddenItemsAsync,
        child: hiddenItems.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('숨긴 공지가 없습니다.')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: hiddenItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notice = hiddenItems[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        // 제목
                        Expanded(
                          child: Text(
                            notice.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 복원 버튼
                        IconButton(
                          icon: const Icon(Icons.undo),
                          onPressed: () => _unhideItem(notice),
                          tooltip: '복원',
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
