import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // From Teammate's Code
  User? get currentUser => _auth.currentUser;

  // UPDATED: Checks for suspension immediately upon login
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    // 1. Authenticate with Firebase
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 2. Fetch the user's document from Firestore to check their status
    DocumentSnapshot userDoc = await _firestore
        .collection('Users')
        .doc(userCredential.user!.uid)
        .get();

    // 3. Check if the account is suspended
    if (userDoc.exists) {
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      bool isSuspended = userData['isSuspended'] ?? false;

      if (isSuspended) {
        // If suspended, sign them out immediately and throw an error
        await _auth.signOut();
        throw Exception('Your account has been suspended for violating our terms of service.');
      }
    }

    return userCredential;
  }

  // Your Code (Updated to include default isSuspended field)
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
        'isSuspended': false, // New users are active by default
      });

      // Sign out immediately after registration — user must log in manually
      await _auth.signOut();

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
    String? downloadUrl;
    try {
      final Uint8List bytes = await imageFile.readAsBytes();

      // 1. Try uploading to Firebase Storage with proper metadata
      try {
        Reference ref = _storage.ref().child('profile_pictures').child('$userID.jpg');
        UploadTask uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        TaskSnapshot snapshot = await uploadTask;
        downloadUrl = await snapshot.ref.getDownloadURL();
      } catch (storageError) {
        debugPrint('Firebase Storage upload failed: $storageError. Falling back to direct database image storage.');
      }

      // 2. If Firebase Storage failed (e.g. storage rules / bucket unconfigured), fallback to base64 data URI in Firestore
      if (downloadUrl == null || downloadUrl.isEmpty) {
        downloadUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
      
      // 3. Persist to Firestore Users document
      await _firestore.collection('Users').doc(userID).set({
        'profileImageUrl': downloadUrl,
        'photoUrl': downloadUrl,
      }, SetOptions(merge: true));

      if (downloadUrl.startsWith('http')) {
        try {
          await _auth.currentUser?.updatePhotoURL(downloadUrl);
        } catch (_) {}
      }
      
      return downloadUrl; 
    } catch (e) {
      debugPrint('Upload Error: $e');
      rethrow;
    }
  }
}