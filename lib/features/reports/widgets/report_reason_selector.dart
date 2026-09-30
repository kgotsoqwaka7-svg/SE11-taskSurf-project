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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: reasons.map((reason) {
        return RadioListTile<String>(
          title: Text(reason, style: const TextStyle(fontSize: 14)),
          value: reason,
          groupValue: selectedReason,
          onChanged: onSelected,
          contentPadding: EdgeInsets.zero,
          dense: true,
        );
      }).toList(),
    );
  }
}