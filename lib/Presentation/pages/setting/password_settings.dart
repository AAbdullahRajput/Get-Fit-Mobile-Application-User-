import 'package:flutter/material.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/auth/forgot_password.dart';

class PasswordSettings extends StatefulWidget {
  const PasswordSettings({super.key});

  @override
  State<PasswordSettings> createState() => _PasswordSettingsState();
}

class _PasswordSettingsState extends State<PasswordSettings> {
  static bool _hasLoaded = false;
  bool _isLoading = true;
  bool _isChanging = false;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_hasLoaded) {
      setState(() => _isLoading = false);
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _hasLoaded = true;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    _hasLoaded = false;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      _hasLoaded = true;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnack('Please fill in all fields', isError: true);
      return;
    }
    if (newPass.length < 6) {
      _showSnack('New password must be at least 6 characters', isError: true);
      return;
    }
    if (newPass != confirm) {
      _showSnack('Passwords do not match', isError: true);
      return;
    }
    if (current == newPass) {
      _showSnack('New password must be different from current', isError: true);
      return;
    }

    setState(() => _isChanging = true);

    try {
      final email = SupabaseService.currentUser?.email ?? '';
      await SupabaseService.signIn(email: email, password: current);
      await SupabaseService.updatePassword(newPass);

      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle_outline, color: themeColor, size: 56),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Password Changed!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Your password has been updated successfully.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('OK',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Current password is incorrect', isError: true);
    } finally {
      if (mounted) setState(() => _isChanging = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyle(
                color: isError ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : themeColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xff111111) : const Color(0xffF2F2F2),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Password Settings',
                    style: TextStyle(
                      color: themeColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Body
            Expanded(
              child: RefreshIndicator(
                color: themeColor,
                backgroundColor: isDark ? const Color(0xff2C2C2C) : Colors.white,
                onRefresh: _onRefresh,
                child: _isLoading
                    ? _buildSkeleton(context)
                    : _buildForm(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildField(
          controller: _currentPasswordController,
          label: 'Current Password',
          obscure: !_showCurrent,
          toggle: () => setState(() => _showCurrent = !_showCurrent),
          showText: _showCurrent,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 24),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ForgotPasswordPage(fromSettings: true),
                ),
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        _buildField(
          controller: _newPasswordController,
          label: 'New Password',
          obscure: !_showNew,
          toggle: () => setState(() => _showNew = !_showNew),
          showText: _showNew,
        ),
        const SizedBox(height: 16),
        _buildField(
          controller: _confirmPasswordController,
          label: 'Confirm New Password',
          obscure: !_showConfirm,
          toggle: () => setState(() => _showConfirm = !_showConfirm),
          showText: _showConfirm,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _isChanging ? null : _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            disabledBackgroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: _isChanging
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.black),
                )
              : const Text(
                  'Change Password',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    required bool showText,
  }) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextFormField(
                controller: controller,
                obscureText: obscure,
                textAlignVertical: TextAlignVertical.center,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: toggle,
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Icon(
                showText ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey.shade400,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final isDark = context.isDark;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ...List.generate(3, (index) => Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _ShimmerWidget(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xff3a3a3a) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            if (index == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: _ShimmerWidget(
                  child: Container(
                    width: 120,
                    height: 13,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff3a3a3a) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
          ],
        )),
        const SizedBox(height: 24),
        _ShimmerWidget(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff3a3a3a) : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}