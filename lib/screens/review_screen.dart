import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int selectedRating = 0;

  final TextEditingController reviewController =
      TextEditingController();

  bool recommendWorker = true;

  final List<String> positiveTags = [
    "Reliable",
    "Professional",
    "Friendly",
    "On Time",
    "Good Communication",
    "High Quality Work",
  ];

  final Set<String> selectedTags = {};

  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  String get ratingText {
    switch (selectedRating) {
      case 1:
        return "Poor - 1 Star";
      case 2:
        return "Fair - 2 Stars";
      case 3:
        return "Good - 3 Stars";
      case 4:
        return "Very Good - 4 Stars";
      case 5:
        return "Outstanding - 5 Stars";
      default:
        return "Select a rating";
    }
  }

  // ============================================================
  // SUBMIT REVIEW TO FIRESTORE
  // ============================================================

  Future<void> submitReview() async {
    if (selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a rating first."),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'reviewId':
            'review_${DateTime.now().millisecondsSinceEpoch}',
        'taskId': 'sample_task_001',
        'reviewerId': 'sample_provider_001',
        'reviewedUserId':
            'lQe4Z4QWyEg8eXlbnzaJ6FyIm3U2',
        'rating': selectedRating,
        'comment': reviewController.text.trim(),
        'tags': selectedTags.toList(),
        'recommend': recommendWorker,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Review submitted successfully!",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Failed to submit review: $e",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      // ============================================================
      // TOP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor: const Color(0xFF2864D7),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Leave Review",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ============================================================
      // PAGE CONTENT
      // ============================================================

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // --------------------------------------------------------
          // SUCCESS MESSAGE
          // --------------------------------------------------------

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F8EF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.shade300,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Review Submitted Successfully",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // COMPLETED TASK
          // --------------------------------------------------------

          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1FF),
                        borderRadius:
                            BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.grid_view_rounded,
                        size: 15,
                        color: Color(0xFF2864D7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "Gardening & Lawn Mowing",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F8EF),
                        borderRadius:
                            BorderRadius.circular(5),
                      ),
                      child: const Text(
                        "COMPLETED",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Date",
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Oct 24, 2023",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Location",
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Johannesburg Alberton",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Agreed Payment",
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "R180.00",
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2864D7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // WORKER PROFILE
          // --------------------------------------------------------

          _buildCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 23,
                  backgroundColor: Color(0xFFE5EBF7),
                  child: Icon(
                    Icons.person,
                    color: Color(0xFF2864D7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Text(
                            "Dave Harrison",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: 13,
                            color: Color(0xFF2864D7),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 3),
                          Text(
                            "4.9",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 3),
                          Text(
                            "(18 reviews)",
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // RATING
          // --------------------------------------------------------

          _buildCard(
            child: Column(
              children: [
                const Text(
                  "How would you rate Dave's work?",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) {
                      final starNumber = index + 1;

                      return IconButton(
                        onPressed: () {
                          setState(() {
                            selectedRating = starNumber;
                          });
                        },
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 3,
                        ),
                        constraints:
                            const BoxConstraints(),
                        icon: Icon(
                          starNumber <= selectedRating
                              ? Icons.star
                              : Icons.star_border,
                          size: 30,
                          color: Colors.orange,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  ratingText,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // WHAT WENT WELL
          // --------------------------------------------------------

          _buildCard(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select what went well",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 9),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: positiveTags.map(
                    (tag) {
                      final selected =
                          selectedTags.contains(tag);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (selected) {
                              selectedTags.remove(tag);
                            } else {
                              selectedTags.add(tag);
                            }
                          });
                        },
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFEAF1FF)
                                : Colors.white,
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF2864D7)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 8,
                              color: selected
                                  ? const Color(0xFF2864D7)
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // REVIEW TEXT
          // --------------------------------------------------------

          _buildCard(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  "Write your review",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                TextField(
                  controller: reviewController,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText:
                        "Share your experience working with this person...",
                    hintStyle: const TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF2864D7),
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: Color(0xFF2864D7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // RECOMMEND WORKER
          // --------------------------------------------------------

          _buildCard(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Would you hire this worker again?",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        "Your response helps us rank top helpers",
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: recommendWorker,
                  activeColor:
                      const Color(0xFF2864D7),
                  onChanged: (value) {
                    setState(() {
                      recommendWorker = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // --------------------------------------------------------
          // SUBMIT BUTTON
          // --------------------------------------------------------

          SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF2864D7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "Submit Review",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ],
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        selectedItemColor:
            const Color(0xFF2864D7),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 9,
        unselectedFontSize: 9,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: "My Tasks",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Messages",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // REUSABLE CARD
  // ==============================================================

  Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}