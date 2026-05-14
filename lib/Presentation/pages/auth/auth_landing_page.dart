import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/auth/login_page.dart';
import 'dart:ui';

import 'package:get_fit/Presentation/pages/auth/register_page.dart';
import 'package:get_fit/Utils/constants.dart';

class AuthLandingPage extends StatelessWidget {
  const AuthLandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            'assets/auth/bg.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.8),
                ],
                stops: const [0.0, 0.5, 0.75, 1.0],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Spacer(),
                  _buildGlassButton(
                    context: context,
                    label: 'Create Account',
                    icon: Icons.person_add_alt_1_rounded,
                    isPrimary: true,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildGlassButton(
                    context: context,
                    label: 'Login',
                    icon: Icons.login_rounded,
                    isPrimary: false,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 50),
                  
                 ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGlassButton({
    required BuildContext context, 
    required String label, 
    required IconData icon,
    required bool isPrimary, 
    required VoidCallback onPressed
  }) {
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: isPrimary 
                ? themeColor
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isPrimary 
                  ? themeColor 
                  : Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              splashColor: isPrimary 
                  ? themeColor.withOpacity(0.2) 
                  : Colors.white.withOpacity(0.1),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isPrimary ? Colors.black : Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isPrimary ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}