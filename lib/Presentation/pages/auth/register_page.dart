import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/auth/login_page.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/home/home_page.dart';
import 'package:flutter/services.dart';
import 'package:get_fit/Presentation/widgets/validated_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _mobileNoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFieldKey = GlobalKey<ValidatedTextFieldState>();
  final _emailFieldKey = GlobalKey<ValidatedTextFieldState>();
  final _mobileFieldKey = GlobalKey<ValidatedTextFieldState>();
  final _passwordFieldKey = GlobalKey<ValidatedTextFieldState>();
  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _validateUsername(String value) {
    if (value.trim().isEmpty) return 'Username is required';
    if (value.trim().length < 3) return 'Username must be at least 3 characters';
    return null;
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email like name@example.com';
    }
    return null;
  }

  String? _validateMobile(String value) {
    if (value.isEmpty) return 'Mobile number is required';
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Digits only — no letters or symbols';
    }
    if (value.length > 11) return 'Maximum 11 digits allowed';
    if (value.length < 10) return 'Enter a valid 10-11 digit number';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    if (value.length > 20) return 'Password must be 20 characters or fewer';
    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _mobileNoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final mobileNo = _mobileNoController.text.trim();
    final password = _passwordController.text.trim();

    final usernameError = _usernameFieldKey.currentState?.validateForSubmit();
    final emailError = _emailFieldKey.currentState?.validateForSubmit();
    final mobileError = _mobileFieldKey.currentState?.validateForSubmit();
    final passwordError = _passwordFieldKey.currentState?.validateForSubmit();

    if (usernameError != null ||
        emailError != null ||
        mobileError != null ||
        passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        username: username,
        mobileNo: mobileNo,
      );

      if (!mounted) return;

      if (response.user != null) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceAll('AuthException: ', '');
      if (msg.toLowerCase().contains('already registered') || 
          msg.toLowerCase().contains('already exists') ||
          msg.toLowerCase().contains('rate limit') ||
          msg.toLowerCase().contains('email rate')) {
        _showEmailExistsDialog(msg);
      } else {
        _showErrorDialog('Registration Failed', msg);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF4A5240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle_outline, color: Color(0xFFDBF500), size: 48),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Account Created!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your account has been created successfully. Please login to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDBF500),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Go to Login',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

void _showEmailExistsDialog(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF4A5240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(
  msg.toLowerCase().contains('rate limit') 
    ? Icons.timer_outlined 
    : Icons.email_outlined, 
  color: const Color(0xFFDBF500), 
  size: 48
),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Registration Failed',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              msg.toLowerCase().contains('rate limit') 
                ? 'Too many requests. Please wait a moment and try again.'
                : 'This email is already registered. Please login or use a different email.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (!msg.toLowerCase().contains('rate limit'))
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBF500),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Go to Login',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Try Again',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF4A5240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFDBF500),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
  

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 45),
                Image.asset('assets/auth/logo-2.png', height: 88),
                const SizedBox(height: 30),
                const Text(
                  "Welcome",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Create an account",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A5240).withOpacity(0.85),
                    border: Border(
                      top: BorderSide(
                        color: const Color.fromARGB(255, 217, 240, 8).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValidatedTextField(
                        key: _usernameFieldKey,
                        controller: _usernameController,
                        hint: 'e.g. john_doe',
                        icon: Icons.person_outline,
                        validator: _validateUsername,
                      ),
                      const SizedBox(height: 20),
                      ValidatedTextField(
                        key: _emailFieldKey,
                        controller: _emailController,
                        hint: 'name@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 20),
                      ValidatedTextField(
                        key: _mobileFieldKey,
                        controller: _mobileNoController,
                        hint: '03XXXXXXXXX (10-11 digits)',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: _validateMobile,
                      ),
                      const SizedBox(height: 20),
                      ValidatedTextField(
                        key: _passwordFieldKey,
                        controller: _passwordController,
                        hint: '6-20 characters',
                        icon: Icons.lock_outline,
                        obscure: _obscurePassword,
                        maxLength: 20,
                        validator: _validatePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xff333333),
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),

                      const SizedBox(height: 24),
                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account? ",
                            style: TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const LoginPage()),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Color(0xFFDBF500),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFDBF500), width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        ),
      ),
      child: SizedBox(
        height: 60,
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.black54),
            prefixIcon: Icon(icon, color: const Color(0xff333333)),
            suffixIcon: suffixIcon,
          ),
        ),
      ),
    );
  }
}