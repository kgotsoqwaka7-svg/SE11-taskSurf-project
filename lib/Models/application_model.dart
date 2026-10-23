class ApplicationModel {
  final String applicationId;
  final String taskId;
  final String taskProviderId;
  final String workerId;
  final String workerName;
  final String workerLocation;
  final double proposedPrice;
  final String message;
  final String status;
  final DateTime? appliedAt;
  final double workerRating;

  ApplicationModel({
    required this.applicationId,
    required this.taskId,
    required this.taskProviderId,
    required this.workerId,
    required this.workerName,
    required this.workerLocation,
    required this.proposedPrice,
    required this.message,
    required this.status,
    required this.appliedAt,
    required this.workerRating,
  });

  factory ApplicationModel.fromMap(Map<String, dynamic> data) {
    return ApplicationModel(
      applicationId: data['applicationId']?.toString() ?? '',
      taskId: data['taskId']?.toString() ?? '',
      taskProviderId: data['taskProviderId']?.toString() ?? '',
      workerId: data['workerId']?.toString() ?? '',
      workerName: data['workerName']?.toString() ?? '',
      workerLocation: data['workerLocation']?.toString() ?? '',
      proposedPrice: (data['proposedPrice'] as num?)?.toDouble() ?? 0.0,
      message: data['message']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      appliedAt: data['appliedAt'] != null
          ? (data['appliedAt'] as dynamic).toDate()
          : null,
      workerRating: (data['workerRating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'applicationId': applicationId,
      'taskId': taskId,
      'taskProviderId': taskProviderId,
      'workerId': workerId,
      'workerName': workerName,
      'workerLocation': workerLocation,
      'proposedPrice': proposedPrice,
      'message': message,
      'status': status,
      'appliedAt': appliedAt,
      'workerRating': workerRating,
    };
  }
}