import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'account_info.dart'; 

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2), // Updated Team Color
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        actions: [
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
      body: currentUser == null
          ? const Center(child: Text('Please log in to view your profile.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('Users').doc(currentUser.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
                }

                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Profile data not found.'));
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;

// Explicitly forcing them to be Strings using ?.toString()
final String name = userData['name']?.toString() ?? 'New User';
final String location = userData['location']?.toString() ?? 'Location not set';
final String profileImageUrl = userData['profileImageUrl']?.toString() ?? '';
final String aboutMe = userData['aboutMe']?.toString() ?? '';
final String skillsString = userData['skills']?.toString() ?? '';

// Because skillsString is now strictly a String, we can simplify this line safely
List<String> skillsList = skillsString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : const NetworkImage('https://i.pravatar.cc/150?img=44') as ImageProvider,
                            ),
                            const SizedBox(height: 16),
                            Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
                            const SizedBox(height: 4),
                            Text(location, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Dynamic About Me Section
                      const Text('About Me', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        aboutMe.isNotEmpty ? aboutMe : 'You haven\'t added a bio yet. Click the edit button to add one!',
                        style: TextStyle(fontSize: 14, height: 1.5, color: aboutMe.isNotEmpty ? Colors.black87 : Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Dynamic Skills Section
                      const Text('Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      skillsList.isNotEmpty 
                        ? Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: skillsList.map((skill) => _buildSkillChip(skill)).toList(),
                          )
                        : const Text('No skills added yet.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSkillChip(String label) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Color(0xFF1976D2), fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFF1976D2).withOpacity(0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}