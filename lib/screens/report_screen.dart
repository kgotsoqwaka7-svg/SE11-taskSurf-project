import 'package:flutter/material.dart';
import '../controllers/report_controller.dart';
import '../models/report_model.dart';
import '../widgets/report_reason_selector.dart';
import '../widgets/report_target_card.dart';

class ReportScreen extends StatefulWidget {
  final String targetId;
  final String targetTitle;
  final String? targetSubtitle;
  final ReportType targetType;

  const ReportScreen({
    super.key,
    required this.targetId,
    required this.targetTitle,
    this.targetSubtitle,
    required this.targetType,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _controller = ReportController();
  final _detailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _controller.submitReport(
      targetId: widget.targetId,
      targetType: widget.targetType,
      details: _detailsController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully. Thank you.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report ${widget.targetType.name.toUpperCase()}'),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportTargetCard(
                    targetTitle: widget.targetTitle,
                    targetSubtitle: widget.targetSubtitle,
                    targetType: widget.targetType,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select a reason',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ReportReasonSelector(
                    reasons: _controller.commonReasons,
                    selectedReason: _controller.selectedReason,
                    onSelected: (val) => _controller.setReason(val),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Additional details (optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _detailsController,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'Provide context to help moderators review...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _controller.isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                      ),
                      child: _controller.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit Report'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}