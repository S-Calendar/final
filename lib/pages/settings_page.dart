// pages/settings_page.dart
import 'package:flutter/material.dart';
import 'hidden_items_page.dart';
import 'favorite_items_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'push_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_page.dart'; // 로그인 페이지 import

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: android);
    await _notificationsPlugin.initialize(init);
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> settingsItems = [
      {
        'label': '년간 일정 보기',
        'onTap': () {
          Navigator.pushNamed(context, '/year_page');
        },
      },
      {
        'label': '월간 일정 보기',
        'onTap': () {
          Navigator.pushNamed(context, '/main_page');
        },
      },
      {
        'label': '숨기기 편집',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HiddenItemsPage()),
          );
        },
      },
      {
        'label': '관심 공지 편집',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoriteItemsPage()),
          );
        },
      },
      {
        'label': '푸시 알림 편집',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PushPage(notifications: _notificationsPlugin),
            ),
          );
        },
      },
      {
        'label': '로그아웃',
        'onTap': () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('로그아웃 확인'),
                content: const Text('정말 로그아웃 하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('아니오'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('예'),
                  ),
                ],
              );
            },
          );

          // '예'를 누른 경우만 로그아웃 진행
          if (shouldLogout == true) {
            try {
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
            } catch (e) {
              debugPrint('로그아웃 중 오류: $e');
            }

            if (!mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        },
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          '설정',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: settingsItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = settingsItems[index];
          return GestureDetector(
            onTap: item['onTap'],
            child: Container(
              height: 40,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item['label'],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
