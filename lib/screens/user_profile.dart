import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'account_info.dart'; 
import 'verification_screen.dart'; // Added import for the verification screen

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  ImageProvider? _getProfileImageProvider(String? url) {
    if (url == null) return null;
    final clean = url.trim();
    if (clean.isEmpty || clean == 'null') return null;
    if (clean.startsWith('data:image')) {
      try {
        final base64String = clean.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (_) {
        return null;
      }
    }
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      try {
        return MemoryImage(base64Decode(clean));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(clean);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
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

                final String name = userData['name']?.toString() ?? 'New User';
                final String location = userData['location']?.toString() ?? 'Location not set';
                final bool isVerified = userData['isVerified'] == true; // Fetch verification status
                final String profileImageUrl = (userData['profileImageUrl'] ??
                        userData['photoUrl'] ??
                        userData['photoURL'] ??
                        userData['profilePicture'] ??
                        userData['profileImage'] ??
                        currentUser.photoURL ??
                        '')
                    .toString()
                    .trim();
                final String aboutMe = userData['aboutMe']?.toString() ?? '';
                final String skillsString = userData['skills']?.toString() ?? '';

                List<String> skillsList = skillsString
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Builder(
                              builder: (context) {
                                final profileProvider = _getProfileImageProvider(profileImageUrl);
                                return CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFFE3F2FD),
                                  backgroundImage: profileProvider,
                                  child: profileProvider == null
                                      ? const Icon(Icons.person_rounded, color: Color(0xFF1976D2), size: 55)
                                      : null,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Name with optional Blue Tick
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
                                if (isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded, color: Color(0xFF1976D2), size: 24),
                                ],
                              ],
                            ),
                            
                            const SizedBox(height: 4),
                            Text(location, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                            const SizedBox(height: 12),

                            // LIVE AVERAGE RATING CALCULATOR & BADGE
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('reviews')
                                  .where('reviewedUserId', isEqualTo: currentUser.uid)
                                  .snapshots(),
                              builder: (context, reviewSnap) {
                                double avgRating = 0.0;
                                int totalReviews = 0;

                                if (reviewSnap.hasData && reviewSnap.data!.docs.isNotEmpty) {
                                  totalReviews = reviewSnap.data!.docs.length;
                                  double sum = 0.0;
                                  for (var doc in reviewSnap.data!.docs) {
                                    final data = doc.data() as Map<String, dynamic>;
                                    sum += (data['rating'] as num?)?.toDouble() ?? 0.0;
                                  }
                                  avgRating = sum / totalReviews;
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.amber.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        totalReviews > 0 ? avgRating.toStringAsFixed(1) : 'New User',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "($totalReviews ${totalReviews == 1 ? 'review' : 'reviews'})",
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // Verify Profile Button (Shows if not verified)
                            if (!isVerified) ...[
                              const SizedBox(height: 16),
                              FutureBuilder<QuerySnapshot>(
                                future: FirebaseFirestore.instance
                                    .collection('verificationRequests')
                                    .where('userId', isEqualTo: currentUser.uid)
                                    .where('status', isEqualTo: 'pending')
                                    .limit(1)
                                    .get(),
                                builder: (context, reqSnapshot) {
                                  final isPending = reqSnapshot.hasData && reqSnapshot.data!.docs.isNotEmpty;

                                  if (isPending) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.orange.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.hourglass_top_rounded, size: 18, color: Colors.orange.shade700),
                                          const SizedBox(width: 6),
                                          Text('Verification Pending', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    );
                                  }

                                  return ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const VerificationScreen()),
                                      );
                                    },
                                    icon: const Icon(Icons.verified_user_rounded, size: 18),
                                    label: const Text('Verify Account', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade500,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                  );
                                },
                              ),
                            ],
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
                              spacing: 8.0, runSpacing: 8.0,
                              children: skillsList.map((skill) => _buildSkillChip(skill)).toList(),
                            )
                          : const Text('No skills added yet.', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 28),

                      // DYNAMIC REVIEWS LIST
                      const Text('Ratings & Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reviews')
                            .where('reviewedUserId', isEqualTo: currentUser.uid)
                            .snapshots(),
                        builder: (context, reviewSnap) {
                          if (reviewSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
                          }

                          if (!reviewSnap.hasData || reviewSnap.data!.docs.isEmpty) {
                            return const Text('No reviews received yet.', style: TextStyle(color: Colors.grey));
                          }

                          final reviews = reviewSnap.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: reviews.length,
                            itemBuilder: (context, index) {
                              final rData = reviews[index].data() as Map<String, dynamic>;
                              final double rating = (rData['rating'] as num?)?.toDouble() ?? 0.0;
                              final String comment = rData['comment'] ?? 'No comment written.';
                              final List<String> tags = rData['tags'] != null ? List<String>.from(rData['tags']) : [];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F9FC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Row(
                                          children: List.generate(5, (sIndex) {
                                            return Icon(
                                              sIndex < rating.round() ? Icons.star : Icons.star_border,
                                              size: 16, color: Colors.orange,
                                            );
                                          }),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(comment, style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black87)),
                                    if (tags.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        children: tags.map((t) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(6)),
                                            child: Text(t, style: const TextStyle(fontSize: 10, color: Color(0xFF1976D2), fontWeight: FontWeight.w600)),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 30),
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