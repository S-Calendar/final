import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../widgets/notice_modal.dart';

class CustomCalendar extends StatefulWidget {
  final DateTime month;
  final List<Notice> notices;

  /// 카테고리 필터 리스트 (빈 리스트면 필터 적용 안함)
  final List<String> filterCategories;

  /// 외부에서 초기 선택 날짜 지정용 (optional)
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
    selectedDate = widget.initialSelectedDate;
  }

  @override
  void didUpdateWidget(covariant CustomCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSelectedDate != oldWidget.initialSelectedDate) {
      if (widget.initialSelectedDate != null &&
          widget.initialSelectedDate!.year == widget.month.year &&
          widget.initialSelectedDate!.month == widget.month.month) {
        selectedDate = widget.initialSelectedDate;
      }
    }
  }

  // 한국 주요 공휴일 (고정일 기준) + 일요일 포함 여부 체크 함수
  bool isKoreanHoliday(DateTime date) {
    final fixedHolidays = [
      DateTime(date.year, 1, 1),   // 신정
      DateTime(date.year, 3, 1),   // 삼일절
      DateTime(date.year, 5, 5),   // 어린이날
      DateTime(date.year, 6, 6),   // 현충일
      DateTime(date.year, 8, 15),  // 광복절
      DateTime(date.year, 10, 3),  // 개천절
      DateTime(date.year, 10, 9),  // 한글날
      DateTime(date.year, 12, 25), // 성탄절
    ];

    for (var d in fixedHolidays) {
      if (d.year == date.year && d.month == date.month && d.day == date.day) {
        return true;
      }
    }

    // 일요일은 공휴일로 간주
    if (date.weekday == DateTime.sunday) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final int daysInMonth =
        DateTime(widget.month.year, widget.month.month + 1, 0).day;
    final int firstWeekday =
        DateTime(widget.month.year, widget.month.month, 1).weekday % 7; // 0=일
    final int totalCells = daysInMonth + firstWeekday;
    final int numberOfWeeks = (totalCells / 7).ceil();

    List<Notice> base = widget.notices.where((n) => !n.isHidden).toList();
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
                Text('일', style: TextStyle(color: Colors.red)),
                Text('월'),
                Text('화'),
                Text('수'),
                Text('목'),
                Text('금'),
                Text('토', style: TextStyle(color: Colors.blue)),
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
                  final date = DateTime(widget.month.year, widget.month.month, day);

                  final dailyNotices =
                      filteredNotices.where((n) => n.includes(date)).toList()
                        ..sort((a, b) => a.duration.compareTo(b.duration));

                  final now = DateTime.now();
                  final bool isToday =
                      date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;

                  final bool isSelected = selectedDate != null &&
                      date.year == selectedDate!.year &&
                      date.month == selectedDate!.month &&
                      date.day == selectedDate!.day;

                  final bool isSaturday = date.weekday == DateTime.saturday;
                  final bool holiday = isKoreanHoliday(date);

                  Color textColor;
                  if (isToday) {
                    textColor = Colors.white;
                  } else if (holiday) {
                    textColor = Colors.red;
                  } else if (isSaturday) {
                    textColor = Colors.blue;
                  } else {
                    textColor = Colors.black;
                  }

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
                    child: Container(
                      height: isSelected ? cellHeight + 8 : cellHeight,
                      decoration: isSelected
                          ? BoxDecoration(
                              border: Border.all(
                                color: const Color.fromARGB(255, 158, 108, 167).withOpacity(0.6),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            )
                          : null,
                      child: Column(
                        children: [
                          const SizedBox(height: 2),
                          Container(
                            width: 25,
                            height: 25,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isToday ? Colors.red : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$day',
                              style: TextStyle(
                                color: isToday ? Colors.white : textColor,
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
                                      margin: const EdgeInsets.symmetric(vertical: 1),
                                      padding: const EdgeInsets.symmetric(horizontal: 2),
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
