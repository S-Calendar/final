// main_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  PageController? _pageController; // nullable
  int? _selectedIndex; // nullable
  int? _todayIndex; // nullable
  List<Notice> allNotices = [];
  bool _initialized = false;

  List<String> selectedCategories = ['ai학과공지', '학사공지', '취업공지'];

  @override
  void initState() {
    super.initState();
    _loadSelectedCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, int>?;

        final today = DateTime.now();

        int initYear = today.year;
        int initMonth = today.month;

        if (args != null &&
            args.containsKey('year') &&
            args.containsKey('month')) {
          initYear = args['year']!;
          initMonth = args['month']!;
        }

        _todayIndex = (today.year - baseYear) * 12 + (today.month - 1);
        _selectedIndex = (initYear - baseYear) * 12 + (initMonth - 1);

        _pageController = PageController(initialPage: _selectedIndex!);

        await _loadNotices();

        if (mounted) setState(() {});
      });
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadNotices() async {
    if (!mounted) return;
    final notices = await NoticeData.loadNoticesFromFirestore();
    if (!mounted) return;
    allNotices = notices.where((n) => !n.isHidden).toList();
  }

  Future<void> _loadSelectedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final savedCategories = prefs.getStringList('selectedCategories');
    if (savedCategories != null && savedCategories.isNotEmpty) {
      setState(() {
        selectedCategories = savedCategories;
      });
    }
  }

  Future<void> _navigateAndRefresh(String routeName) async {
    await Navigator.pushNamed(context, routeName);
    if (!mounted) return;
    await _loadNotices();
    if (mounted) setState(() {});
  }

  Future<void> _saveSelectedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selectedCategories', selectedCategories);
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder:
          (context) => CategoryFilterDialog(
            selectedCategories: selectedCategories,
            onApply: (newCategories) {
              setState(() {
                selectedCategories = newCategories;
              });
              _saveSelectedCategories();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 초기화 전 null 체크해서 로딩 보여주기
    if (_selectedIndex == null || _pageController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final int year = baseYear + (_selectedIndex! ~/ 12);
    final int month = (_selectedIndex! % 12) + 1;

    final filteredNotices =
        allNotices
            .where((n) => selectedCategories.contains(n.category))
            .toList();

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
                        _selectedIndex = _todayIndex!;
                        _pageController!.jumpToPage(_todayIndex!);
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
                controller: _pageController!,
                onPageChanged: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final year = baseYear + (index ~/ 12);
                  final month = (index % 12) + 1;
                  final currentMonth = DateTime(year, month);

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
