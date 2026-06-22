import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/auth/login_page.dart';
import 'package:get_fit/Presentation/pages/setting/notifications_page.dart';
import 'package:get_fit/Presentation/pages/setting/password_settings.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class AppSettingsPage extends StatefulWidget {
  const AppSettingsPage({super.key});

  @override
  State<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends State<AppSettingsPage> {
  final List<Map<String, dynamic>> settingsItems = const [
    {'title': 'Notification Settings', 'icon': Icons.notifications},
    {'title': 'Password Settings', 'icon': Icons.lock},
    {'title': 'Delete Account', 'icon': Icons.delete},
  ];

  bool _isDeleting = false;
  final _deletePasswordController = TextEditingController();
  bool _showDeletePassword = false;

  @override
  void dispose() {
    _deletePasswordController.dispose();
    super.dispose();
  }

  // Step 1 — password verify
  void _showDeleteWarningDialog() {
    _deletePasswordController.clear();
    _showDeletePassword = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.lock_outline, color: themeColor, size: 52),
              SizedBox(height: 8),
              Text(
                'Confirm Identity',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your password to proceed with account deletion.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          controller: _deletePasswordController,
                          obscureText: !_showDeletePassword,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15),
                          decoration: const InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                            isCollapsed: true,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setDialogState(
                          () => _showDeletePassword = !_showDeletePassword),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Icon(
                          _showDeletePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white38,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Cancel',
                    style: TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
            ),
            TextButton(
              onPressed: () async {
                final password = _deletePasswordController.text.trim();
                if (password.isEmpty) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: const Text('Please enter your password',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  return;
                }
                try {
                  final email = SupabaseService.currentUser?.email ?? '';
                  await SupabaseService.signIn(
                      email: email, password: password);
                  if (!mounted) return;
                  Navigator.pop(dialogContext);
                  _showDataWarningDialog();
                } catch (e) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: const Text(
                          'Incorrect password. Please try again.',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Verify',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 2 — data warning
  void _showDataWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: themeColor, size: 52),
            SizedBox(height: 8),
            Text(
              'Delete Account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'The following will be permanently deleted:',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
            SizedBox(height: 16),
            _BulletItem(
                icon: Icons.person, text: 'Your profile and personal info'),
            _BulletItem(
                icon: Icons.fitness_center, text: 'All saved favorites'),
            _BulletItem(
                icon: Icons.settings,
                text: 'Your workout setup & preferences'),
            _BulletItem(
                icon: Icons.photo, text: 'Your avatar from storage'),
            _BulletItem(
                icon: Icons.lock, text: 'Your login credentials'),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showFinalConfirmDialog();
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('I Understand, Continue',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3 — final confirm
  void _showFinalConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.delete_forever, color: themeColor, size: 52),
            SizedBox(height: 8),
            Text(
              'Are You Sure?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Tapping "Delete Forever" will immediately and permanently delete your entire account and all associated data with no way to recover it.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Go Back',
                  style: TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold)),
            ),
          ),
          TextButton(
            onPressed: _isDeleting
                ? null
                : () async {
                    Navigator.pop(dialogContext);
                    setState(() => _isDeleting = true);
                    try {
                      await SupabaseService.deleteAccountNoPassword();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _isDeleting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Failed to delete account. Please try again.',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('Delete Forever',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 60, 0, 10),
              child: ListView.builder(
                itemCount: settingsItems.length,
                itemBuilder: (context, index) {
                  final item = settingsItems[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: themeColor,
                      child:
                          Icon(item['icon'], color: Colors.black, size: 24),
                    ),
                    title: Text(
                      item['title'],
                      style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: context.isDark ? themeColor : Colors.black,
                      size: 18,
                    ),
                    onTap: () {
                      switch (item['title']) {
                        case 'Notification Settings':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => NotificationsPage()));
                          break;
                        case 'Password Settings':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const PasswordSettings()));
                          break;
                        case 'Delete Account':
                          _showDeleteWarningDialog();
                          break;
                      }
                    },
                  );
                },
              ),
            ),
          ),

          // Back button
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                    backgroundColor: Colors.black54,
                  ),
                  child:
                      const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BulletItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: themeColor, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}