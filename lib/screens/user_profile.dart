import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'account_info.dart'; // Ensure this points to your edit screen

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Grab the currently logged-in user
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A75FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        actions: [
          // 2. Added an Edit Button to reach your AccountInfoScreen
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountInfoScreen()),
              );
            },
          )
        ],
      ),
      // 3. If no user is logged in, show a prompt. Otherwise, open the Firestore stream.
      body: currentUser == null
          ? const Center(child: Text('Please log in to view your profile.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('Users').doc(currentUser.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF5A75FF)));
                }

                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Profile data not found.'));
                }

                // 4. Extract the live data from Firebase
                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final name = userData['name'] ?? 'New User';
                final location = userData['location'] ?? 'Location not set';
                final profileImageUrl = userData['profileImageUrl'] ?? '';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Avatar and Live Basic Info
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade200,
                              // Show uploaded image if it exists, otherwise show placeholder
                              backgroundImage: profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : const NetworkImage('https://i.pravatar.cc/150?img=44') as ImageProvider,
                            ),
                            const SizedBox(height: 16),
                            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5A75FF))),
                            const SizedBox(height: 4),
                            Text(location, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                            const SizedBox(height: 8),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 20),
                                SizedBox(width: 4),
                                Text('4.9 (134 Reviews)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // About Me Section
                      const Text('About Me', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text(
                        'Reliable and detail-oriented worker with 3+ years of experience in home repairs, furniture assembly, and general landscaping. Always on time and ready to help!',
                        style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                      ),
                      const SizedBox(height: 24),

                      // Skills Section (Chips)
                      const Text('Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          _buildSkillChip('Carpentry'),
                          _buildSkillChip('Furniture Assembly'),
                          _buildSkillChip('Painting'),
                          _buildSkillChip('Yard Cleaning'),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Completed Tasks / Experience
                      const Text('Experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.check_circle, color: Colors.green),
                        ),
                        title: const Text('42 Tasks Completed', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('100% completion rate this month'),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  // Helper widget to keep the skills UI clean
  Widget _buildSkillChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Color(0xFF5A75FF), fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFF5A75FF).withOpacity(0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}