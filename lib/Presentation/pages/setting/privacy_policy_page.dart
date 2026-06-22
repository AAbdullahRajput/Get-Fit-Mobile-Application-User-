import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool _isAccepting = false;
  bool _alreadyAccepted = false;

  @override
  void initState() {
    super.initState();
    _checkAccepted();
  }

  Future<void> _checkAccepted() async {
    final data = await SupabaseService.getUserProfile();
    if (mounted) {
      setState(() => _alreadyAccepted = data?['terms_accepted'] == true);
    }
  }

  Future<void> _accept() async {
    if (_alreadyAccepted) return;
    setState(() => _isAccepting = true);
    await SupabaseService.acceptTerms();
    if (!mounted) return;
    await _checkAccepted(); // re-read from DB to confirm
    if (!mounted) return;
    setState(() => _isAccepting = false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF4A5240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_outline, color: themeColor, size: 56),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Terms Accepted!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'You have successfully accepted our Terms & Privacy Policy.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
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
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Accepted badge
                    if (_alreadyAccepted)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: themeColor, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified, color: themeColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'You have already accepted these terms.',
                              style: TextStyle(color: context.textColor, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),

                    Text(
                      'Terms and Conditions',
                      style: TextStyle(
                        color: context.isDark ? themeColor : Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'By downloading or using the app, these terms will automatically apply to you. Please read them carefully before using the app.',
                      style: TextStyle(color: context.textColor, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Privacy Policy',
                      style: TextStyle(
                        color: context.isDark ? themeColor : Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '''Your privacy is important to us. This privacy policy explains how we collect, use, and protect your information when you use our app.

1. Information Collection
We collect information that you provide directly to us, including:
- Personal information (name, email, age)
- Fitness data (height, weight, activity levels)
- Device information and usage statistics

2. How We Use Your Information
- To personalize your workout experience
- To track your fitness progress
- To improve our services
- To communicate with you about updates

3. Data Security
We implement security measures to protect your personal information from unauthorized access or disclosure.

4. Third-Party Services
We may use third-party services that collect information. These services have their own privacy policies.

5. Updates to Privacy Policy
We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.

6. Contact Us
If you have any questions about this privacy policy, please contact us.''',
                      style: TextStyle(color: context.textColor, fontSize: 15, height: 1.6),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
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
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),

          // Bottom button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.bgColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _alreadyAccepted || _isAccepting ? null : _accept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _alreadyAccepted ? const Color(0xFF3A3A3A) : themeColor,
                  disabledBackgroundColor: _alreadyAccepted ? const Color(0xFF3A3A3A) : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: _isAccepting
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                      )
                    : Text(
                        _alreadyAccepted ? 'Already Accepted ✓' : "I've Accepted This",
                        style: TextStyle(
                          color: _alreadyAccepted ? Colors.white54 : Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}