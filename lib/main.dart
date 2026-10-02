import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/report_model.dart';
import 'screens/report_screen.dart'; // Adjust path if needed

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
    return const MaterialApp(
      title: 'Task Surf App',
      debugShowCheckedModeBanner: false,
      home: ReportScreen(
        targetId: 'task_001',
        targetTitle: 'Fix leaking sink in Bellville',
        targetSubtitle: 'Task posted by Provider XYZ',
        targetType: ReportType.task,
      ),
    );
  }
}