enum ReportType { user, listing, task, review }

class ReportModel {
  final String? id;
  final String reporterId;
  final String targetId; // ID of the user, item, or task being reported
  final ReportType targetType;
  final String reason;
  final String details;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'

  ReportModel({
    this.id,
    required this.reporterId,
    required this.targetId,
    required this.targetType,
    required this.reason,
    required this.details,
    DateTime? createdAt,
    this.status = 'pending',
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'targetId': targetId,
      'targetType': targetType.name,
      'reason': reason,
      'details': details,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReportModel(
      id: docId,
      reporterId: map['reporterId'] ?? '',
      targetId: map['targetId'] ?? '',
      targetType: ReportType.values.firstWhere(
        (e) => e.name == map['targetType'],
        orElse: () => ReportType.user,
      ),
      reason: map['reason'] ?? '',
      details: map['details'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      status: map['status'] ?? 'pending',
    );
  }
}