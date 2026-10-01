import 'package:flutter/material.dart';

class ApplicantProfileScreen extends StatelessWidget {
  final Map<String, dynamic> applicantData;

  const ApplicantProfileScreen({
    super.key,
    required this.applicantData,
  });

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // APPLICATION DATA
    // ============================================================

    final String fullName =
        applicantData['workerName']?.toString() ?? 'Unknown User';

    final String area =
        applicantData['workerLocation']?.toString() ??
            'Location unavailable';

    final String rating =
        applicantData['workerRating']?.toString() ?? '0.0';

    final String message =
        applicantData['message']?.toString() ?? '';

    final String proposedPrice =
        applicantData['proposedPrice']?.toString() ?? '';

    // ============================================================
    // MAIN PROFILE SCREEN
    // ============================================================

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),

      // ============================================================
      // TOP APP BAR
      // ============================================================

      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          "Applicant Profile",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
      ),

      // ============================================================
      // PROFILE CONTENT
      // ============================================================

      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [

          // --------------------------------------------------------
          // PROFILE HEADER
          // --------------------------------------------------------

          _buildCard(
            child: Column(
              children: [

                Row(
                  children: [

                    const CircleAvatar(
                      radius: 31,
                      backgroundColor: Color(0xFFE5EBF7),
                      child: Icon(
                        Icons.person,
                        size: 35,
                        color: Color(0xFF1976D2),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Row(
                            children: [

                              Expanded(
                                child: Text(
                                  fullName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              const SizedBox(width: 4),

                              const Icon(
                                Icons.verified,
                                size: 14,
                                color: Color(0xFF1976D2),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Row(
                            children: [

                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFE6F8EF),
                                  borderRadius:
                                      BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  "Available Now",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 6),

                              const Text(
                                "• Verified User",
                                style: TextStyle(
                                  fontSize: 9,
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

                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [

                    Row(
                      children: [

                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.orange,
                        ),

                        const SizedBox(width: 3),

                        Text(
                          rating,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(width: 3),

                        const Text(
                          "(8 reviews)",
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [

                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Colors.grey,
                        ),

                        const SizedBox(width: 3),

                        Text(
                          area,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
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
          // APPLICATION DETAILS
          // --------------------------------------------------------

          _buildCard(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Text(
                  "Application Details",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                if (message.isNotEmpty) ...[
                  const Text(
                    "Message",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ],

                if (proposedPrice.isNotEmpty) ...[
                  const SizedBox(height: 12),

                  const Text(
                    "Proposed Price",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "R$proposedPrice",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // STATISTICS
          // --------------------------------------------------------

          Row(
            children: [

              const Expanded(
                child: _StatCard(
                  value: "24",
                  label: "Completed",
                ),
              ),

              const SizedBox(width: 8),

              const Expanded(
                child: _StatCard(
                  value: "100%",
                  label: "Success Rate",
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: _StatCard(
                  value: rating,
                  label: "Avg Rating",
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // ABOUT ME
          // --------------------------------------------------------

          _buildCard(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Text(
                  "About Me",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  message.isNotEmpty
                      ? message
                      : "This applicant is registered on TaskSurf "
                          "and is available for local tasks.",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                const Divider(),

                const SizedBox(height: 8),

                const Text(
                  "SKILLS & EXPERTISE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    _SkillChip(text: "Gardening"),
                    _SkillChip(text: "Cleaning"),
                    _SkillChip(text: "General Labour"),
                    _SkillChip(text: "Painting"),
                    _SkillChip(text: "Deliveries"),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // PORTFOLIO
          // --------------------------------------------------------

          _buildCard(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Text(
                  "Recent Work Portfolio",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [

                    const Expanded(
                      child: _PortfolioBox(
                        icon: Icons.grass,
                        label: "BEFORE",
                      ),
                    ),

                    const SizedBox(width: 8),

                    const Expanded(
                      child: _PortfolioBox(
                        icon: Icons.yard,
                        label: "AFTER",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // WORK EXPERIENCE
          // --------------------------------------------------------

          _buildCard(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Text(
                  "Work Experience",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const _ExperienceItem(
                  title: "Lead Landscaper",
                  company: "GreenThumb Gardens & Co.",
                  years: "2021 - Present",
                  description:
                      "Supervised complex planting schemes, "
                      "irrigation setup, and heavy yard clearing.",
                ),

                const SizedBox(height: 12),

                const _ExperienceItem(
                  title: "Gardener Assistant",
                  company:
                      "Downtown Botanical Services",
                  years: "2019 - 2021",
                  description:
                      "Maintained public flowerbeds, managed lawn "
                      "watering, and supported landscaping projects.",
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --------------------------------------------------------
          // RECENT REVIEWS
          // --------------------------------------------------------

          _buildCard(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const Text(
                  "Recent Reviews (8)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [

                    const CircleAvatar(
                      radius: 17,
                      backgroundColor: Color(0xFFE5EBF7),
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: Color(0xFF1976D2),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [

                              const Text(
                                "Marcus Aurel",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Row(
                                children: const [

                                  Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Colors.orange,
                                  ),

                                  Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Colors.orange,
                                  ),

                                  Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Colors.orange,
                                  ),

                                  Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Colors.orange,
                                  ),

                                  Icon(
                                    Icons.star,
                                    size: 10,
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            "Great work and very professional. "
                            "The task was completed successfully.",
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 90),
        ],
      ),

      // ============================================================
      // BOTTOM ACTION BUTTONS
      // ============================================================

      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(
          12,
          10,
          12,
          10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [

            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content:
                          Text("Application rejected"),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Colors.red,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  "Reject",
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),

            const SizedBox(width: 7),

            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Message feature coming soon",
                      ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(0xFF1976D2),
                  side: const BorderSide(
                    color: Color(0xFF1976D2),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(7),
                  ),
                ),
                child: const Text(
                  "Message",
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),

            const SizedBox(width: 7),

            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content:
                          Text("Application accepted"),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF12B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(7),
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
      ),

      // ============================================================
      // BOTTOM NAVIGATION
      // ============================================================

      bottomNavigationBar:
          BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor:
            const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 9,
        unselectedFontSize: 9,
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

  // ==============================================================
  // CARD BUILDER
  // ==============================================================

  static Widget _buildCard({
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.05),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ==================================================================
// STAT CARD
// ==================================================================

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.04),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [

          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 8,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================================
// SKILL CHIP
// ==================================================================

class _SkillChip extends StatelessWidget {
  final String text;

  const _SkillChip({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5FF),
        borderRadius:
            BorderRadius.circular(5),
        border: Border.all(
          color: const Color(0xFFD7E4FF),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          color: Color(0xFF1976D2),
        ),
      ),
    );
  }
}

// ==================================================================
// PORTFOLIO BOX
// ==================================================================

class _PortfolioBox extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PortfolioBox({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        Container(
          height: 80,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EDF2),
            borderRadius:
                BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 35,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          label,
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.bold,
            color: label == "BEFORE"
                ? Colors.red
                : Colors.green,
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// WORK EXPERIENCE
// ==================================================================

class _ExperienceItem extends StatelessWidget {
  final String title;
  final String company;
  final String years;
  final String description;

  const _ExperienceItem({
    required this.title,
    required this.company,
    required this.years,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Container(
          width: 7,
          height: 7,
          margin:
              const EdgeInsets.only(top: 4),
          decoration: const BoxDecoration(
            color: Color(0xFF1976D2),
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [

                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  Text(
                    years,
                    style: const TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 3),

              Text(
                company,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                description,
                style: const TextStyle(
                  fontSize: 8,
                  color: Colors.grey,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}