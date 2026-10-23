import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_provider_dashboard.dart';
import '../screens/conversations_screen.dart'; // Ensure correct path
import '../screens/user_profile.dart'; 
import '../screens/settings.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    final List<Widget> screens = [
      const TaskProviderDashboard(),
      ConversationsScreen(currentUserId: currentUserId),
      const UserProfileScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 5,
        indicatorColor: const Color(0xFFE3F2FD),
        height: 70,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard_rounded,
              color: Color(0xFF1976D2),
            ),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(
              Icons.chat_bubble_rounded,
              color: Color(0xFF1976D2),
            ),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(
              Icons.person_rounded,
              color: Color(0xFF1976D2),
            ),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(
              Icons.settings_rounded,
              color: Color(0xFF1976D2),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}