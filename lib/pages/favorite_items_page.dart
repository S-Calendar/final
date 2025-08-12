import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notice.dart';
import '../services/favorite_notice.dart';
import 'package:url_launcher/url_launcher.dart';

class FavoriteItemsPage extends StatefulWidget {
  const FavoriteItemsPage({super.key});

  @override
  State<FavoriteItemsPage> createState() => _FavoriteItemsPageState();
}

class _FavoriteItemsPageState extends State<FavoriteItemsPage> {
  List<Notice> favoriteItems = [];
  String? userUid;

  @override
  void initState() {
    super.initState();
    userUid = FirebaseAuth.instance.currentUser?.uid;
    _loadFavoriteItems();
  }

  Future<void> _loadFavoriteItems() async {
    if (userUid == null) {
      // 로그인 안 됐으면 빈 리스트 처리
      if (!mounted) return;
      setState(() {
        favoriteItems = [];
      });
      return;
    }
    final favorites = await FavoriteNotices.loadFavorites(userUid!);
    if (!mounted) return;
    setState(() {
      favoriteItems = favorites;
    });
  }

  Future<void> _removeFromFavorites(Notice notice) async {
    if (userUid == null) return;
    await FavoriteNotices.removeFavorite(userUid!, notice.id!);
    if (!mounted) return;
    setState(() {
      favoriteItems.remove(notice);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('관심 공지에서 제거되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    if (userUid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('관심 공지 편집')),
        body: const Center(child: Text('로그인이 필요합니다.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('관심 공지'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body:
          favoriteItems.isEmpty
              ? const Center(child: Text('관심 공지가 없습니다.'))
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: favoriteItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notice = favoriteItems[index];
                  return GestureDetector(
                    onTap: () async {
                      if (notice.url != null && notice.url!.isNotEmpty) {
                        final url = Uri.parse(notice.url!);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('URL을 열 수 없습니다.')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('해당 공지에 연결된 URL이 없습니다.'),
                          ),
                        );
                      }
                    },
                    child: Container(
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
                            icon: const Icon(Icons.star, color: Colors.yellow),
                            onPressed: () => _removeFromFavorites(notice),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
