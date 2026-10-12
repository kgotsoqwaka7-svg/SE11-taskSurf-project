import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your applications.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        title: const Text(
          'My Applications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('workerId', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
          }

          if (snapshot.hasError) {
            // If you haven't created a Firestore composite index yet, orderBy combined with where might throw an error.
            return Center(child: Text('Error loading applications.\n\n${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      size: 45,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No Applications Yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'When you apply for tasks, they will appear here.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
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
                  String taskTitle = 'Loading Task...';
                  String taskCategory = '...';

                  if (taskSnapshot.connectionState == ConnectionState.done && taskSnapshot.hasData && taskSnapshot.data!.exists) {
                    final taskData = taskSnapshot.data!.data() as Map<String, dynamic>;
                    taskTitle = taskData['title'] ?? 'Untitled Task';
                    taskCategory = taskData['category'] ?? 'General';
                  } else if (taskSnapshot.connectionState == ConnectionState.done && !taskSnapshot.data!.exists) {
                    taskTitle = 'Task Deleted by Provider';
                  }

                  return _buildApplicationCard(
                    title: taskTitle,
                    category: taskCategory,
                    status: status,
                    price: proposedPrice.toString(),
                    date: dateApplied,
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
    required String title,
    required String category,
    required String status,
    required String price,
    required String date,
  }) {
    // Determine status colors
    Color statusColor;
    Color statusBgColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'accepted':
        statusColor = Colors.green.shade700;
        statusBgColor = Colors.green.shade50;
        statusText = 'Accepted';
        break;
      case 'rejected':
        statusColor = Colors.red.shade700;
        statusBgColor = Colors.red.shade50;
        statusText = 'Rejected';
        break;
      case 'pending':
      default:
        statusColor = Colors.orange.shade700;
        statusBgColor = Colors.orange.shade50;
        statusText = 'Pending Review';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.work_outline, color: Color(0xFF1976D2), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                      style: const TextStyle(color: Color(0xFF1976D2), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
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
        ],
      ),
    );
  }
}