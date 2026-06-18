import 'package:flutter/material.dart';
import 'package:get_fit/Utils/constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
    return Material(
      color: context.bgColor,
      child: Stack(
        children: [
          // Main scrollable content
          RefreshIndicator(
            color: context.subtextColor,
            backgroundColor: context.cardBgColor,
            displacement: 100,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Top yellow header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 20,
                      bottom: 40,
                    ),
                    decoration: const BoxDecoration(
                      color: themeColor,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: context.bgColor,
                          child: Icon(Icons.person,
                              size: 80, color: context.textColor),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Name Surname',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "email@gmail.com",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.top + 60),

                  // Form fields or skeleton
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _isLoading
                        ? _buildSkeleton(context)
                        : _buildForm(context),
                  ),
                ],
              ),
            ),
          ),

          // Stats box
          Positioned(
            top: MediaQuery.of(context).padding.top + 220,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xff414141)
                      : const Color(0xff1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: const [
                          Text("75 kg",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Weight",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white54),
                    Expanded(
                      child: Column(
                        children: const [
                          Text("28",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Years Old",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white54),
                    Expanded(
                      child: Column(
                        children: const [
                          Text("180 cm",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text("Height",
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
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
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      children: [
        ...formFields.map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: context.cardBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  style: TextStyle(color: context.textColor),
                  decoration: InputDecoration(
                    labelText: field['label'],
                    labelStyle: TextStyle(color: context.subtextColor),
                    hintText: field['hint'],
                    hintStyle: TextStyle(color: context.subtextColor),
                    prefixIcon: Icon(field['icon'],
                        color: context.subtextColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                  ),
                ),
              ),
            )),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
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
              'Update Profile',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Column(
      children: [
        ...List.generate(
          formFields.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ShimmerWidget(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xff3a3a3a)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _ShimmerWidget(
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: context.isDark
                  ? const Color(0xff3a3a3a)
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

final List<Map<String, dynamic>> formFields = [
  {'label': 'Full Name', 'hint': 'Enter your full name', 'icon': Icons.person_outline},
  {'label': 'Email', 'hint': 'Enter your email', 'icon': Icons.email_outlined},
  {'label': 'Mobile Number', 'hint': 'Enter your mobile number', 'icon': Icons.phone_outlined},
  {'label': 'Date of Birth', 'hint': 'DD/MM/YYYY', 'icon': Icons.calendar_today_outlined},
  {'label': 'Weight (kg)', 'hint': 'Enter your weight', 'icon': Icons.monitor_weight_outlined},
  {'label': 'Height (cm)', 'hint': 'Enter your height', 'icon': Icons.height_outlined},
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