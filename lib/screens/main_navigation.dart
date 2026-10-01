import 'package:flutter/material.dart';
import 'task_provider_dashboard.dart';
import '../screens/user_profile.dart'; // Ensure these paths match your structure
import '../screens/settings.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // List of the screens we just built, updated with a Messages placeholder
  final List<Widget> _screens = [
    const TaskProviderDashboard(),
    const Center(child: Text('Messages Screen Coming Soon', style: TextStyle(fontSize: 18, color: Colors.grey))),
    const UserProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // Shows the active screen
      // Upgraded to NavigationBar to match your teammate's UI exactly
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index; // Changes the tab when clicked
          });
        },
        backgroundColor: Colors.white,
        elevation: 5,
        indicatorColor: const Color(0xFFE3F2FD), // Teammate's light blue bubble
        height: 70,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(
              Icons.dashboard_rounded,
              color: Color(0xFF1976D2), // Teammate's primary dark blue
            ),
            label: 'Dashboard',
          ),
          
          // Added the exact Messages icon block from homeScreen.dart
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