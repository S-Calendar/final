// year_page.dart
import 'package:flutter/material.dart';

class YearCalendarPage extends StatefulWidget {
  const YearCalendarPage({super.key});

  @override
  State<YearCalendarPage> createState() => _YearCalendarPageState();
}

class _YearCalendarPageState extends State<YearCalendarPage> {
  late int selectedYear;
  late final List<int> selectableYears;

  @override
  void initState() {
    super.initState();
    final int currentYear = DateTime.now().year;
    selectableYears = List.generate(3, (i) => currentYear - 1 + i); 
    selectedYear = DateTime.now().year; 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A6FB3),
        foregroundColor: Colors.white,
        title: DropdownButton<int>(
          value: selectedYear,
          dropdownColor: const Color(0xFF6A6FB3),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          onChanged: (int? newYear) {
            if (newYear != null) {
              setState(() {
                selectedYear = newYear;
              });
            }
          },
          items: selectableYears.map((year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text('$year년'),
            );
          }).toList(),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final int month = index + 1;
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/main_page',
                  arguments: {
                    'year': selectedYear,
                    'month': month,
                  },
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF6A6FB3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6A6FB3), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$month월',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A6FB3),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
