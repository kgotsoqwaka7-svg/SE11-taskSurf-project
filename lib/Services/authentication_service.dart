import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthenticationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Creating the account what what data will be saved for the profile
  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try{
      //Atempting to create the user account is Firebase Auth
      UserCredential info = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    }
  }
}