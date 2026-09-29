import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a new report for either a task or a user
  Future<void> submitReport(ReportModel report) async {
    try {
      await _firestore
          .collection('Reports')
          .doc(report.reportID)
          .set(report.toMap());
    } catch (e) {
      print('Error submitting report: $e');
      rethrow;
    }
  }

  // Helper method specifically for reporting a task listing
  Future<void> reportTask({
    required String reporterID,
    required String taskID,
    required String reason,
  }) async {
    String reportID = _firestore.collection('Reports').doc().id; // Auto-generated Firestore ID

    ReportModel report = ReportModel(
      reportID: reportID,
      reporterID: reporterID,
      targetType: 'task',
      reportedTaskID: taskID,
      reason: reason,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await submitReport(report);
  }

  // Helper method specifically for reporting an unsafe/fraudulent user
  Future<void> reportUser({
    required String reporterID,
    required String reportedUserID,
    required String reason,
  }) async {
    String reportID = _firestore.collection('Reports').doc().id;

    ReportModel report = ReportModel(
      reportID: reportID,
      reporterID: reporterID,
      targetType: 'user',
      reportedUserID: reportedUserID,
      reason: reason,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await submitReport(report);
  }
}