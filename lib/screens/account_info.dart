import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/authentication_service.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController(); // New
  final TextEditingController _skillsController = TextEditingController(); // New

  File? _selectedImage;
  String _existingImageUrl = '';
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  ImageProvider? _getProfileImageProvider(String url) {
    final clean = url.trim();
    if (clean.isEmpty || clean == 'null') return null;
    if (clean.startsWith('data:image')) {
      try {
        final base64String = clean.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (_) {
        return null;
      }
    }
    if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
      try {
        return MemoryImage(base64Decode(clean));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(clean);
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _emailController.text = data['email'] ?? user.email ?? '';
            _phoneController.text = data['phone'] ?? '';
            _locationController.text = data['location'] ?? '';
            _aboutController.text = data['aboutMe'] ?? ''; // Fetch bio
            _skillsController.text = data['skills'] ?? ''; // Fetch skills
            _existingImageUrl = (data['profileImageUrl'] ??
                    data['photoUrl'] ??
                    data['photoURL'] ??
                    data['profilePicture'] ??
                    data['profileImage'] ??
                    user.photoURL ??
                    '')
                .toString();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2), // Updated Team Color
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Edit Account', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage, 
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Builder(
                    builder: (context) {
                      final existingProvider = _getProfileImageProvider(_existingImageUrl);
                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFE3F2FD),
                        backgroundImage: _selectedImage != null 
                            ? FileImage(_selectedImage!) as ImageProvider
                            : existingProvider,
                        onBackgroundImageError: existingProvider != null
                            ? (exception, stackTrace) {
                                debugPrint('Error loading image: $exception');
                              }
                            : null,
                        child: (_selectedImage == null && existingProvider == null)
                            ? const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF1976D2),
                                size: 55,
                              )
                            : null,
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1976D2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()), readOnly: true),
            const SizedBox(height: 16),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(
              controller: _aboutController, 
              maxLines: 3, 
              decoration: const InputDecoration(labelText: 'About Me', border: OutlineInputBorder(), hintText: 'Write a short bio...')
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _skillsController, 
              decoration: const InputDecoration(labelText: 'Skills', border: OutlineInputBorder(), hintText: 'e.g. Cleaning, Painting, Carpentry')
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving profile...')));
                  String userID = FirebaseAuth.instance.currentUser!.uid;

                  if (_selectedImage != null) {
                    try {
                      final uploadedUrl = await AuthenticationService().uploadProfilePicture(userID, _selectedImage!);
                      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
                        setState(() {
                          _existingImageUrl = uploadedUrl;
                        });
                      }
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
                      return;
                    }
                  }

                  try {
                    await FirebaseFirestore.instance.collection('Users').doc(userID).update({
                      'name': _nameController.text.trim(),
                      'phone': _phoneController.text.trim(),
                      'location': _locationController.text.trim(),
                      'aboutMe': _aboutController.text.trim(),
                      'skills': _skillsController.text.trim(),
                    });
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save info: $e')));
                    return;
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated Successfully!')));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}