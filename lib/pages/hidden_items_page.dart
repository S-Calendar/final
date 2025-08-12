import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notice.dart';
import '../services/hidden_notice.dart'; // Firestore 기반 HiddenNotices 클래스

class HiddenItemsPage extends StatefulWidget {
  const HiddenItemsPage({super.key});

  @override
  State<HiddenItemsPage> createState() => _HiddenItemsPageState();
}

class _HiddenItemsPageState extends State<HiddenItemsPage> {
  List<Notice> hiddenItems = [];
  String? userUid;

  @override
  void initState() {
    super.initState();
    userUid = FirebaseAuth.instance.currentUser?.uid;
    _loadHiddenItemsAsync();
  }

  Future<void> _loadHiddenItemsAsync() async {
    if (userUid == null) return;
    // Firestore에서 숨김 공지 불러오기
    final hidden = await HiddenNotices.loadHidden(userUid!);
    setState(() {
      hiddenItems = hidden;
    });
  }

  Future<void> _unhideItem(Notice notice) async {
    if (userUid == null) return;
    // Firestore에서 숨김 공지 삭제(복원)
    await HiddenNotices.remove(userUid!, notice.id);
    await _loadHiddenItemsAsync();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('공지를 복원했습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('숨기기 편집'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body:
          hiddenItems.isEmpty
              ? const Center(child: Text('숨긴 공지가 없습니다.'))
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: hiddenItems.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notice = hiddenItems[index];
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(notice.title)),
                        IconButton(
                          icon: const Icon(Icons.undo, color: Colors.green),
                          onPressed: () async {
                            await _unhideItem(notice);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
