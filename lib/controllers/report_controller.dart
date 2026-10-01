import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';

class ReportController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _selectedReason;
  bool _isSubmitting = false;
  String? _errorMessage;

  String? get selectedReason => _selectedReason;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  final List<String> commonReasons = [
    'Inappropriate Content / Language',
    'Spam or Scam',
    'Harassment or Bullying',
    'False Information / Fake Profile',
    'Unfulfilled Task / Transaction Issue',
    'Other',
  ];

  void setReason(String? reason) {
    _selectedReason = reason;
    notifyListeners();
  }

  Future<bool> submitReport({
    required String targetId,
    required ReportType targetType,
    required String details,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _errorMessage = 'You must be logged in to submit a report.';
      notifyListeners();
      return false;
    }

    if (_selectedReason == null || _selectedReason!.isEmpty) {
      _errorMessage = 'Please select a reason for the report.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final report = ReportModel(
        reporterId: currentUser.uid,
        targetId: targetId,
        targetType: targetType,
        reason: _selectedReason!,
        details: details.trim(),
      );

      await _firestore.collection('reports').add(report.toMap());

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = 'Failed to submit report. Please try again.';
      notifyListeners();
      return false;
    }
  }
}