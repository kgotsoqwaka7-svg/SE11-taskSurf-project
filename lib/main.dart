import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:task_surf_se11/screens/main_navigation.dart';
import 'package:task_surf_se11/screens/task_provider_dashboard.dart';
import 'firebase_options.dart';
import 'screens/task_provider_dashboard.dart'; // Add this import

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
      debugShowCheckedModeBanner: false, // Hides the debug banner
      home: const MainNavigation(), // Loads your new UI immediately
    );
  }
}