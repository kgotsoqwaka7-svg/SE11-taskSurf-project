import 'package:flutter/material.dart';
import 'account_info.dart'; // 1. Added import for the new screen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A75FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        children: [
          // Account Information
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('ACCOUNT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Container(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.black87),
              title: const Text('Account Information'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                // 2. Navigates to the new edit screen when tapped
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountInfoScreen()),
                );
              },
            ),
          ),
          
          const SizedBox(height: 32),

          // Log Out & Delete (Danger Zone text removed)
          Container(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                  onTap: () {
                    // TODO: Execute Firebase Sign Out
                  },
                ),
                const Divider(height: 1, indent: 16),
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                  onTap: () {
                    // TODO: Show confirmation dialog, then delete from Firebase
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}