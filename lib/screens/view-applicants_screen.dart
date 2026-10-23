import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'review_screen.dart'; 

class ViewApplicationsScreen extends StatelessWidget {
  final String taskId; 

  const ViewApplicationsScreen({
    super.key, 
    required this.taskId,
  });

  void _showProfileDialog(
    BuildContext context, {
    required String name,
    required String profilePic,
    required bool isVerified,
    required String rating,
    required String reviews,
    required String location,
    required List<String> skills,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(ctx),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              CircleAvatar(
                radius: 38,
                backgroundColor: const Color(0xFFE7EDF8),
                backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                child: profilePic.isEmpty ? const Icon(Icons.person, color: Color(0xFF1976D2), size: 38) : null,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  if (isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF1976D2)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(5, (index) => const Icon(Icons.star, size: 14, color: Colors.orange)),
                  const SizedBox(width: 6),
                  Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                  const SizedBox(width: 4),
                  Text('($reviews reviews)', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('SKILLS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map((s) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF), 
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s, style: const TextStyle(fontSize: 11, color: Color(0xFF5C6BC0), fontWeight: FontWeight.w600)),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
          title: const Text("View Applications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          bottom: const TabBar(
            indicatorColor: Colors.white, indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
            tabs: [Tab(text: "Pending"), Tab(text: "Accepted")],
          ),
        ),
        body: TabBarView(
          children: [
            _buildApplicationsStream(context, 'pending'),
            _buildApplicationsStream(context, 'accepted'),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsStream(BuildContext context, String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('applications').where('taskId', isEqualTo: taskId).where('status', isEqualTo: status).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
        if (snapshot.hasError) return Center(child: Text("Unable to load applications.\n\n${snapshot.error}"));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text(status == 'pending' ? "No pending applications found." : "No accepted applicants yet.", style: const TextStyle(color: Colors.grey, fontSize: 15)));
        }

        final applications = snapshot.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: applications.map((document) {
            final data = document.data() as Map<String, dynamic>;

            final String name = data['workerName']?.toString() ?? 'Unknown Worker';
            final String workerId = data['workerId']?.toString() ?? '';
            final String price = data['proposedPrice'] != null ? 'R${data['proposedPrice']}' : 'No bid';
            final String location = data['workerLocation']?.toString() ?? 'Location unavailable';
            final String description = data['message']?.toString() ?? 'No application message provided.';
            
            final List<String> skills = data['skills'] != null ? List<String>.from(data['skills']) : ["No specific skills listed"];
            String applied = 'Recently';
            if (data['appliedAt'] is Timestamp) {
              final date = (data['appliedAt'] as Timestamp).toDate();
              applied = '${date.day}/${date.month}/${date.year}';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('reviews').where('reviewedUserId', isEqualTo: workerId).snapshots(),
                builder: (context, reviewSnap) {
                  double avgRating = 0.0;
                  int totalReviews = 0;
                  if (reviewSnap.hasData && reviewSnap.data!.docs.isNotEmpty) {
                    totalReviews = reviewSnap.data!.docs.length;
                    double sum = 0.0;
                    for (var doc in reviewSnap.data!.docs) {
                      final rData = doc.data() as Map<String, dynamic>;
                      sum += (rData['rating'] as num?)?.toDouble() ?? 0.0;
                    }
                    avgRating = sum / totalReviews;
                  }

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('Users').doc(workerId).get(),
                    builder: (context, userSnap) {
                      bool isVerified = false;
                      String profilePic = '';
                      List<String> userProfileSkills = skills; 

                      if (userSnap.hasData && userSnap.data!.exists) {
                        final uData = userSnap.data!.data() as Map<String, dynamic>;
                        isVerified = uData['isVerified'] == true;
                        profilePic = uData['profileImageUrl'] ?? '';
                        
                        // Fetches live skills directly from the user's database entry
                        if (uData['skills'] != null && uData['skills'].toString().isNotEmpty) {
                          userProfileSkills = uData['skills'].toString().split(',').map((e) => e.trim()).toList();
                        }
                      }

                      return ApplicationCard(
                        name: name, 
                        rating: avgRating.toStringAsFixed(1), 
                        reviews: totalReviews.toString(), 
                        distance: location,
                        price: price, 
                        applied: applied, 
                        description: description, 
                        skills: skills,
                        isAccepted: status == 'accepted', 
                        isVerified: isVerified,
                        profilePic: profilePic,
                        onViewProfile: () {
                          // Triggers popup with real live data
                          _showProfileDialog(
                            context,
                            name: name,
                            profilePic: profilePic,
                            isVerified: isVerified,
                            rating: avgRating.toStringAsFixed(1),
                            reviews: totalReviews.toString(),
                            location: location,
                            skills: userProfileSkills,
                          );
                        },
                        onRate: () async {
                           String taskTitle = 'Task';
                           String taskCategory = 'General';
                           final taskDoc = await FirebaseFirestore.instance.collection('Tasks').doc(taskId).get();
                           if (taskDoc.exists && taskDoc.data() != null) {
                             taskTitle = taskDoc.data()!['title'] ?? 'Task';
                             taskCategory = taskDoc.data()!['category'] ?? 'General';
                           }

                           if (context.mounted) {
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (context) => ReviewScreen(
                                   taskId: taskId,
                                   reviewedUserId: workerId,
                                   reviewedUserName: name,
                                   taskTitle: taskTitle,
                                   taskCategory: taskCategory,
                                   taskPayment: price,
                                 ),
                               ),
                             );
                           }
                        },
                        onReject: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Reject Application?'),
                              content: Text('Are you sure you want to reject $name\'s application?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  onPressed: () { Navigator.pop(dialogContext); _updateApplicationStatus(document.id, 'rejected', context, name); },
                                  child: const Text('Reject'),
                                ),
                              ],
                            ),
                          );
                        },
                        onAccept: () async {
                          await _updateApplicationStatus(document.id, 'accepted', context, name);
                        },
                      );
                    }
                  );
                }
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _updateApplicationStatus(String documentId, String status, BuildContext context, String workerName) async {
    try {
      await FirebaseFirestore.instance.collection('applications').doc(documentId).update({'status': status});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(status == 'accepted' ? "$workerName's application accepted" : "$workerName's application rejected")));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not update application: $e")));
    }
  }
}

class ApplicationCard extends StatelessWidget {
  final String name;
  final String rating;
  final String reviews;
  final String distance;
  final String price;
  final String applied;
  final String description;
  final List<String> skills;
  final bool isAccepted;
  final bool isVerified;
  final String profilePic;
  final VoidCallback onViewProfile;
  final VoidCallback onRate;
  final VoidCallback onReject;
  final VoidCallback onAccept;

  const ApplicationCard({
    super.key, required this.name, required this.rating, required this.reviews, required this.distance, required this.price,
    required this.applied, required this.description, required this.skills, required this.isAccepted, required this.isVerified,
    required this.profilePic, required this.onViewProfile, required this.onRate, required this.onReject, required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22, 
                backgroundColor: const Color(0xFFE7EDF8), 
                backgroundImage: profilePic.isNotEmpty ? NetworkImage(profilePic) : null,
                child: profilePic.isEmpty ? const Icon(Icons.person, color: Color(0xFF1976D2)) : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), 
                        if (isVerified) ...[
                          const SizedBox(width: 4), 
                          const Icon(Icons.verified, size: 14, color: Color(0xFF1976D2)),
                        ],
                      ]
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 13, color: Colors.orange), const SizedBox(width: 3),
                        Text("$rating ($reviews)", style: const TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey), const SizedBox(width: 2),
                        Expanded(child: Text(distance, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6, runSpacing: 5,
            children: skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFF1F4F8), borderRadius: BorderRadius.circular(5)),
                child: Text(skill, style: const TextStyle(fontSize: 9, color: Colors.black87)),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Text('"$description"', style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.4)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(color: const Color(0xFFF7F9FC), borderRadius: BorderRadius.circular(7)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Proposed Bid", style: TextStyle(fontSize: 9, color: Colors.grey)), const SizedBox(height: 2), Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green))]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("Applied", style: TextStyle(fontSize: 9, color: Colors.grey)), const SizedBox(height: 2), Text(applied, style: const TextStyle(fontSize: 9, color: Colors.black87))]),
              ],
            ),
          ),
          const SizedBox(height: 14), 
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewProfile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1976D2), 
                    side: const BorderSide(color: Color(0xFF1976D2)), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 0),
                  ),
                  child: const Text("View Profile", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 6),
              
              ...isAccepted
                  ? [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onRate,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)), padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 0),
                          ),
                          child: const Text("Rate", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {}, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)), padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 0),
                          ),
                          child: const Text("Message", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1),
                        ),
                      ),
                    ]
                  : [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)), padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 0),
                          ),
                          child: const Text("Reject", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF12B981), foregroundColor: Colors.white, elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)), padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 0),
                          ),
                          child: const Text("Accept", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1),
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
