import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'view-applicantions_screen.dart';

class TaskProviderDashboard extends StatelessWidget {
  const TaskProviderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Grab the current logged-in user's ID
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      // 1. Matched the light blue background color
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        // 2. Matched the primary dark blue color
        backgroundColor: const Color(0xFF1976D2), 
        elevation: 0,
        title: const Text(
          'My Posted Tasks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: currentUser == null
          ? const Center(child: Text('Please log in to view your tasks.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Tasks')
                  .where('creatorID', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading tasks.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('You have not posted any tasks yet.', style: TextStyle(fontSize: 16)));
                }

                final liveTasks = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(20.0), // Matched padding
                  itemCount: liveTasks.length,
                  itemBuilder: (context, index) {
                    final doc = liveTasks[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final title = data['title'] ?? 'Untitled Task';
                    final location = data['location'] ?? 'No Location Provided';
                    final applicantsCount = data['applicantsCount'] ?? 0;

                    // 3. Replaced the old Card with the exact styling from HomeScreen
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ViewApplicationsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.07),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // 4. Matched the light blue icon boxes
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.work_outline_rounded,
                                color: Color(0xFF1976D2),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    '$applicantsCount applications • $location',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // Matched the "Active" status indicator
                                  Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.grey,
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
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1976D2), // Matched primary color
        onPressed: () {
          // TODO: Link to the Post Task Form
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}