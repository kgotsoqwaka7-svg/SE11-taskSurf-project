import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'applicantion_profile_screen.dart';

class ViewApplicationsScreen extends StatelessWidget {
  const ViewApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

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
          "View Applications",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('applications')
            .where('status', isEqualTo: 'pending')
            .snapshots(),

        builder: (context, snapshot) {
          // ------------------------------------------------------------
          // LOADING
          // ------------------------------------------------------------

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ------------------------------------------------------------
          // ERROR
          // ------------------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Unable to load applications.\n\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }

          // ------------------------------------------------------------
          // NO APPLICATIONS
          // ------------------------------------------------------------

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "No pending applications found.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),
              ),
            );
          }

          final applications = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ----------------------------------------------------------
              // ACTIVE TASK CARD
              // ----------------------------------------------------------

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "ACTIVE TASK",
                          style: TextStyle(
                            color: Color(0xFF2864D7),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "R250",
                            style: TextStyle(
                              color: Color(0xFF2864D7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Garden Renovation &\nOrganic Planting",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: const [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 3),
                        Text(
                          "Germiston",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),

                        SizedBox(width: 16),

                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Posted 2d ago",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),

                        SizedBox(width: 16),

                        Icon(
                          Icons.people_outline,
                          size: 14,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Applicants",
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF2864D7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ----------------------------------------------------------
              // FILTER BUTTONS
              // ----------------------------------------------------------

              Row(
                children: [
                  _FilterButton(
                    text: "Newest",
                    selected: true,
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    text: "Rating",
                    selected: false,
                  ),
                  const SizedBox(width: 8),
                  _FilterButton(
                    text: "Distance",
                    selected: false,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ----------------------------------------------------------
              // FIRESTORE APPLICATIONS
              // ----------------------------------------------------------

              ...applications.map((document) {
                final data =
                    document.data() as Map<String, dynamic>;

                final String name =
                    data['workerName']?.toString() ??
                        'Unknown Worker';

                final String rating =
                    data['workerRating']?.toString() ?? '0.0';

                final String price =
                    data['proposedPrice'] != null
                        ? 'R${data['proposedPrice']}'
                        : 'No bid';

                final String location =
                    data['workerLocation']?.toString() ??
                        'Location unavailable';

                final String description =
                    data['message']?.toString() ??
                        'No application message provided.';

                final String status =
                    data['status']?.toString() ?? 'pending';

                String applied = 'Recently';

                if (data['appliedAt'] is Timestamp) {
                  final timestamp =
                      data['appliedAt'] as Timestamp;

                  final date = timestamp.toDate();

                  applied =
                      '${date.day}/${date.month}/${date.year}';
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ApplicationCard(
                    name: name,
                    rating: rating,
                    reviews: "0",
                    distance: location,
                    price: price,
                    applied: applied,
                    description: description,
                    skills: const [
                      "General Labour",
                    ],
                    onViewProfile: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ApplicantProfileScreen(applicantData: data,),
                        ),
                      );
                    },
                    onReject: ()  {
                     showDialog(
                     context: context,
                     builder: (dialogContext) {
                     return AlertDialog(
                        title: const Text('Reject Application?'),
                      content: Text(
                          'Are you sure you want to reject $name\'s application?',
                       ),
                     actions: [
                      TextButton(
                       onPressed: () {
                        Navigator.pop(dialogContext);
                       },
                       child: const Text('Cancel'),
                     ),
                     ElevatedButton(
                      onPressed: () {
                       Navigator.pop(dialogContext);

                      _updateApplicationStatus(
                        document.id,
                       'rejected',
                       context,
                       name,
                    );
                  },
                  child: const Text('Reject'),
                ),
              ],
            );
           },
          );
                    },
                    onAccept: () async {
                      await _updateApplicationStatus(
                        document.id,
                        'accepted',
                        context,
                        name,
                      );
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),

      // ------------------------------------------------------------
      // BOTTOM NAVIGATION
      // ------------------------------------------------------------

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2864D7),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: "Browse",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: "Tasks",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: "Applications",
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

  // ------------------------------------------------------------
  // UPDATE APPLICATION STATUS
  // ------------------------------------------------------------

  Future<void> _updateApplicationStatus(
    String documentId,
    String status,
    BuildContext context,
    String workerName,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(documentId)
          .update({
        'status': status,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'accepted'
                  ? "$workerName's application accepted"
                  : "$workerName's application rejected",
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Could not update application: $e",
            ),
          ),
        );
      }
    }
  }
}

// ==================================================================
// FILTER BUTTON
// ==================================================================

class _FilterButton extends StatelessWidget {
  final String text;
  final bool selected;

  const _FilterButton({
    required this.text,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFF2864D7)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? const Color(0xFF2864D7)
              : const Color(0xFFE0E0E0),
        ),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color:
                  selected ? Colors.white : Colors.black87,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (selected) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: Colors.white,
            ),
          ],
        ],
      ),
    );
  }
}

// ==================================================================
// APPLICATION CARD
// ==================================================================

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------------
          // APPLICANT HEADER
          // --------------------------------------------------------

          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFE7EDF8),
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
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 4),

                        const Icon(
                          Icons.verified,
                          size: 14,
                          color: Color(0xFF2864D7),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 13,
                          color: Colors.orange,
                        ),

                        const SizedBox(width: 3),

                        Text(
                          "$rating ($reviews)",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(width: 8),

                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 2),

                        Expanded(
                          child: Text(
                            distance,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // SKILLS
          // --------------------------------------------------------

          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: skills.map((skill) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F8),
                  borderRadius:
                      BorderRadius.circular(5),
                ),
                child: Text(
                  skill,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.black87,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // DESCRIPTION
          // --------------------------------------------------------

          Text(
            '"$description"',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // --------------------------------------------------------
          // BID INFORMATION
          // --------------------------------------------------------

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius:
                  BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Proposed Bid",
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Applied",
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      applied,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // ACTION BUTTONS
          // --------------------------------------------------------

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(
                      color: Colors.red,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(7),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 11,
                    ),
                  ),
                  child: const Text(
                    "Reject",
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: OutlinedButton(
                  onPressed: onViewProfile,
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color(0xFF2864D7),
                    side: const BorderSide(
                      color: Color(0xFF2864D7),
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(7),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 11,
                    ),
                  ),
                  child: const Text(
                    "View Profile",
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF12B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(7),
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 11,
                    ),
                  ),
                  child: const Text(
                    "Accept",
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
