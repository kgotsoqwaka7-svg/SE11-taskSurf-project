import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'application_profile_screen.dart';

class ViewApplicationsScreen extends StatelessWidget {
  const ViewApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("View Applications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)));
          }

          if (snapshot.hasError) {
            return Center(child: Text("Unable to load applications.\n\n${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No pending applications found.", style: TextStyle(color: Colors.grey, fontSize: 15)),
            );
          }

          final applications = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...applications.map((document) {
                final data = document.data() as Map<String, dynamic>;

                final String name = data['workerName']?.toString() ?? 'Unknown Worker';
                final String rating = data['workerRating']?.toString() ?? '0.0';
                final String reviews = data['reviewCount']?.toString() ?? '0'; // Dynamic reviews
                final String price = data['proposedPrice'] != null ? 'R${data['proposedPrice']}' : 'No bid';
                final String location = data['workerLocation']?.toString() ?? 'Location unavailable';
                final String description = data['message']?.toString() ?? 'No application message provided.';
                
                // Fetch dynamic skills if they exist, otherwise default text
                final List<String> skills = data['skills'] != null 
                    ? List<String>.from(data['skills']) 
                    : ["No specific skills listed"];

                String applied = 'Recently';
                if (data['appliedAt'] is Timestamp) {
                  final date = (data['appliedAt'] as Timestamp).toDate();
                  applied = '${date.day}/${date.month}/${date.year}';
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ApplicationCard(
                    name: name,
                    rating: rating,
                    reviews: reviews,
                    distance: location,
                    price: price,
                    applied: applied,
                    description: description,
                    skills: skills,
                    onViewProfile: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ApplicantProfileScreen(applicantData: data),
                        ),
                      );
                    },
                    onReject: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Reject Application?'),
                          content: Text('Are you sure you want to reject $name\'s application?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _updateApplicationStatus(document.id, 'rejected', context, name);
                              },
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      );
                    },
                    onAccept: () async {
                      await _updateApplicationStatus(document.id, 'accepted', context, name);
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateApplicationStatus(String documentId, String status, BuildContext context, String workerName) async {
    try {
      await FirebaseFirestore.instance.collection('applications').doc(documentId).update({'status': status});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(status == 'accepted' ? "$workerName's application accepted" : "$workerName's application rejected")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not update application: $e")));
      }
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
  final VoidCallback onViewProfile;
  final VoidCallback onReject;
  final VoidCallback onAccept;

  const ApplicationCard({
    super.key,
    required this.name,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.price,
    required this.applied,
    required this.description,
    required this.skills,
    required this.onViewProfile,
    required this.onReject,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFE7EDF8),
                child: Icon(Icons.person, color: Color(0xFF1976D2)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 14, color: Color(0xFF1976D2)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 13, color: Colors.orange),
                        const SizedBox(width: 3),
                        Text("$rating ($reviews)", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
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
            spacing: 6,
            runSpacing: 5,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Proposed Bid", style: TextStyle(fontSize: 9, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Applied", style: TextStyle(fontSize: 9, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(applied, style: const TextStyle(fontSize: 9, color: Colors.black87)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red, side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)), padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: const Text("Reject", style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewProfile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1976D2), side: const BorderSide(color: Color(0xFF1976D2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)), padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: const Text("View Profile", style: TextStyle(fontSize: 11)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12B981), foregroundColor: Colors.white, elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)), padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: const Text("Accept", style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}