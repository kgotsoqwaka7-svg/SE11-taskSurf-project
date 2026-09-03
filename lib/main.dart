import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Surf App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Youth Jobs Marketplace'),
        ),
        body: const Center(
          child: Text('Firebase Successfully Connected!'),
        ),
      ),
    );
  }
}