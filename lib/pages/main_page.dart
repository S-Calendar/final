// main_page.dart
import 'package:flutter/material.dart';
import '../widgets/custom_calendar.dart';
import '../models/notice.dart';
import '../services/notice_data.dart';
import '../widgets/category_filter_dialog.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final int baseYear = 2024;
  late PageController _pageController;
  late int _selectedIndex;
  late int _todayIndex;
  late List<Notice> allNotices = [];
  bool _initializedWithArgs = false;

  List<String> selectedCategories = ['ai학과공지', '학사공지', '취업공지'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, int>?;

    final today = DateTime.now();
    int initYear = today.year;
    int initMonth = today.month;

    if (args != null) {
      if (args.containsKey('year') && args.containsKey('month')) {
        initYear = args['year']!;
        initMonth = args['month']!;
      }
    }

    _todayIndex = (today.year - baseYear) * 12 + (today.month - 1);
    final newIndex = (initYear - baseYear) * 12 + (initMonth - 1);

    if (!_initializedWithArgs || _selectedIndex != newIndex) {
      _selectedIndex = newIndex;
      _pageController = PageController(initialPage: _selectedIndex);
      _initializedWithArgs = true;
      _loadNotices();
    }
  }

  Future<void> _loadNotices() async {
    final notices = await NoticeData.loadNoticesFromFirestore();
    setState(() {
      allNotices = notices.where((n) => !n.isHidden).toList();
    });
  }

  Future<void> _navigateAndRefresh(String routeName) async {
    await Navigator.pushNamed(context, routeName);
    await _loadNotices();
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => CategoryFilterDialog(
        selectedCategories: selectedCategories,
        onApply: (newCategories) {
          setState(() {
            selectedCategories = newCategories;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int year = baseYear + (_selectedIndex ~/ 12);
    final int month = (_selectedIndex % 12) + 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 25, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _navigateAndRefresh('/settings'),
                    child: Image.asset('assets/setting_icon.png', width: 32),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = _todayIndex;
                        _pageController.jumpToPage(_todayIndex);
                      });
                    },
                    child: Image.asset('assets/today_icon.png', width: 70),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$month월',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _navigateAndRefresh('/search'),
                    child: Image.asset('assets/search_icon.png', width: 30),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _showCategoryDialog,
                    child: Image.asset(
                      'assets/colorfilter_icon.png',
                      width: 44,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final year = baseYear + (index ~/ 12);
                  final month = (index % 12) + 1;
                  final currentMonth = DateTime(year, month);

                  final filteredNotices = allNotices
                      .where((n) => selectedCategories.contains(n.category))
                      .toList();

                  return CustomCalendar(
                    month: currentMonth,
                    notices: filteredNotices,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
