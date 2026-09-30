import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      });

    } catch(e) {
      print('Registration Error: $e');
      throw e;
    }
  }
}