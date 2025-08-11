// year_page.dart
import 'package:flutter/material.dart';

class YearCalendarPage extends StatefulWidget {
  const YearCalendarPage({super.key});

  @override
  State<YearCalendarPage> createState() => _YearCalendarPageState();
}

class _YearCalendarPageState extends State<YearCalendarPage> {
  late int selectedYear;

  static const Color textMain = Color(0xFF202124);
  static const Color textDim  = Color(0x80202124);
  static const Color line     = Color(0x1A000000);

  @override
  void initState() {
    super.initState();
    selectedYear = DateTime.now().year;
  }

  void _changeYear(int delta) => setState(() => selectedYear += delta);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textMain,
        automaticallyImplyLeading: true, 
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _changeYear(-1),
              icon: const Icon(Icons.chevron_left),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              splashRadius: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '$selectedYear년',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textMain,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _changeYear(1),
              icon: const Icon(Icons.chevron_right),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              splashRadius: 18,
            ),
          ],
        ),
        actions: const [],
      ),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        child: LayoutBuilder(
          builder: (context, c) {
            const cols = 3;
            const hGap = 12.0;
            const vGap = 14.0;
            final itemW = (c.maxWidth - hGap * (cols - 1)) / cols;
            final itemH = (c.maxHeight - vGap * 3) / 4;
            final aspect = itemW / itemH;
            final scale = (itemH / 160).clamp(0.9, 1.2);

            return GridView.builder(
              itemCount: 12,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: hGap,
                mainAxisSpacing: vGap,
                childAspectRatio: aspect,
              ),
              itemBuilder: (context, i) {
                final month = i + 1;
                final tappedMonth = month; 

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: ValueKey('month-$selectedYear-$month'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/main_page',
                        arguments: {'year': selectedYear, 'month': tappedMonth},
                      );
                    },
                    child: _MinimalMonth(
                      year: selectedYear,
                      month: month,
                      now: now,
                      textMain: textMain,
                      textDim: textDim,
                      line: line,
                      monthTitleSize: 18 * scale,
                      dayTextSize: 11 * scale,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MinimalMonth extends StatelessWidget {
  const _MinimalMonth({
    required this.year,
    required this.month,
    required this.now,
    required this.textMain,
    required this.textDim,
    required this.line,
    this.monthTitleSize = 18,
    this.dayTextSize = 11,
  });

  final int year;
  final int month;
  final DateTime now;
  final Color textMain, textDim, line;
  final double monthTitleSize, dayTextSize;

  int _daysInMonth(int y, int m) => DateUtils.getDaysInMonth(y, m);
  int _leadingOffsetSunday(DateTime first) => first.weekday % 7;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(year, month, 1);
    final days = _daysInMonth(year, month);
    final leading = _leadingOffsetSunday(first);
    const totalCells = 42;
    final prevLast = DateTime(year, month, 0);
    final prevDays = _daysInMonth(prevLast.year, prevLast.month);
    final bool thisMonthNow = (now.year == year && now.month == month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 2),
          child: Text(
            '$month월',
            style: TextStyle(
              fontSize: monthTitleSize,
              fontWeight: FontWeight.w800,
              color: textMain,
              letterSpacing: -0.2,
              height: 1.0,
            ),
          ),
        ),
        Container(height: 1, color: line),
        const SizedBox(height: 6),

        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 3, 
                crossAxisSpacing: 2, 
              ),
              itemCount: totalCells,
              itemBuilder: (context, idx) {
                late int dayNum;
                late bool inCurrentMonth;

                if (idx < leading) {
                  dayNum = prevDays - (leading - idx) + 1; 
                  inCurrentMonth = false;
                } else if (idx < leading + days) {
                  dayNum = (idx - leading) + 1; 
                  inCurrentMonth = true;
                } else {
                  dayNum = (idx - (leading + days)) + 1; 
                  inCurrentMonth = false;
                }

                final bool isToday =
                    thisMonthNow && inCurrentMonth && (now.day == dayNum);

                final textStyle = TextStyle(
                  fontSize: dayTextSize,
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: inCurrentMonth ? textMain : textDim,
                  height: 1.0,
                );

                final child = Text('$dayNum', style: textStyle);

                return Center(
                  child: isToday
                      ? Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: textMain, width: 1),
                          ),
                          child: child,
                        )
                      : child,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
