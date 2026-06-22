import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setting/app_settings_page.dart';
import 'package:get_fit/Presentation/pages/setting/favorites_page.dart';
import 'package:get_fit/Presentation/pages/setting/help_and_faq_page.dart';
import 'package:get_fit/Presentation/pages/setting/privacy_policy_page.dart';
import 'package:get_fit/Presentation/pages/setting/profile_page.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/auth/login_page.dart';
import 'package:get_fit/Services/supabase_service.dart';

class SettingHomePage extends StatefulWidget {
  const SettingHomePage({super.key});

  @override
  State<SettingHomePage> createState() => _SettingHomePageState();
}

class _SettingHomePageState extends State<SettingHomePage> {
  static bool _hasLoaded = false;
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  final List<Map<String, dynamic>> settingsItems = const [
    {'title': 'Profile', 'icon': Icons.person},
    {'title': 'Favourite', 'icon': Icons.star},
    {'title': 'Privacy Policy', 'icon': Icons.lock},
    {'title': 'Settings', 'icon': Icons.settings},
    {'title': 'Help', 'icon': Icons.help},
    {'title': 'Dark Mode', 'icon': Icons.dark_mode},
    {'title': 'Logout', 'icon': Icons.logout},
  ];

 @override
void initState() {
  super.initState();
  _hasLoaded = false;
  _loadData();
}

  Future<void> _loadData() async {
  if (_hasLoaded) {
    setState(() => _isLoading = false);
    return;
  }
  final data = await SupabaseService.getUserProfile();
  if (mounted) {
    _hasLoaded = true;
    _profileData = data;
    setState(() => _isLoading = false);
  }
}


  Future<void> _onRefresh() async {
  _hasLoaded = false;
  setState(() => _isLoading = true);
  final data = await SupabaseService.getUserProfile();
  if (mounted) {
    _hasLoaded = true;
    _profileData = data;
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          // Yellow header bg
          Container(
            height: 337,
            width: double.infinity,
            decoration: const BoxDecoration(color: themeColor),
          ),

          // Back button
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                    backgroundColor: Colors.black54,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ],
            ),
          ),

          // Profile section (always visible, not skeletonized — it's above the fold)
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    CircleAvatar(
  radius: 65,
  backgroundColor: context.bgColor,
  backgroundImage: _profileData?['avatar_url'] != null
      ? NetworkImage(_profileData!['avatar_url'])
      : null,
  child: _profileData?['avatar_url'] == null
      ? Icon(Icons.person, size: 100, color: context.textColor)
      : null,
),
                    const SizedBox(height: 20),
                    Text(
                      _profileData?['username'] ?? 'Loading...',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                                        const SizedBox(height: 10),
                                        Text(
                      _profileData?['email'] ?? 'Loading...',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stats bar
          Positioned(
            top: 295,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? const Color(0xff414141)
                      : const Color(0xff1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text("${_profileData?['weight'] ?? '--'} kg",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text("Weight", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      VerticalDivider(color: Colors.white, thickness: 2),
                      Column(
                        children: [
                          Text("${_profileData?['age'] ?? '--'}",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text("Years Old", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                      VerticalDivider(color: Colors.white, thickness: 2),
                      Column(
                        children: [
                          Text("${_profileData?['height'] ?? '--'} cm",
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text("Height", style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Settings list with skeleton + refresh
          Positioned(
            top: 350,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 420,
                child: RefreshIndicator(
                  color: context.subtextColor,
                  backgroundColor: context.cardBgColor,
                  displacement: 100,
                  onRefresh: _onRefresh,
                  child: _isLoading
                      ? _buildSkeleton(context)
                      : _buildList(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.builder(
  physics: const AlwaysScrollableScrollPhysics(),
  itemCount: settingsItems.length,
  itemBuilder: (context, index) {
        final item = settingsItems[index];
        final isLogout = item['title'] == 'Logout';
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: themeColor,
            child: Icon(item['icon'], color: Colors.black, size: 24),
          ),
          title: Text(
            item['title'],
            style: TextStyle(
              color: isLogout
                  ? (context.isDark ? themeColor : Colors.red)
                  : context.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          trailing: item['title'] == 'Dark Mode'
              ? ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeNotifier,
                  builder: (context, mode, _) {
                    return Switch(
                      value: mode == ThemeMode.dark,
                      activeColor: themeColor,
                      onChanged: (val) {
                        themeNotifier.value =
                            val ? ThemeMode.dark : ThemeMode.light;
                      },
                    );
                  },
                )
              : Icon(
                  Icons.arrow_forward_ios,
                  color: context.isDark ? themeColor : Colors.black,
                  size: 18,
                ),
          onTap: () => _handleTap(item['title']),
        );
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: settingsItems.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _shimmer(context, width: 40, height: 40, radius: 20),
              const SizedBox(width: 16),
              _shimmer(context, width: 140, height: 16),
              const Spacer(),
              _shimmer(context, width: 20, height: 20, radius: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmer(BuildContext context,
      {required double width, required double height, double radius = 8}) {
    return _ShimmerWidget(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.isDark
              ? const Color(0xff3a3a3a)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  void _handleTap(String title) {
    switch (title) {
      case 'Profile':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => ProfilePage()));
        break;
      case 'Favourite':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => FavoritesPage()));
        break;
      case 'Privacy Policy':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()));
        break;
      case 'Settings':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => AppSettingsPage()));
        break;
      case 'Help':
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => const HelpAndFaqPage()));
        break;
      case 'Dark Mode':
        themeNotifier.value = themeNotifier.value == ThemeMode.dark
            ? ThemeMode.light
            : ThemeMode.dark;
        break;
      case 'Logout':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: context.bgColor,
            title: Text('Logout', style: TextStyle(color: context.textColor)),
            content: Text('Are you sure you want to logout?',
                style: TextStyle(color: context.subtextColor)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: TextStyle(color: context.subtextColor)),
              ),
              TextButton(
                onPressed: () async {
                  await SupabaseService.signOut();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                child: Text('Logout',
                    style: TextStyle(
                        color: context.isDark ? themeColor : Colors.red)),
              ),
            ],
          ),
        );
        break;
    }
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