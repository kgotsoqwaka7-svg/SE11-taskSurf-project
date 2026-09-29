import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; // Added Storage Instance

  //Creating the account and saving profile data
  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Attempting to create the user account in Firebase Auth
      UserCredential info = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Extract the generated ID
      String userID = info.user!.uid;

      // Save the profile data to Firestore
      await _firestore.collection('Users').doc(userID).set({
        'userID': userID, 
        'name': name, 
        'role': role,
        'profileImageUrl': '', // Added placeholder for the image link
      });

    } catch(e) {
      print('Registration Error: $e');
      throw e;
    }
  }

  // Uploading the image to Storage and saving the URL to Firestore
  Future<String?> uploadProfilePicture(String userID, File imageFile) async {
    try {
      // 1. Create a folder and file path in Firebase Storage
      Reference ref = _storage.ref().child('profile_pictures').child('$userID.jpg');
      
      // 2. Upload the physical file
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      // 3. Retrieve the secure web link for the uploaded image
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      // 4. Update that specific user's Firestore document with the live link
      await _firestore.collection('Users').doc(userID).update({
        'profileImageUrl': downloadUrl,
      });
      
      return downloadUrl; // Return the link so the UI can update immediately
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }
}