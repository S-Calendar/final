// 📁 lib/category_filter_dialog.dart
import 'package:flutter/material.dart';

class CategoryFilterDialog extends StatefulWidget {
  final List<String> selectedCategories;
  final Function(List<String>) onApply;

  const CategoryFilterDialog({
    super.key,
    required this.selectedCategories,
    required this.onApply,
  });

  @override
  State<CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<CategoryFilterDialog> {
  late List<String> tempSelected;

  final List<Map<String, dynamic>> allCategories = [
    {
      'label': '학과 공지(AI융합학부)',
      'value': 'ai학과공지',
      'color': Color(0x80FFABAB), // 연분홍
    },
    {
      'label': '학사 공지',
      'value': '학사공지',
      'color': Color(0x80ABC9FF), // 연파랑
    },
    {
      'label': '취업 공지',
      'value': '취업공지',
      'color': Color(0x80A5FAA5), // 연초록
    },
  ];

  @override
  void initState() {
    super.initState();
    tempSelected = List.from(widget.selectedCategories);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('카테고리 편집', style: TextStyle(fontSize: 20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children:
            allCategories.map((category) {
              final isSelected = tempSelected.contains(category['value']);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // 색 띠
                    Container(
                      width: 8,
                      height: 36,
                      decoration: BoxDecoration(
                        color: category['color'],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 체크박스 (동그라미)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            tempSelected.remove(category['value']);
                          } else {
                            tempSelected.add(category['value']);
                          }
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black54, width: 2),
                          color:
                              isSelected
                                  ? category['color']
                                  : Colors.transparent,
                        ),
                        child:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 텍스트
                    Expanded(
                      child: Text(
                        category['label'],
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),

      actions: [
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
            ),
            onPressed: () {
              widget.onApply(tempSelected);
              Navigator.of(context).pop();
            },
            child: const Text(
              '해당 공지만 확인하기',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
