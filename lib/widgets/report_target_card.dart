import 'package:flutter/material.dart';
import '../models/report_model.dart';

class ReportTargetCard extends StatelessWidget {
  final String targetTitle;
  final String? targetSubtitle;
  final ReportType targetType;

  const ReportTargetCard({
    super.key,
    required this.targetTitle,
    this.targetSubtitle,
    required this.targetType,
  });

  IconData _getIcon() {
    switch (targetType) {
      case ReportType.user:
        return Icons.person_outline;
      case ReportType.listing:
        return Icons.storefront_outlined;
      case ReportType.task:
        return Icons.work_outline;
      case ReportType.review:
        return Icons.rate_review_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF1976D2);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: themeColor.withValues(alpha: 0.1),
          child: Icon(_getIcon(), color: themeColor),
        ),
        title: Text(
          targetTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          targetSubtitle ?? 'Reporting dynamic ${targetType.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }
}