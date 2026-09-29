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
  // Text controllers (starts empty, gets filled by Firestore)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  File? _selectedImage;
  String _existingImageUrl = '';
  bool _isLoading = true; // Shows a loading spinner while fetching data
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Fetch the real data when the screen opens
  }

  // Fetch the logged-in user's data from Firestore
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
            _existingImageUrl = data['profileImageUrl'] ?? '';
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
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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
        backgroundColor: const Color(0xFF5A75FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Edit Account', style: TextStyle(color: Colors.white)),
      ),
      // Show a loading circle until the data is fetched
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF5A75FF)))
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage, 
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    // 1. If they picked a new image, show it.
                    // 2. Otherwise, if they have an existing image, show it.
                    // 3. Otherwise, show the blank placeholder.
                    backgroundImage: _selectedImage != null 
                        ? FileImage(_selectedImage!) as ImageProvider
                        : _existingImageUrl.isNotEmpty
                            ? NetworkImage(_existingImageUrl)
                            : const NetworkImage('https://i.pravatar.cc/150?img=44'),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFF5A75FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
              readOnly: true, // Usually, you don't let them change the auth email here
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A75FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saving profile...')),
                  );

                  String userID = FirebaseAuth.instance.currentUser!.uid;

                  // Upload new image if they selected one
                  if (_selectedImage != null) {
                    try {
                      AuthenticationService authService = AuthenticationService();
                      await authService.uploadProfilePicture(userID, _selectedImage!);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
                      }
                      return;
                    }
                  }

                  // Save the typed text
                  try {
                    await FirebaseFirestore.instance.collection('Users').doc(userID).update({
                      'name': _nameController.text.trim(),
                      'phone': _phoneController.text.trim(),
                      'location': _locationController.text.trim(),
                    });
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save info: $e')));
                    }
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