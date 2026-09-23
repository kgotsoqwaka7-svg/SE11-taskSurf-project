import 'package:flutter/material.dart';
import '../services/authentication_service.dart';

class ViewApplicantsScreen extends StatefulWidget {
  const ViewApplicantsScreen({super.key});

  @override
  State<ViewApplicantsScreen> createState() => _ViewApplicantsScreenState();
}

class _ViewApplicantsScreenState extends State<ViewApplicantsScreen> {
  // Dummy data for the UI
  List<Map<String, dynamic>> applicants = [
    {
      'id': '1',
      'name': 'Amara Osei',
      'rating': 4.9,
      'reviews': 134,
      'location': 'Lagos, Nigeria',
      'isAvailable': true,
      'skills': ['Carpentry', 'Furniture Assembly', 'Painting'],
      'status': 'Accepted',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Task Applicants', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // TEMPORARY DATABASE TEST BUTTON
            // ==========================================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () async {
                  try {
                    await AuthenticationService().registerUser(
                      name: 'Kgotso Test',
                      email: 'kgotso.test@example.com',
                      password: 'password123',
                      role: 'Task Provider',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Success! Check Firebase.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('TEST DATABASE CONNECTION', style: TextStyle(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 24),

            // ==========================================
            // APPLICANT UI
            // ==========================================
            const Text('Pending Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: applicants.length,
              itemBuilder: (context, index) {
                var applicant = applicants[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade300,
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(applicant['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('${applicant['rating']} (${applicant['reviews']})'),
                            Text(applicant['location'], style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}