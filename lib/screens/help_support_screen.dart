import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const Color _blue = Color(0xFF1976D2);
  static const Color _lightBlue = Color(0xFFE3F2FD);

  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;

  // Which FAQ is expanded
  int? _expandedFaq;

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How do I apply for a task?',
      'a':
          'Browse tasks in the Explore tab, tap on one that interests you, then press "Apply". The task poster will be notified and can accept or decline your application.',
    },
    {
      'q': 'How do I post a task?',
      'a':
          'Tap the "+" button on your dashboard and fill in the task details — title, description, location, category, and budget. Once submitted, workers in your area can see and apply for it.',
    },
    {
      'q': 'How do payments work?',
      'a':
          'TaskSurf facilitates connections between task posters and workers. Payment arrangements are agreed between parties directly. Always confirm payment terms before starting any task.',
    },
    {
      'q': 'How do I get verified?',
      'a':
          'Go to Profile → Verify Profile and upload a clear photo of your government-issued ID. Our team reviews submissions within 1–3 business days and awards a blue verified tick upon approval.',
    },
    {
      'q': 'What if I have a dispute with another user?',
      'a':
          'Use the Report button on any task or user profile to flag the issue. Our admin team reviews all reports and will take appropriate action within 48 hours.',
    },
    {
      'q': 'How do I delete my account?',
      'a':
          'Go to Profile → Settings → Account Actions → Delete Account. This action is permanent and cannot be undone.',
    },
  ];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both subject and message.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('supportTickets').add({
        'userId': user?.uid ?? '',
        'userEmail': user?.email ?? '',
        'subject': subject,
        'message': message,
        'status': 'open',
        'submittedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      _subjectCtrl.clear();
      _messageCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your ticket has been submitted. We\'ll get back to you soon!'),
          backgroundColor: Color(0xFF1976D2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit ticket: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: _blue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero card ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'How can we help?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Browse our FAQs or send us a message below.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Quick contact chips ────────────────────────────────────
            _sectionLabel('QUICK CONTACT'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _contactChip(
                    icon: Icons.email_outlined,
                    label: 'Email Us',
                    sub: 'support@tasksurf.app',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _contactChip(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Live Chat',
                    sub: 'Mon–Fri, 9am–5pm',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── FAQs ──────────────────────────────────────────────────
            _sectionLabel('FREQUENTLY ASKED QUESTIONS'),
            const SizedBox(height: 12),
            _card(
              child: Column(
                children: List.generate(_faqs.length, (i) {
                  final isExpanded = _expandedFaq == i;
                  final faq = _faqs[i];
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => setState(() => _expandedFaq = isExpanded ? null : i),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  faq['q']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isExpanded ? _blue : const Color(0xFF1A1A1A),
                                  ),
                                ),
                              ),
                              Icon(
                                isExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: isExpanded ? _blue : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isExpanded)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _lightBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            faq['a']!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A1A1A),
                              height: 1.5,
                            ),
                          ),
                        ),
                      if (i < _faqs.length - 1)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }),
              ),
            ),

            const SizedBox(height: 28),

            // ── Submit a ticket ───────────────────────────────────────
            _sectionLabel('SUBMIT A SUPPORT TICKET'),
            const SizedBox(height: 12),
            _card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Can\'t find your answer? Send us a message and we\'ll respond within 24 hours.',
                      style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _subjectCtrl,
                      decoration: InputDecoration(
                        labelText: 'Subject',
                        hintText: 'e.g. Payment issue, Account problem…',
                        filled: true,
                        fillColor: _lightBlue,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.subject_rounded, color: _blue),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _messageCtrl,
                      minLines: 4,
                      maxLines: 7,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        hintText: 'Describe your issue in detail…',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: _lightBlue,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 64),
                          child: Icon(Icons.message_rounded, color: _blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sending ? null : _submitTicket,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(_sending ? 'Sending…' : 'Submit Ticket'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: Color(0xFF1976D2),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _contactChip({
    required IconData icon,
    required String label,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _blue, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
