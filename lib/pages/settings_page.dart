// pages/settings_page.dart
import 'package:flutter/material.dart';
import 'hidden_items_page.dart';
import 'favorite_items_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'push_page.dart';

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
      {'label': '내 계정'},
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
