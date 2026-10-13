import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'authScreen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Existing: Suspend user ──────────────────────────────────────────
  Future<void> _suspendUser(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'isSuspended': true,
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User account suspended'),
            backgroundColor: Colors.red),
      );
    } catch (e) {
      debugPrint('Error suspending user: $e');
    }
  }

  // ── Existing: Delete reported task ─────────────────────────────────
  Future<void> _deleteReportedTask(
      BuildContext context, String taskId, String reportId) async {
    try {
      await FirebaseFirestore.instance.collection('Tasks').doc(taskId).delete();
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({'status': 'resolved'});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted and report resolved')),
      );
    } catch (e) {
      debugPrint('Error deleting task: $e');
    }
  }

  // ── New: Approve verification request ──────────────────────────────
  Future<void> _approveVerification(
      BuildContext context, String requestId, String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Mark request as approved
      batch.update(
        FirebaseFirestore.instance
            .collection('verificationRequests')
            .doc(requestId),
        {'status': 'approved', 'reviewedAt': FieldValue.serverTimestamp()},
      );

      // Set verified flag and badge on user document
      batch.update(
        FirebaseFirestore.instance.collection('Users').doc(userId),
        {'isVerified': true},
      );

      await batch.commit();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User verified and blue tick awarded ✓'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error approving verification: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ── New: Reject verification request ───────────────────────────────
  Future<void> _rejectVerification(
      BuildContext context, String requestId, String userId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      batch.update(
        FirebaseFirestore.instance
            .collection('verificationRequests')
            .doc(requestId),
        {'status': 'rejected', 'reviewedAt': FieldValue.serverTimestamp()},
      );

      // Ensure isVerified is false
      batch.update(
        FirebaseFirestore.instance.collection('Users').doc(userId),
        {'isVerified': false},
      );

      await batch.commit();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification request rejected.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      debugPrint('Error rejecting verification: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.flag_rounded), text: 'Reports'),
            Tab(icon: Icon(Icons.verified_rounded), text: 'Verifications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportsTab(),
          _buildVerificationsTab(),
        ],
      ),
    );
  }

  // ── Tab 1: Reports (existing functionality, unchanged) ───────────
  Widget _buildReportsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data!.docs;
        if (reports.isEmpty) {
          return const Center(child: Text('No pending reports!'));
        }

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final reportDoc = reports[index];
            final data = reportDoc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('Reason: ${data['reason']}'),
                subtitle: Text(
                    'Type: ${data['targetType']} \nDetails: ${data['details']}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'suspend') {
                      _suspendUser(context, data['targetId']);
                    }
                    if (val == 'delete_task') {
                      _deleteReportedTask(
                          context, data['targetId'], reportDoc.id);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'suspend', child: Text('Suspend User')),
                    const PopupMenuItem(
                        value: 'delete_task', child: Text('Delete Task')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Tab 2: Verification requests (new) ───────────────────────────
  Widget _buildVerificationsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('verificationRequests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1976D2)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Unable to load pending verifications: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No pending verifications',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aSubmittedAt =
                (a.data() as Map<String, dynamic>)['submittedAt'];
            final bSubmittedAt =
                (b.data() as Map<String, dynamic>)['submittedAt'];
            if (aSubmittedAt is Timestamp && bSubmittedAt is Timestamp) {
              return aSubmittedAt.compareTo(bSubmittedAt);
            }
            if (aSubmittedAt is Timestamp) return -1;
            if (bSubmittedAt is Timestamp) return 1;
            return 0;
          });

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final doc = requests[index];
            final data = doc.data() as Map<String, dynamic>;
            final userId = data['userId'] as String? ?? '';
            final userEmail = data['userEmail'] as String? ?? '';
            final docData = data['documentUrl'] as String? ??
                data['documentData'] as String? ??
                '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info
                    Row(
                      children: [
                        const Icon(Icons.person_rounded,
                            color: Color(0xFF1976D2)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userEmail.isNotEmpty ? userEmail : userId,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'ID: $userId',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'PENDING',
                            style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Document preview
                    if (docData.isNotEmpty)
                      GestureDetector(
                        onTap: () => _showDocumentPreview(context, docData),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildDocumentPreview(docData),
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _rejectVerification(context, doc.id, userId),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _approveVerification(context, doc.id, userId),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentPreview(String docData) {
    final uri = Uri.tryParse(docData);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        docData,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _docErrorPlaceholder(),
      );
    }

    try {
      final base64Str = docData.contains(',') ? docData.split(',').last : docData;
      final bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _docErrorPlaceholder(),
      );
    } catch (_) {
      return _docErrorPlaceholder();
    }
  }

  Widget _docErrorPlaceholder() {
    return Container(
      height: 100,
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      ),
    );
  }

  void _showDocumentPreview(BuildContext context, String docData) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Document Preview',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildDocumentPreview(docData),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}