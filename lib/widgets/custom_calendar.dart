// widgets/custom_calendar.dart
import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../widgets/notice_modal.dart';

class CustomCalendar extends StatefulWidget {
  final DateTime month;
  final List<Notice> notices;

  /// 카테고리 필터 리스트 (빈 리스트면 필터 적용 안함)
  final List<String> filterCategories;

  /// 외부(예: today_icon 클릭)에서 초기 선택 날짜를 지정하고 싶을 때 사용
  final DateTime? initialSelectedDate;

  const CustomCalendar({
    super.key,
    required this.month,
    required this.notices,
    this.filterCategories = const [],
    this.initialSelectedDate,
  });

  @override
  State<CustomCalendar> createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    // 외부에서 초기 선택 날짜가 들어오면 반영
    selectedDate = widget.initialSelectedDate;
  }

  @override
  void didUpdateWidget(covariant CustomCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // month(페이지) 변경 시, initialSelectedDate가 현재 month와 같으면 갱신
    if (widget.initialSelectedDate != oldWidget.initialSelectedDate) {
      if (widget.initialSelectedDate != null &&
          widget.initialSelectedDate!.year == widget.month.year &&
          widget.initialSelectedDate!.month == widget.month.month) {
        selectedDate = widget.initialSelectedDate;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int daysInMonth =
        DateTime(widget.month.year, widget.month.month + 1, 0).day;
    final int firstWeekday =
        DateTime(widget.month.year, widget.month.month, 1).weekday % 7; // 0=일
    final int totalCells = daysInMonth + firstWeekday;
    final int numberOfWeeks = (totalCells / 7).ceil();

    // 1) 숨김 공지 제거
    List<Notice> base = widget.notices.where((n) => !n.isHidden).toList();

    // 2) 카테고리 필터 적용 (필요 시)
    final filteredNotices = (widget.filterCategories.isEmpty)
        ? base
        : base.where((n) => widget.filterCategories.contains(n.category)).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const double headerHeight = 60;
        final double maxHeight = constraints.maxHeight;
        final double gridHeight = maxHeight - headerHeight;
        final double cellHeight = gridHeight / numberOfWeeks;
        final double cellWidth = (constraints.maxWidth - 6 * 6 - 16) / 7;
        final double aspectRatio = cellWidth / cellHeight;

        return Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text('일'),
                Text('월'),
                Text('화'),
                Text('수'),
                Text('목'),
                Text('금'),
                Text('토'),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: gridHeight,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: numberOfWeeks * 7,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 3,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) {
                  if (index < firstWeekday ||
                      index >= firstWeekday + daysInMonth) {
                    return const SizedBox();
                  }

                  final int day = index - firstWeekday + 1;
                  final date = DateTime(
                    widget.month.year,
                    widget.month.month,
                    day,
                  );

                  // 날짜에 포함되는 공지 필터링
                  final dailyNotices =
                      filteredNotices.where((n) => n.includes(date)).toList()
                        ..sort((a, b) => a.duration.compareTo(b.duration));

                  final now = DateTime.now();
                  final bool isToday =
                      date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;

                  final bool isSelected =
                      selectedDate != null &&
                      date.year == selectedDate!.year &&
                      date.month == selectedDate!.month &&
                      date.day == selectedDate!.day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDate = date;
                      });

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => NoticeBottomSheet(
                          date: date,
                          notices: dailyNotices,
                        ),
                      );
                    },
                    // ✅ 셀 전체 컨테이너에 테두리를 적용하여 "직사각형" 선택 표시
                    child: Container(     
                      height: isSelected ? cellHeight + 8 : cellHeight,
                      decoration: isSelected
                          ? BoxDecoration(
                              border: Border.all(
                                color: const Color.fromARGB(255, 158, 108, 167).withOpacity(0.6), // ✅ 보라색 + 투명도
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                      child: Column(
                        children: [
                          const SizedBox(height: 2),
                          // 날짜 숫자 원형 배경(오늘은 빨간 원)
                          Container(
                            width: 25,
                            height: 25,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Colors.red
                                  : Colors.transparent, // 오늘 동그라미 배경
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$day',
                              style: TextStyle(
                                color: isToday ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  ...dailyNotices.take(4).map((notice) {
                                    final Color bgColor = notice.color;
                                    return Container(
                                      height: 14,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 1,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        notice.title,
                                        style: const TextStyle(
                                          fontSize: 8,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }),
                                  if (dailyNotices.length > 4)
                                    Text(
                                      '+${dailyNotices.length - 4}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
