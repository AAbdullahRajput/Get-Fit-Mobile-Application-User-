import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          // Scrollable content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      style: TextStyle(color: context.textColor, fontSize: 16),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),

          // Back button overlay
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
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Accept button fixed at bottom
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
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'I\'ve Accepted This',
                  style: TextStyle(
                    color: Colors.black,
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