class ReportModel {
  final String reportID;
  final String reporterID;
  final String targetType; // 'task' or 'user'
  final String? reportedTaskID; // Filled if targetType is 'task'
  final String? reportedUserID; // Filled if targetType is 'user'
  final String reason;
  final String status; // 'pending', 'under_investigation', 'resolved', 'dismissed'
  final DateTime createdAt;

  ReportModel({
    required this.reportID,
    required this.reporterID,
    required this.targetType,
    this.reportedTaskID,
    this.reportedUserID,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reportID': reportID,
      'reporterID': reporterID,
      'targetType': targetType,
      'reportedTaskID': reportedTaskID,
      'reportedUserID': reportedUserID,
      'reason': reason,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      reportID: map['reportID'] ?? '',
      reporterID: map['reporterID'] ?? '',
      targetType: map['targetType'] ?? 'task',
      reportedTaskID: map['reportedTaskID'],
      reportedUserID: map['reportedUserID'],
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}