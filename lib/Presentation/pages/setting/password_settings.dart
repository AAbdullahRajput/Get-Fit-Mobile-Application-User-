import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class PasswordSettings extends StatefulWidget {
  const PasswordSettings({super.key});

  @override
  State<PasswordSettings> createState() => _PasswordSettingsState();
}

class _PasswordSettingsState extends State<PasswordSettings> {
  static bool _hasLoaded = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
              child: RefreshIndicator(
                color: context.subtextColor,
                backgroundColor: context.cardBgColor,
                displacement: 100,
                onRefresh: _onRefresh,
                child: _isLoading
                    ? _buildSkeleton(context)
                    : _buildForm(context),
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
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: formFields.length + 1,
      itemBuilder: (context, index) {
        if (index < formFields.length) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: context.cardBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  height: 45,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextFormField(
                      style: TextStyle(color: context.textColor),
                      decoration: InputDecoration(
                        hintText: formFields[index]['label'],
                        hintStyle: TextStyle(color: context.subtextColor),
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.visibility,
                            color: context.subtextColor),
                      ),
                    ),
                  ),
                ),
              ),
              if (index == 0)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 8, right: 8, bottom: 16),
                  child: GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: context.isDark ? themeColor : Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          );
        } else {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Change Password',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ...List.generate(
          formFields.length,
          (index) => Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _ShimmerWidget(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? const Color(0xff3a3a3a)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (index == 0)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 8, right: 8, bottom: 16),
                  child: _ShimmerWidget(
                    child: Container(
                      width: 110,
                      height: 12,
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? const Color(0xff3a3a3a)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: _ShimmerWidget(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xff3a3a3a)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

final List<Map<String, dynamic>> formFields = [
  {'label': 'Current Password', 'hint': 'Enter your current password'},
  {'label': 'New Password', 'hint': 'Enter your new password'},
  {'label': 'Confirm New Password', 'hint': 'Re-enter your new password'},
];

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