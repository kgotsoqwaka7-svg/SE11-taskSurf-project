import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewScreen extends StatefulWidget {
  final String taskId;
  final String reviewedUserId;
  final String reviewedUserName;
  final String taskTitle;
  final String? taskCategory;
  final String? taskPayment;

  const ReviewScreen({
    super.key,
    required this.taskId,
    required this.reviewedUserId,
    required this.reviewedUserName,
    required this.taskTitle,
    this.taskCategory,
    this.taskPayment,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int selectedRating = 0;
  final TextEditingController reviewController = TextEditingController();
  bool recommendWorker = true;
  bool _isSubmitting = false;

  final List<String> positiveTags = [
    "Reliable", "Professional", "Friendly",
    "On Time", "Good Communication", "High Quality Work",
  ];

  final Set<String> selectedTags = {};

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  String get ratingText {
    switch (selectedRating) {
      case 1: return "Poor - 1 Star";
      case 2: return "Fair - 2 Stars";
      case 3: return "Good - 3 Stars";
      case 4: return "Very Good - 4 Stars";
      case 5: return "Outstanding - 5 Stars";
      default: return "Select a rating";
    }
  }

  Future<void> submitReview() async {
    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rating first.")),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to leave a review.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'reviewId': 'review_${DateTime.now().millisecondsSinceEpoch}',
        'taskId': widget.taskId,
        'reviewerId': currentUser.uid,
        'reviewedUserId': widget.reviewedUserId,
        'rating': selectedRating.toDouble(),
        'comment': reviewController.text.trim(),
        'tags': selectedTags.toList(),
        'recommend': recommendWorker,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.green, content: Text("Review submitted successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: Colors.red, content: Text("Failed to submit review: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text("Leave Review", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Task Card Summary
          _buildCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.work_outline_rounded, color: Color(0xFF1976D2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.taskTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.taskCategory ?? 'General Task', style: const TextStyle(fontSize: 12, color: Color(0xFF1976D2), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (widget.taskPayment != null)
                  Text(widget.taskPayment!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // User Being Rated
          _buildCard(
            child: Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: Color(0xFFE5EBF7), child: Icon(Icons.person, color: Color(0xFF1976D2))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Rating for", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(widget.reviewedUserName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Rating Stars
          _buildCard(
            child: Column(
              children: [
                Text("How would you rate ${widget.reviewedUserName}?", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final starNumber = index + 1;
                    return IconButton(
                      onPressed: () => setState(() => selectedRating = starNumber),
                      icon: Icon(starNumber <= selectedRating ? Icons.star : Icons.star_border, size: 32, color: Colors.orange),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(ratingText, style: const TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Positive Tags
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Select highlights", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: positiveTags.map((tag) {
                    final selected = selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) selectedTags.remove(tag);
                          else selectedTags.add(tag);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFEAF1FF) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? const Color(0xFF1976D2) : Colors.grey.shade300),
                        ),
                        child: Text(tag, style: TextStyle(fontSize: 12, color: selected ? const Color(0xFF1976D2) : Colors.grey.shade700, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Written Review
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Write your review", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: reviewController, maxLines: 4, maxLength: 500,
                  decoration: InputDecoration(
                    hintText: "Share your experience...", hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1976D2))),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Recommend Toggle
          _buildCard(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Would you work with this user again?", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text("Helps improve community quality ratings", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                Switch(value: recommendWorker, activeColor: const Color(0xFF1976D2), onChanged: (val) => setState(() => recommendWorker = val)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Submit Button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
              ),
              child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text("Submit Review", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}