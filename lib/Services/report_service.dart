import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> submitReport(ReportModel report) async {
    try {
      await _firestore.collection('reports').add(report.toMap());
    } catch (e) {
      print('Error submitting report: $e');
      rethrow;
    }
  }

  Future<void> reportTask({
    required String reporterId,
    required String taskId,
    required String reason,
    String details = '',
  }) async {
    final report = ReportModel(
      reporterId: reporterId,
      targetId: taskId,
      targetType: ReportType.task,
      reason: reason,
      details: details,
    );

    await submitReport(report);
  }

  Future<void> reportUser({
    required String reporterId,
    required String userId,
    required String reason,
    String details = '',
  }) async {
    final report = ReportModel(
      reporterId: reporterId,
      targetId: userId,
      targetType: ReportType.user,
      reason: reason,
      details: details,
    );

    await submitReport(report);
  }
}