import 'package:flutter/material.dart';

class ApplicantProfileScreen extends StatelessWidget {
  final Map<String, dynamic> applicantData;

  const ApplicantProfileScreen({
    super.key,
    required this.applicantData,
  });

  @override
  Widget build(BuildContext context) {
    // Live data pulled directly from Firestore
    final String fullName = applicantData['workerName']?.toString() ?? 'Unknown User';
    final String area = applicantData['workerLocation']?.toString() ?? 'Location unavailable';
    final String rating = applicantData['workerRating']?.toString() ?? '0.0';
    final String message = applicantData['message']?.toString() ?? '';
    final String proposedPrice = applicantData['proposedPrice']?.toString() ?? '';
    
    // Dynamic stats (will default to 0 if not yet in database)
    final String completedTasks = applicantData['completedTasks']?.toString() ?? '0';
    final String reviewCount = applicantData['reviewCount']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Applicant Profile", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 31,
                      backgroundColor: Color(0xFFE5EBF7),
                      child: Icon(Icons.person, size: 35, color: Color(0xFF1976D2)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  fullName,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 14, color: Color(0xFF1976D2)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text("• Verified User", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.orange),
                        const SizedBox(width: 3),
                        Text(rating, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 3),
                        Text("($reviewCount reviews)", style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(area, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          if (message.isNotEmpty || proposedPrice.isNotEmpty)
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Application Details", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (message.isNotEmpty) ...[
                    const Text("Message", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text(message, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.5)),
                  ],
                  if (proposedPrice.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text("Proposed Price", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text("R$proposedPrice", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _StatCard(value: completedTasks, label: "Completed")),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(value: rating, label: "Avg Rating")),
            ],
          ),
          const SizedBox(height: 90),
        ],
      ),

      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                ),
                child: const Text("Close", style: TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Application accepted")));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                ),
                child: const Text("Accept", style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 7, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 5)],
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 8, color: Colors.grey)),
        ],
      ),
    );
  }
}