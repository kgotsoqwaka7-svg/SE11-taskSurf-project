import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const Color _blue = Color(0xFF1976D2);
  static const Color _lightBlue = Color(0xFFE3F2FD);

  XFile? _selectedDocument; // Changed to XFile to support Web and Mobile
  bool _submitting = false;
  Map<String, dynamic>? _existingRequest;
  bool _loadingStatus = true;

  @override
  void initState() {
    super.initState();
    _loadExistingRequest();
  }

  Future<void> _loadExistingRequest() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _loadingStatus = false);
        return;
      }
      final snap = await FirebaseFirestore.instance
          .collection('verificationRequests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('submittedAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        setState(() {
          _existingRequest = snap.docs.first.data();
          _loadingStatus = false;
        });
      } else {
        setState(() => _loadingStatus = false);
      }
    } catch (e) {
      debugPrint('Error loading verification request: $e');
      setState(() => _loadingStatus = false);
    }
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800, // Reduced to ensure small size
      maxHeight: 800,
      imageQuality: 30, // Highly compressed to fit under 1MB Firestore limit
    );
    if (picked != null) {
      setState(() => _selectedDocument = picked); 
    }
  }

  Future<void> _submitVerification() async {
    if (_selectedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your ID document first.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Convert the image to bytes
      final bytes = await _selectedDocument!.readAsBytes();
      
      // 2. Check if the image is larger than ~900KB to be safe against Firestore's 1MB limit
      if (bytes.length > 900000) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image is too large. Please select a smaller photo.')),
        );
        setState(() => _submitting = false);
        return;
      }

      // 3. Convert to Base64 Text String
      final base64String = base64Encode(bytes);

      // 4. Save directly to Firestore (Bypassing Firebase Storage)
      final request = FirebaseFirestore.instance.collection('verificationRequests').doc();
      
      await request.set({
        'userId': user.uid,
        'userEmail': user.email ?? '',
        'documentData': base64String, // Saved as text data instead of a URL
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        _existingRequest = {'status': 'pending'};
        _selectedDocument = null;
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification request submitted! We\'ll review it within 1–3 business days.'),
          backgroundColor: _blue,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit: $e')),
      );
      setState(() => _submitting = false);
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
        title: const Text('Verify Your Profile', style: TextStyle(color: Colors.white)),
      ),
      body: _loadingStatus
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header card ──────────────────────────────────────
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
                                'Get Verified',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Upload your ID document to earn a blue verified tick on your profile.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                  height: 1.4,
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
                          child: const Icon(Icons.verified_rounded, color: Colors.white, size: 36),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Status banner (if request exists) ─────────────────
                  if (_existingRequest != null) ...[
                    _buildStatusBanner(_existingRequest!['status'] as String),
                    const SizedBox(height: 24),
                  ],

                  // ── Benefits ──────────────────────────────────────────
                  _sectionLabel('BENEFITS OF VERIFICATION'),
                  const SizedBox(height: 12),
                  _card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _benefitRow(Icons.verified_rounded, 'Blue Verified Tick',
                              'Displayed on your profile and task applications'),
                          const Divider(height: 20),
                          _benefitRow(Icons.trending_up_rounded, 'Higher Visibility',
                              'Verified users appear higher in search results'),
                          const Divider(height: 20),
                          _benefitRow(Icons.shield_rounded, 'Build Trust',
                              'Task posters are more likely to hire verified workers'),
                          const Divider(height: 20),
                          _benefitRow(Icons.star_rounded, 'Priority Applications',
                              'Applications stand out to task posters'),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Upload form (only if not already pending/approved) ─
                  if (_existingRequest == null ||
                      _existingRequest!['status'] == 'rejected') ...[
                    _sectionLabel('UPLOAD YOUR ID DOCUMENT'),
                    const SizedBox(height: 12),
                    _card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Accepted documents',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            _docTypeRow(Icons.credit_card_rounded, 'National ID Card'),
                            _docTypeRow(Icons.book_rounded, 'Passport'),
                            _docTypeRow(Icons.directions_car_rounded, "Driver's Licence"),

                            const SizedBox(height: 16),

                            GestureDetector(
                              onTap: _pickDocument,
                              child: Container(
                                width: double.infinity,
                                height: 160,
                                decoration: BoxDecoration(
                                  color: _lightBlue,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _blue.withValues(alpha: 0.35),
                                    width: 1.5,
                                    strokeAlign: BorderSide.strokeAlignInside,
                                  ),
                                ),
                                child: _selectedDocument != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(13),
                                        child: kIsWeb 
                                            ? Image.network(
                                                _selectedDocument!.path,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.file(
                                                File(_selectedDocument!.path),
                                                fit: BoxFit.cover,
                                              ),
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.upload_file_rounded,
                                              color: _blue, size: 40),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Tap to select document',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: _blue),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Clear photo, well-lit, all corners visible',
                                            style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            if (_selectedDocument != null) ...[
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: _pickDocument,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Choose a different photo'),
                                style: TextButton.styleFrom(
                                  foregroundColor: _blue,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.lock_outline_rounded,
                                      color: Colors.amber, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Your document is stored securely and only used for verification purposes.',
                                      style: TextStyle(fontSize: 12, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _submitting ? null : _submitVerification,
                                icon: _submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded),
                                label: Text(_submitting
                                    ? 'Submitting…'
                                    : 'Submit for Verification'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _blue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color bg;
    Color fg;
    IconData icon;
    String title;
    String sub;

    switch (status) {
      case 'approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        icon = Icons.verified_rounded;
        title = 'You\'re Verified! 🎉';
        sub = 'Your blue verified tick is now visible on your profile.';
        break;
      case 'pending':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade700;
        icon = Icons.hourglass_top_rounded;
        title = 'Verification Pending';
        sub = 'We\'re reviewing your submission. This usually takes 1–3 business days.';
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        title = 'Verification Rejected';
        sub = 'Your document could not be verified. Please submit a clearer photo below.';
        break;
      default:
        bg = _lightBlue;
        fg = _blue;
        icon = Icons.info_outline_rounded;
        title = 'Status Unknown';
        sub = '';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: fg, fontSize: 14)),
                if (sub.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(sub,
                      style: TextStyle(color: fg.withValues(alpha: 0.8), fontSize: 12, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitRow(IconData icon, String title, String sub) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _blue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(sub,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _docTypeRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: _blue, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
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
        color: _blue,
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
}