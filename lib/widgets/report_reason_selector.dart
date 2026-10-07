import 'package:flutter/material.dart';

class ReportReasonSelector extends StatelessWidget {
  final List<String> reasons;
  final String? selectedReason;
  final ValueChanged<String?> onSelected;

  const ReportReasonSelector({
    super.key,
    required this.reasons,
    required this.selectedReason,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1976D2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: reasons.map((reason) {
        final isSelected = selectedReason == reason;
        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? themeColor : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: RadioListTile<String>(
            value: reason,
            groupValue: selectedReason,
            onChanged: onSelected,
            title: Text(
              reason,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? themeColor : Colors.black87,
              ),
            ),
            activeColor: themeColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
            dense: true,
          ),
        );
      }).toList(),
    );
  }
}