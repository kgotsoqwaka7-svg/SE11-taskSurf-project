import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // Function to ban a user
  Future<void> _suspendUser(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance.collection('Users').doc(userId).update({
        'isSuspended': true,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User account suspended'), backgroundColor: Colors.red),
      );
    } catch (e) {
      print('Error suspending user: $e');
    }
  }

  // Function to delete a flagged task
  Future<void> _deleteReportedTask(BuildContext context, String taskId, String reportId) async {
    try {
      await FirebaseFirestore.instance.collection('Tasks').doc(taskId).delete();
      await FirebaseFirestore.instance.collection('reports').doc(reportId).update({'status': 'resolved'});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted and report resolved')),
      );
    } catch (e) {
      print('Error deleting task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.red.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('reports').where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final reports = snapshot.data!.docs;
          if (reports.isEmpty) return const Center(child: Text('No pending reports!'));

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final reportDoc = reports[index];
              final data = reportDoc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Reason: ${data['reason']}'),
                  subtitle: Text('Type: ${data['targetType']} \nDetails: ${data['details']}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'suspend') _suspendUser(context, data['targetId']);
                      if (val == 'delete_task') _deleteReportedTask(context, data['targetId'], reportDoc.id);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'suspend', child: Text('Suspend User')),
                      const PopupMenuItem(value: 'delete_task', child: Text('Delete Task')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}