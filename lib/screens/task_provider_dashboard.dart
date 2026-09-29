import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'view_applicants_screen.dart';

class TaskProviderDashboard extends StatelessWidget {
  const TaskProviderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Grab the current logged-in user's ID
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A75FF), 
        elevation: 0,
        title: const Text(
          'My Posted Tasks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      // 1. Replace the static list with a StreamBuilder listening to Firestore
      body: currentUser == null
          ? const Center(child: Text('Please log in to view your tasks.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Tasks')
                  // Only pull tasks where the providerId matches this user
                  .where('providerId', isEqualTo: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                // 2. Show a loading spinner while waiting for Firebase
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF5A75FF)));
                }

                // 3. Handle empty states
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading tasks.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('You have not posted any tasks yet.', style: TextStyle(fontSize: 16)));
                }

                // 4. Extract the live documents from Firestore
                final liveTasks = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: liveTasks.length,
                  itemBuilder: (context, index) {
                    final doc = liveTasks[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // 5. Map the Firestore fields (with fallbacks if fields are missing)
                    final title = data['title'] ?? 'Untitled Task';
                    final location = data['location'] ?? 'No Location Provided';
                    final applicantsCount = data['applicantsCount'] ?? 0;
                    final posted = data['posted'] ?? 'Recently';

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFF5A75FF), width: 1.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5A75FF)),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('$location • Posted $posted', style: const TextStyle(color: Colors.black87)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5A75FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$applicantsCount Applicants',
                                  style: const TextStyle(color: Color(0xFF5A75FF), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF5A75FF)),
                        onTap: () {
                          // Pass the specific task ID to the applicants screen if needed
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ViewApplicantsScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF5A75FF),
        onPressed: () {
          // TODO: Link to the Post Task Form
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Post Task', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}