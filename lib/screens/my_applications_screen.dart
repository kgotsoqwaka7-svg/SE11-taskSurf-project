import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'view_task_screen.dart'; // Make sure this import matches your file name!
import 'review_screen.dart'; // Make sure this import matches your file name!

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Please log in to view your applications.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: const Text('My Applications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('applications').where('workerId', isEqualTo: currentUser.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
          if (snapshot.hasError) return Center(child: Text('Error loading applications.'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(25)),
                    child: const Icon(Icons.assignment_outlined, size: 45, color: Color(0xFF1976D2)),
                  ),
                  const SizedBox(height: 20),
                  const Text('No Applications Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text('When you apply for tasks, they will appear here.', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final applications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final appData = applications[index].data() as Map<String, dynamic>;
              final taskId = appData['taskId'] ?? '';
              final status = appData['status'] ?? 'pending';
              final proposedPrice = appData['proposedPrice'] ?? 0.0;
              
              String dateApplied = 'Recently';
              if (appData['appliedAt'] != null && appData['appliedAt'] is Timestamp) {
                final date = (appData['appliedAt'] as Timestamp).toDate();
                dateApplied = DateFormat('MMM d, yyyy').format(date);
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('Tasks').doc(taskId).get(),
                builder: (context, taskSnapshot) {
                  Map<String, dynamic> taskData = {};
                  bool taskExists = false;

                  if (taskSnapshot.connectionState == ConnectionState.done && taskSnapshot.hasData && taskSnapshot.data!.exists) {
                    taskData = taskSnapshot.data!.data() as Map<String, dynamic>;
                    taskExists = true;
                  }

                  final String title = taskExists ? (taskData['title'] ?? 'Untitled Task') : 'Task Unavailable';
                  final String category = taskExists ? (taskData['category'] ?? 'General') : '...';
                  final String providerId = taskExists ? taskData['creatorID'] : (appData['taskProviderId'] ?? '');

                  return _buildApplicationCard(
                    context: context, taskId: taskId, title: title, category: category,
                    status: status, price: proposedPrice.toString(), date: dateApplied,
                    taskData: taskData, providerId: providerId, taskExists: taskExists,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildApplicationCard({
    required BuildContext context, required String taskId, required String title, required String category,
    required String status, required String price, required String date,
    required Map<String, dynamic> taskData, required String providerId, required bool taskExists,
  }) {
    Color statusColor; Color statusBgColor; String statusText;

    switch (status.toLowerCase()) {
      case 'accepted':
        statusColor = Colors.green.shade700; statusBgColor = Colors.green.shade50; statusText = 'Accepted'; break;
      case 'completed':
        statusColor = Colors.blue.shade700; statusBgColor = Colors.blue.shade50; statusText = 'Completed'; break;
      case 'rejected':
        statusColor = Colors.red.shade700; statusBgColor = Colors.red.shade50; statusText = 'Rejected'; break;
      case 'pending':
      default:
        statusColor = Colors.orange.shade700; statusBgColor = Colors.orange.shade50; statusText = 'Pending Review'; break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.work_outline, color: Color(0xFF1976D2), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(category, style: const TextStyle(color: Color(0xFF1976D2), fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(20)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Bid', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('R$price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Applied On', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(date, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons: View Details & Rate Provider
          Row(
            children: [
              if (taskExists)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailsScreen(
                            taskId: taskId,
                            title: taskData['title'] ?? 'Task Details',
                            category: taskData['category'] ?? 'General',
                            location: taskData['location'] ?? 'Location not specified',
                            payment: 'R${taskData['paymentAmount'] ?? price}',
                            date: taskData['taskDate'] ?? 'Flexible',
                            time: taskData['taskTime'] ?? 'Anytime',
                            distance: 'Nearby',
                            description: taskData['description'] ?? 'No description provided.',
                            providerId: providerId,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1976D2),
                      side: const BorderSide(color: Color(0xFF1976D2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),

              if (taskExists && (status == 'accepted' || status == 'completed')) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      String providerName = 'Task Provider';
                      if (providerId.isNotEmpty) {
                        final pDoc = await FirebaseFirestore.instance.collection('Users').doc(providerId).get();
                        if (pDoc.exists && pDoc.data() != null) {
                          providerName = pDoc.data()!['name'] ?? 'Task Provider';
                        }
                      }

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReviewScreen(
                              taskId: taskId,
                              reviewedUserId: providerId,
                              reviewedUserName: providerName,
                              taskTitle: title,
                              taskCategory: category,
                              taskPayment: 'R$price',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.star_rate_rounded, size: 16),
                    label: const Text('Rate Provider', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}