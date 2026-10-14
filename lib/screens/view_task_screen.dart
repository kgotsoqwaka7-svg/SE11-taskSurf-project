import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../screens/report_screen.dart';
import 'chat_screen.dart';

class TaskDetailsScreen extends StatelessWidget {
  final String taskId;
  final String title;
  final String category;
  final String location;
  final String payment;
  final String date;
  final String time;
  final String distance;
  final String description;
  final String providerId; 

  const TaskDetailsScreen({
    super.key,
    required this.taskId,
    required this.title,
    required this.category,
    required this.location,
    required this.payment,
    required this.date,
    required this.time,
    required this.distance,
    required this.providerId, 
    this.description =
        "Looking for a reliable and hard-working individual to help complete this task successfully. Please ensure you arrive on time and have the necessary tools if required.",
  });

  void _navigateToReportScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportScreen(
          targetId: taskId,
          targetTitle: title,
          targetSubtitle: '$category • $payment',
          targetType: ReportType.task,
        ),
      ),
    );
  }

  void _navigateToChatScreen(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send a message.')),
      );
      return;
    }

    if (currentUser.uid == providerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot message yourself.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          taskId: taskId,
          taskTitle: title,
          providerId: providerId,
          seekerId: currentUser.uid,
          seekerName: currentUser.displayName ?? 'Seeker',
          currentUserId: currentUser.uid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Task Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined, color: Colors.white),
            tooltip: 'Report Task',
            onPressed: () => _navigateToReportScreen(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                          color: Color(0xFF1976D2),
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Payment: ',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                      Text(
                        payment,
                        style: const TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  
                  // LIVE FETCH OF POSTER (Includes Blue Tick)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('Users').doc(providerId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Row(
                          children: [
                            CircleAvatar(radius: 16, backgroundColor: Color(0xFFE3F2FD)),
                            SizedBox(width: 10),
                            Text('Loading poster info...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        );
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text('Posted by: Unknown User', style: TextStyle(color: Colors.grey, fontSize: 13));
                      }

                      final userData = snapshot.data!.data() as Map<String, dynamic>;
                      final posterName = userData['name'] ?? 'Unknown User';
                      final posterImage = userData['profileImageUrl'] ?? '';
                      final isVerified = userData['isVerified'] == true;

                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFE3F2FD),
                            backgroundImage: posterImage.isNotEmpty ? NetworkImage(posterImage) : null,
                            child: posterImage.isEmpty
                                ? const Icon(Icons.person, size: 18, color: Color(0xFF1976D2))
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Posted by', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              Row(
                                children: [
                                  Text(
                                    posterName,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified_rounded, color: Color(0xFF1976D2), size: 16),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Logistics Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildLogisticsRow(Icons.location_on_outlined, 'Location',
                      '$location • $distance'),
                  const Divider(height: 24),
                  _buildLogisticsRow(
                      Icons.calendar_today_outlined, 'Date', date),
                  const Divider(height: 24),
                  _buildLogisticsRow(Icons.access_time_rounded, 'Time', time),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Task Description',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Message Icon Button
            Container(
              height: 54,
              width: 54,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF1976D2)),
                onPressed: () => _navigateToChatScreen(context),
              ),
            ),

            // Apply Button
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final currentUser = FirebaseAuth.instance.currentUser;
  
                      if (currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to apply.')));
                        return;
                      }

                      if (currentUser.uid == providerId) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot apply to your own task.')));
                        return;
                      }

                      try {
                          // 1. Fetch the worker's profile data to attach to the application
                          final userDoc = await FirebaseFirestore.instance.collection('Users').doc(currentUser.uid).get();
                          final userData = userDoc.data() ?? {};

                          // Extract just the number from the payment string (e.g., "R350" -> 350.0)
                          final double proposedPrice = double.tryParse(payment.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

                          // 2. Create the new application document
                          final docRef = FirebaseFirestore.instance.collection('applications').doc();

                          // 3. Write exactly to your ApplicationModel structure
                          await docRef.set({
                           'applicationId': docRef.id,
                           'taskId': taskId,
                           'taskProviderId': providerId, 
                           'workerId': currentUser.uid,
                           'workerName': userData['name'] ?? 'Unknown Worker',
                           'workerLocation': userData['area'] ?? 'Location unavailable',
                           'proposedPrice': proposedPrice,
                           'message': 'Hi, I am interested in completing this task for you.',
                           'status': 'pending',
                           'appliedAt': FieldValue.serverTimestamp(),
                           'workerRating': 0.0,
                      });

                        if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                            content: Text('Application sent successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(content: Text('Error submitting application: $e'), backgroundColor: Colors.red),
                             );
                          }
                       }
                },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Apply for Task',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogisticsRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1976D2), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}