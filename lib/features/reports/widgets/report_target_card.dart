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
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(_getIcon(), color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          targetTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: targetSubtitle != null
            ? Text(
                targetSubtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : Text('Reporting dynamic ${targetType.name}'),
      ),
    );
  }
}