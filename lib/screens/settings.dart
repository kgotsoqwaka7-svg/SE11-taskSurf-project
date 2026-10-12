import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'authScreen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;

  // ── Notification prefs ─────────────────────────────────────────────
  bool _notifyNewMessages = true;
  bool _notifyTaskUpdates = true;
  bool _notifyApplications = true;
  bool _notifyPromotions = false;

  // ── Privacy prefs ──────────────────────────────────────────────────
  bool _profilePublic = true;
  bool _showLocation = true;

  // ── App prefs ──────────────────────────────────────────────────────
  bool _emailUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('Users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final prefs = data['settings'] as Map<String, dynamic>? ?? {};

        setState(() {
          _notifyNewMessages   = prefs['notifyNewMessages']   ?? true;
          _notifyTaskUpdates   = prefs['notifyTaskUpdates']   ?? true;
          _notifyApplications  = prefs['notifyApplications']  ?? true;
          _notifyPromotions    = prefs['notifyPromotions']    ?? false;
          _profilePublic       = prefs['profilePublic']       ?? true;
          _showLocation        = prefs['showLocation']        ?? true;
          _emailUpdates        = prefs['emailUpdates']        ?? true;
          _isLoading           = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Persists a single settings key to Firestore.
  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      await _firestore.collection('Users').doc(user.uid).set(
        {'settings': {key: value}},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error saving setting "$key": $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save setting.')),
        );
      }
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────

  void _showChangePasswordDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl     = TextEditingController();
    final confirmCtrl     = TextEditingController();
    bool obscureCurrent   = true;
    bool obscureNew       = true;
    bool obscureConfirm   = true;
    bool saving           = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Change Password',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _passField('Current Password', currentPassCtrl,
                    obscureCurrent, () {
                  setDialogState(
                      () => obscureCurrent = !obscureCurrent);
                }),
                const SizedBox(height: 12),
                _passField('New Password', newPassCtrl, obscureNew,
                    () {
                  setDialogState(() => obscureNew = !obscureNew);
                }),
                const SizedBox(height: 12),
                _passField('Confirm New Password', confirmCtrl,
                    obscureConfirm, () {
                  setDialogState(
                      () => obscureConfirm = !obscureConfirm);
                }),
              ],
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: saving
                    ? null
                    : () async {
                        if (newPassCtrl.text != confirmCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Passwords do not match.')),
                          );
                          return;
                        }
                        if (newPassCtrl.text.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Password must be at least 6 characters.')),
                          );
                          return;
                        }
                        setDialogState(() => saving = true);
                        try {
                          final user = _auth.currentUser!;
                          final cred = EmailAuthProvider.credential(
                            email: user.email!,
                            password: currentPassCtrl.text,
                          );
                          await user.reauthenticateWithCredential(cred);
                          await user.updatePassword(newPassCtrl.text);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password updated successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          setDialogState(() => saving = false);
                          String msg = 'An error occurred.';
                          if (e.code == 'wrong-password') {
                            msg = 'Current password is incorrect.';
                          } else if (e.code == 'weak-password') {
                            msg = 'New password is too weak.';
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Update'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showDeleteAccountDialog() {
    final passCtrl = TextEditingController();
    bool deleting  = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Delete Account',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This will permanently delete your account and all associated data. This action cannot be undone.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm your password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: deleting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: deleting
                    ? null
                    : () async {
                        if (passCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter your password.')),
                          );
                          return;
                        }
                        setDialogState(() => deleting = true);
                        try {
                          final user = _auth.currentUser!;
                          final cred = EmailAuthProvider.credential(
                            email: user.email!,
                            password: passCtrl.text,
                          );
                          await user.reauthenticateWithCredential(cred);
                          // Delete Firestore user doc
                          await _firestore
                              .collection('Users')
                              .doc(user.uid)
                              .delete();
                          // Delete auth account
                          await user.delete();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AuthScreen()),
                              (_) => false,
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          setDialogState(() => deleting = false);
                          String msg = 'Deletion failed.';
                          if (e.code == 'wrong-password') {
                            msg = 'Incorrect password.';
                          }
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                        }
                      },
                child: deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Delete'),
              ),
            ],
          );
        });
      },
    );
  }

  // ── Build ──────────────────────────────────────────────────────────


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Settings',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFF1976D2)))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // ── Account ───────────────────────────────────────
                _sectionLabel('ACCOUNT'),
                _settingsCard(children: [
                  _navTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Change Password',
                    subtitle: 'Update your login password',
                    onTap: _showChangePasswordDialog,
                  ),
                ]),


                // ── Notifications ─────────────────────────────────
                _sectionLabel('NOTIFICATIONS'),
                _settingsCard(children: [
                  _toggleTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'New Messages',
                    subtitle: 'Get notified when someone messages you',
                    value: _notifyNewMessages,
                    onChanged: (v) {
                      setState(() => _notifyNewMessages = v);
                      _saveSetting('notifyNewMessages', v);
                    },
                  ),
                  _divider(),
                  _toggleTile(
                    icon: Icons.task_alt_rounded,
                    title: 'Task Updates',
                    subtitle: 'Status changes on tasks you\'re involved in',
                    value: _notifyTaskUpdates,
                    onChanged: (v) {
                      setState(() => _notifyTaskUpdates = v);
                      _saveSetting('notifyTaskUpdates', v);
                    },
                  ),
                  _divider(),
                  _toggleTile(
                    icon: Icons.people_outline_rounded,
                    title: 'Applications',
                    subtitle: 'When someone applies to your task',
                    value: _notifyApplications,
                    onChanged: (v) {
                      setState(() => _notifyApplications = v);
                      _saveSetting('notifyApplications', v);
                    },
                  ),
                  _divider(),
                  _toggleTile(
                    icon: Icons.local_offer_outlined,
                    title: 'Promotions & Tips',
                    subtitle: 'TaskSurf news and helpful tips',
                    value: _notifyPromotions,
                    onChanged: (v) {
                      setState(() => _notifyPromotions = v);
                      _saveSetting('notifyPromotions', v);
                    },
                  ),
                ]),

                // ── Privacy ───────────────────────────────────────
                _sectionLabel('PRIVACY'),
                _settingsCard(children: [
                  _toggleTile(
                    icon: Icons.public_rounded,
                    title: 'Public Profile',
                    subtitle:
                        'Allow others to view your profile and reviews',
                    value: _profilePublic,
                    onChanged: (v) {
                      setState(() => _profilePublic = v);
                      _saveSetting('profilePublic', v);
                    },
                  ),
                  _divider(),
                  _toggleTile(
                    icon: Icons.location_on_outlined,
                    title: 'Show Location',
                    subtitle: 'Display your area on your public profile',
                    value: _showLocation,
                    onChanged: (v) {
                      setState(() => _showLocation = v);
                      _saveSetting('showLocation', v);
                    },
                  ),
                  _divider(),
                  _toggleTile(
                    icon: Icons.email_outlined,
                    title: 'Email Updates',
                    subtitle:
                        'Receive important account emails from TaskSurf',
                    value: _emailUpdates,
                    onChanged: (v) {
                      setState(() => _emailUpdates = v);
                      _saveSetting('emailUpdates', v);
                    },
                  ),
                ]),

                // ── Danger Zone ───────────────────────────────────
                // ── Danger Zone ───────────────────────────────────
                _sectionLabel('ACCOUNT ACTIONS'),
                _settingsCard(children: [
                  _navTile(
                    icon: Icons.logout_rounded,
                    iconColor: Colors.orange,
                    title: 'Log Out',
                    titleColor: Colors.orange,
                    subtitle: 'Sign out of your TaskSurf account',
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                          (route) => false, // Clears the navigation history
                        );
                      }
                    },
                  ),
                  _divider(),
                  _navTile(
                    icon: Icons.delete_forever_rounded,
                    iconColor: Colors.red,
                    title: 'Delete Account',
                    titleColor: Colors.red,
                    subtitle:
                        'Permanently delete your account and all data',
                    onTap: _showDeleteAccountDialog,
                  ),
                ]),
                const SizedBox(height: 30),
                Center(
                  child: Text(
                    'TaskSurf v1.0.0',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }

  // ── Small helpers ──────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Color(0xFF1976D2),
        ),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, indent: 56, endIndent: 16);

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF1976D2), size: 20),
      ),
      title: Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF1976D2),
      activeTrackColor: const Color(0xFF1976D2).withValues(alpha: 0.35),
    );
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF1976D2))
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            color: iconColor ?? const Color(0xFF1976D2), size: 20),
      ),
      title: Text(title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: titleColor ?? const Color(0xFF1A1A1A),
          )),
      subtitle: Text(subtitle,
          style:
              TextStyle(color: Colors.grey.shade500, fontSize: 12)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  TextField _passField(String label, TextEditingController ctrl,
      bool obscure, VoidCallback toggleObscure) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon:
              Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleObscure,
        ),
      ),
    );
  }
}