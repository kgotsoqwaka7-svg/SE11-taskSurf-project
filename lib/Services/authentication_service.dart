import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // From Teammate's Code
  User? get currentUser => _auth.currentUser;

  // From Teammate's Code
  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Your Code (Updated to include email, phone, and location fields)
  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      UserCredential info = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );

      String userID = info.user!.uid;

      // This ensures EVERYONE goes to the exact same 'Users' collection
      await _firestore.collection('Users').doc(userID).set({
        'userID': userID, 
        'name': name,
        'email': email,
        'role': role,
        'profileImageUrl': '', 
        'location': '',
        'phone': '',
      });

    } catch(e) {
      print('Registration Error: $e');
      rethrow;
    }
  }

  // From Teammate's Code
  Future<void> logout() {
    return _auth.signOut();
  }

  // Your Code
  Future<String?> uploadProfilePicture(String userID, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('profile_pictures').child('$userID.jpg');
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      await _firestore.collection('Users').doc(userID).update({
        'profileImageUrl': downloadUrl,
      });
      
      return downloadUrl; 
    } catch (e) {
      print('Upload Error: $e');
      return null;
    }
  }
}