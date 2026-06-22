import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setting/setting_home_page.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_tab_content.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/fitnes_trainer/fitness_tainer_detail_page.dart';
import 'package:get_fit/Presentation/pages/runner/runner_page.dart';
import 'package:get_fit/Presentation/pages/gym/gym_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_fit/Services/supabase_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  int _selectedTab = 0;
  static bool _hasLoaded = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _tabs = const [
    {'label': 'Overview', 'icon': Icons.grid_view_rounded},
    {'label': 'Trainers', 'icon': Icons.fitness_center_outlined},
    {'label': 'Yoga', 'icon': Icons.self_improvement_outlined},
    {'label': 'Gym', 'icon': Icons.sports_gymnastics_outlined},
    {'label': 'Running', 'icon': Icons.directions_run_outlined},
  ];

  @override
  bool get wantKeepAlive => true;

  late final List<Widget> _pages = [
    _OverviewTab(onTabSwitch: (i) => setState(() => _selectedTab = i)),
    _buildFitnessTab(),
    const YogaTabContent(),
    const GymPage(),
    const RunnerPage(),
  ];

  @override
  void initState() {
    super.initState();
    _hasLoaded = true;
    _isLoading = false;
  }

  Widget _buildFitnessTab() {
    return _FitnessTabContent();
  }

  Widget _buildSkeleton(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBox(context, width: 120, height: 22),
                  const SizedBox(height: 8),
                  _skeletonBox(context, width: 200, height: 14),
                ],
              ),
              Row(
                children: [
                  _skeletonBox(context, width: 24, height: 24, radius: 12),
                  const SizedBox(width: 10),
                  _skeletonBox(context, width: 24, height: 24, radius: 12),
                  const SizedBox(width: 10),
                  _skeletonBox(context, width: 24, height: 24, radius: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          _skeletonBox(context, width: double.infinity, height: 77, radius: 20),
          const SizedBox(height: 30),
          _skeletonBox(context, width: 160, height: 22),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _skeletonBox(context, width: double.infinity, height: 160, radius: 16)),
              const SizedBox(width: 16),
              Expanded(child: _skeletonBox(context, width: double.infinity, height: 160, radius: 16)),
            ],
          ),
          const SizedBox(height: 20),
          _skeletonBox(context, width: double.infinity, height: 194, radius: 16),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _skeletonBox(BuildContext context, {required double width, required double height, double radius = 8}) {
    return _ShimmerWidget(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xff3a3a3a)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) {
            final isSelected = _selectedTab == i;
            final unselectedColor = isDark ? Colors.white54 : Colors.grey.shade600;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_tabs[i]['icon'] as IconData,
                      color: isSelected ? (isDark ? themeColor : Colors.black) : unselectedColor),
                  const SizedBox(height: 4),
                  Text(_tabs[i]['label'] as String,
                      style: TextStyle(
                          color: isSelected ? (isDark ? themeColor : Colors.black) : unselectedColor,
                          fontSize: 12)),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 40,
                      height: 2,
                      color: isDark ? themeColor : Colors.black,
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// OVERVIEW TAB
// ─────────────────────────────────────────────
class _OverviewTab extends StatefulWidget {
  final Function(int) onTabSwitch;
  const _OverviewTab({required this.onTabSwitch});

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  String _username = '';
  List<Map<String, dynamic>> _appointments = [];
  bool _loadingAppointments = true;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final res = await SupabaseService.getMyAppointments();
      if (mounted) setState(() { _appointments = res; _loadingAppointments = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingAppointments = false);
    }
  }

  Future<void> _fetchUsername() async {
    final data = await SupabaseService.getUserProfile();
    if (mounted) setState(() { _username = data?['username'] ?? 'User'; });
  }

  Future<void> _onRefresh() async {
    await _fetchUsername();
    await _fetchAppointments();
  }

  // upcoming trainer appointments (future dates)
  List<Map<String, dynamic>> get _upcomingAppointments {
    final today = DateTime.now();
    return _appointments.where((a) {
      try {
        final d = DateTime.parse(a['appointment_date']);
        return !d.isBefore(DateTime(today.year, today.month, today.day));
      } catch (_) { return false; }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: themeColor,
      backgroundColor: Theme.of(context).cardColor,
      displacement: 100,
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Hi, $_username!",
                            style: TextStyle(
                                color: isDark ? themeColor : Colors.black,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                        Text("It's time to challenge your limits.",
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodyLarge?.color)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.search, color: isDark ? themeColor : Colors.black),
                        const SizedBox(width: 10),
                        Icon(Icons.notifications, color: isDark ? themeColor : Colors.black),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SettingHomePage())),
                          child: Icon(Icons.settings, color: isDark ? themeColor : Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Workout Today banner ──
              const SizedBox(height: 20),
              Container(
                height: 80,
                decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Image.asset("assets/home/fire.png", width: 50, height: 50),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Workout Today",
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
                            const SizedBox(height: 2),
                            Text("let's achieve your target today",
                                style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.7))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Activity Summary ──
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text("Activity Summary",
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  // Steps card
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 160,
                          padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[200] : const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  SvgPicture.asset("assets/icons/steps_icon.svg",
                                      width: 16, height: 16,
                                      colorFilter: const ColorFilter.mode(Color.fromARGB(255, 0, 0, 0), BlendMode.srcIn)),
                                  const SizedBox(width: 6),
                                  const Text("Steps",
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color.fromARGB(255, 0, 0, 0))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("5000",
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? const Color.fromARGB(255, 210, 231, 16) : Colors.black)),
                                      const Text("/10000",
                                          style: TextStyle(fontSize: 15, color: Color.fromARGB(255, 0, 0, 0))),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          SvgPicture.asset("assets/icons/clock_icon.svg",
                                              width: 12, height: 12,
                                              colorFilter: const ColorFilter.mode(Color.fromARGB(255, 0, 0, 0), BlendMode.srcIn)),
                                          const SizedBox(width: 4),
                                          const Text("Last", style: TextStyle(fontSize: 11, color: Color.fromARGB(255, 0, 0, 0))),
                                        ],
                                      ),
                                      const Text("7 Days", style: TextStyle(fontSize: 11, color: Color.fromARGB(255, 0, 0, 0))),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -30, left: 0, right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  shape: BoxShape.circle),
                              child: Container(
                                width: 60, height: 60,
                                decoration: const BoxDecoration(color: themeColor, shape: BoxShape.circle),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset("assets/home/container-1-icon.png", height: 36, width: 36, fit: BoxFit.contain),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Calories card
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 160,
                          padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[200] : const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  SvgPicture.asset("assets/icons/calories_icon.svg",
                                      width: 16, height: 16,
                                      colorFilter: const ColorFilter.mode(Color.fromARGB(255, 0, 0, 0), BlendMode.srcIn)),
                                  const SizedBox(width: 6),
                                  const Text("Calories",
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color.fromARGB(255, 0, 0, 0))),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("1500",
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? const Color.fromARGB(255, 192, 207, 50) : Colors.black)),
                                      const Text("/20000",
                                          style: TextStyle(fontSize: 15, color: Color.fromARGB(255, 0, 0, 0))),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          SvgPicture.asset("assets/icons/clock_icon.svg",
                                              width: 12, height: 12,
                                              colorFilter: const ColorFilter.mode(Color.fromARGB(255, 0, 0, 0), BlendMode.srcIn)),
                                          const SizedBox(width: 4),
                                          const Text("Last", style: TextStyle(fontSize: 11, color: Color.fromARGB(255, 0, 0, 0))),
                                        ],
                                      ),
                                      const Text("7 Days", style: TextStyle(fontSize: 11, color: Color.fromARGB(255, 0, 0, 0))),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -30, left: 0, right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  shape: BoxShape.circle),
                              child: Container(
                                width: 60, height: 60,
                                decoration: const BoxDecoration(color: themeColor, shape: BoxShape.circle),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset("assets/home/container-2-icon.png", height: 36, width: 36, fit: BoxFit.contain),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── YOGA CLASS CARD ──
              const SizedBox(height: 30),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 194,
                    width: double.infinity,
                    decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Next Upcoming Class",
                              style: TextStyle(color: Colors.black, fontSize: 25, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          const Text("Yoga",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 25)),
                          const Text("Time: 2h:20m", style: TextStyle(color: Colors.black, fontSize: 17)),
                          const Spacer(),
                          SizedBox(
                            width: 100,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () => widget.onTabSwitch(2),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text("Join Now", style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -23, left: 0, right: -75,
                    child: Image.asset("assets/home/yoga-girl.png", height: 223, width: 150),
                  ),
                ],
              ),

              // ── FITNESS TRAINER CARD ──
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => widget.onTabSwitch(1),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 100, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Next Training Session",
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Fitness Trainer",
                                style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Personal & Group Sessions",
                                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: 110,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () => widget.onTabSwitch(1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text("Book Now", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Trainer icon on the right
                      Positioned(
                top: -43, right: 15, left: 0,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    "assets/home/trainer-man.png",
                    height: 223,
                    width: 150,
                  ),
                ),
              ),
                    ],
                  ),
                ),
              ),

              // ── UPCOMING TRAINER APPOINTMENTS ──
              const SizedBox(height: 20),
              Text("Upcoming Appointments",
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _loadingAppointments
                  ? const Center(child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: themeColor, strokeWidth: 2)))
                  : _upcomingAppointments.isEmpty
                      ? GestureDetector(
                          onTap: () => widget.onTabSwitch(1),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today_outlined, color: themeColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text("No upcoming appointments. Book a trainer!",
                                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
                                ),
                                Icon(Icons.arrow_forward_ios, color: themeColor, size: 14),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: _upcomingAppointments.take(3).map((a) {
                            final trainer = a['fitness_trainers'];
                            final imageUrl = trainer?['image_url'] ?? '';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: themeColor,
                                      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                                      child: imageUrl.isEmpty
                                          ? const Icon(Icons.person, color: Colors.black, size: 22)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(trainer?['name'] ?? 'Trainer',
                                              style: TextStyle(
                                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14)),
                                          Text(trainer?['training_type'] ?? '',
                                              style: TextStyle(color: themeColor, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, color: Colors.grey, size: 11),
                                            const SizedBox(width: 4),
                                            Text(a['appointment_date'] ?? '',
                                                style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(Icons.access_time, color: Colors.grey, size: 11),
                                            const SizedBox(width: 4),
                                            Text(a['appointment_time'] ?? '',
                                                style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: a['status'] == 'confirmed'
                                                ? Colors.green.withOpacity(0.15)
                                                : themeColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            (a['status'] ?? 'pending').toString().toUpperCase(),
                                            style: TextStyle(
                                              color: a['status'] == 'confirmed' ? Colors.green : themeColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FITNESS TAB CONTENT
// ─────────────────────────────────────────────
class _FitnessTabContent extends StatefulWidget {
  @override
  State<_FitnessTabContent> createState() => _FitnessTabContentState();
}

class _FitnessTabContentState extends State<_FitnessTabContent> {
  List<Map<String, dynamic>> _trainers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.getTrainers();
    if (mounted) setState(() { _trainers = data; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Fitness Trainers',
                  style: TextStyle(color: isDark ? themeColor : Colors.black, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildSkeleton(context, isDark)
                : RefreshIndicator(
                    color: themeColor,
                    backgroundColor: Theme.of(context).cardColor,
                    onRefresh: _load,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _trainers.length,
                      itemBuilder: (context, index) {
                        final t = _trainers[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => FitnessTrainerDetailPage(trainer: t))),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: themeColor,
                                    backgroundImage: (t['image_url'] ?? '').isNotEmpty
                                        ? NetworkImage(t['image_url']) : null,
                                    child: (t['image_url'] ?? '').isEmpty
                                        ? const Icon(Icons.person, color: Colors.black, size: 30) : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t['name'] ?? '',
                                            style: TextStyle(
                                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                                fontSize: 17, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 3),
                                        Text(t['training_type'] ?? '',
                                            style: TextStyle(
                                                color: Theme.of(context).textTheme.bodySmall?.color,
                                                fontSize: 13)),
                                        const SizedBox(height: 3),
                                        Text('${t['experience']} experience',
                                            style: TextStyle(color: themeColor, fontSize: 12, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.people_outline, size: 13, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text('${t['active_clients'] ?? 0} clients',
                                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.check_circle_outline, size: 13, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text('${t['training_completed'] ?? 0} sessions',
                                                style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(8)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star, size: 12, color: Colors.black),
                                            const SizedBox(width: 3),
                                            Text(t['rating'].toString(),
                                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Icon(Icons.arrow_forward_ios,
                                          size: 14, color: Theme.of(context).textTheme.bodyLarge?.color),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context, bool isDark) {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.all(4.0),
        child: _ShimmerWidget(
          child: Container(
            height: 90,
            decoration: BoxDecoration(
                color: isDark ? const Color(0xff3a3a3a) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                      color: isDark ? const Color(0xff4a4a4a) : Colors.grey.shade400,
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 130, height: 14,
                      decoration: BoxDecoration(
                          color: isDark ? const Color(0xff4a4a4a) : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 90, height: 10,
                      decoration: BoxDecoration(
                          color: isDark ? const Color(0xff4a4a4a) : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(6)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerWidget extends StatefulWidget {
  final Widget child;
  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _animation, child: widget.child);
}