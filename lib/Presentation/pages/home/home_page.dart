import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setting/setting_home_page.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_tab_content.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Presentation/pages/fitnes_trainer/fitness_tainer_detail_page.dart';
import 'package:get_fit/Presentation/pages/runner/runner_page.dart';
import 'package:get_fit/Presentation/pages/gym/gym_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_fit/Services/supabase_service.dart';
import 'package:get_fit/Presentation/pages/fitnes_trainer/trainer_booking_detail_page.dart';
import 'package:get_fit/Presentation/pages/yoga/session_detail_page.dart';

Color _accent(BuildContext context) {
  return context.isDark ? themeColor : const Color(0xFF6B7A00);
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
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
              Expanded(
                  child: _skeletonBox(context,
                      width: double.infinity, height: 160, radius: 16)),
              const SizedBox(width: 16),
              Expanded(
                  child: _skeletonBox(context,
                      width: double.infinity, height: 160, radius: 16)),
            ],
          ),
          const SizedBox(height: 20),
          _skeletonBox(context, width: double.infinity, height: 194, radius: 16),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _skeletonBox(BuildContext context,
      {required double width, required double height, double radius = 8}) {
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
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
              Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) {
            final isSelected = _selectedTab == i;
            final unselectedColor =
                isDark ? Colors.white54 : Colors.grey.shade600;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_tabs[i]['icon'] as IconData,
                      color: isSelected
                          ? (isDark ? themeColor : Colors.black)
                          : unselectedColor),
                  const SizedBox(height: 4),
                  Text(_tabs[i]['label'] as String,
                      style: TextStyle(
                          color: isSelected
                              ? (isDark ? themeColor : Colors.black)
                              : unselectedColor,
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

  // ── Trainer slot bookings ──
  List<Map<String, dynamic>> _trainerBookings = [];
  bool _loadingTrainer = true;

  // ── Yoga session bookings ──
  List<Map<String, dynamic>> _allYogaBookings = [];
  int _yogaVisible = 3;
  bool _loadingYoga = true;

  // Live countdown ticker
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _fetchUsername();
    _fetchTrainerBookings();
    _fetchYogaBookings();
    _ticker =
        Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── Fetch trainer slot bookings (upcoming + confirmed only) ──
  Future<void> _fetchTrainerBookings() async {
  setState(() => _loadingTrainer = true);
  try {
    final res = await SupabaseService.getUpcomingTrainerBookings();
    final now = DateTime.now();
    // Filter out slots whose end time has already passed today
    final filtered = res.where((booking) {
      try {
        final dateStr = booking['booking_date'] as String;
        final endStr = booking['end_time'] as String;
        final parts = endStr.split(':');
        final d = DateTime.parse(dateStr);
        final end = DateTime(d.year, d.month, d.day,
            int.parse(parts[0]), int.parse(parts[1]));
        return now.isBefore(end); // only keep if not ended yet
      } catch (_) {
        return true;
      }
    }).toList();
    if (mounted) setState(() {
      _trainerBookings = filtered;
      _loadingTrainer = false;
    });
  } catch (_) {
    if (mounted) setState(() => _loadingTrainer = false);
  }
}

  // ── Fetch yoga session bookings ──
  Future<void> _fetchYogaBookings() async {
  setState(() => _loadingYoga = true);
  try {
    final res = await SupabaseService.getMyYogaBookings();
    final today = DateTime.now();
    final todayClean = DateTime(today.year, today.month, today.day);
    final filtered = res.where((b) {
      final status = b['status'] as String? ?? '';
      if (status == 'cancelled' || status == 'completed') return false;
      // Keep if start_date is today or future
      try {
        final d = DateTime.parse(b['start_date'] as String);
        final startDay = DateTime(d.year, d.month, d.day);
        return !startDay.isBefore(todayClean);
      } catch (_) {
        return true;
      }
    }).toList();
    if (mounted) setState(() {
      _allYogaBookings = filtered;
      _loadingYoga = false;
    });
  } catch (_) {
    if (mounted) setState(() => _loadingYoga = false);
  }
}

  Future<void> _fetchUsername() async {
    final data = await SupabaseService.getUserProfile();
    if (mounted) setState(() {
      _username = data?['username'] ?? 'User';
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _yogaVisible = 3);
    await Future.wait([
      _fetchUsername(),
      _fetchTrainerBookings(),
      _fetchYogaBookings(),
    ]);
  }

  // ── Time helpers ──

  String _timeLeft(String? startDate) {
    if (startDate == null) return '';
    try {
      final d = DateTime.parse(startDate);
      final now = DateTime.now();
      final diff = d.difference(DateTime(now.year, now.month, now.day));
      if (diff.inDays == 0) return 'Today';
      if (diff.inDays == 1) return 'Tomorrow';
      if (diff.inDays < 0) return 'Started';
      return 'In ${diff.inDays} days';
    } catch (_) {
      return '';
    }
  }

  Color _timeLeftColor(String? startDate) {
    if (startDate == null) return Colors.grey;
    try {
      final d = DateTime.parse(startDate);
      final now = DateTime.now();
      final diff =
          d.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (diff <= 0) return Colors.green;
      if (diff <= 2) return Colors.orange;
      return Colors.blue;
    } catch (_) {
      return Colors.grey;
    }
  }

  /// Countdown string for a trainer slot booking
  /// Returns null if not today or already started
  String? _trainerCountdown(Map<String, dynamic> booking) {
    try {
      final dateStr = booking['booking_date'] as String;
      final startStr = booking['start_time'] as String;
      final endStr = booking['end_time'] as String;
      final parts = startStr.split(':');
      final endParts = endStr.split(':');
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      final start = DateTime(
          d.year, d.month, d.day, int.parse(parts[0]), int.parse(parts[1]));
      final end = DateTime(d.year, d.month, d.day, int.parse(endParts[0]),
          int.parse(endParts[1]));

      if (now.isAfter(end)) return 'Ended';
      if (now.isAfter(start) && now.isBefore(end)) return 'LIVE NOW';

      final diff = start.difference(now);
      if (diff.inDays > 0) return null; // not today
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      final s = diff.inSeconds % 60;
      if (h > 0) return '${h}h ${m}m';
      return '${m}m ${s}s';
    } catch (_) {
      return null;
    }
  }

  bool _isTrainerSlotLive(Map<String, dynamic> booking) {
    try {
      final dateStr = booking['booking_date'] as String;
      final startStr = booking['start_time'] as String;
      final endStr = booking['end_time'] as String;
      final parts = startStr.split(':');
      final endParts = endStr.split(':');
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      final start = DateTime(
          d.year, d.month, d.day, int.parse(parts[0]), int.parse(parts[1]));
      final end = DateTime(d.year, d.month, d.day, int.parse(endParts[0]),
          int.parse(endParts[1]));
      return now.isAfter(start) && now.isBefore(end);
    } catch (_) {
      return false;
    }
  }

  /// Countdown string for a yoga booking (start_date is date only)
  String? _yogaCountdown(String? startDate) {
    if (startDate == null) return null;
    try {
      final d = DateTime.parse(startDate);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startDay = DateTime(d.year, d.month, d.day);
      if (startDay.isAfter(today)) return null; // future days, show timeLeft badge instead
      if (startDay.isBefore(today)) return 'Started';
      // same day
      final diff = d.difference(now);
      if (diff.isNegative) return 'Today';
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      final s = diff.inSeconds % 60;
      if (h > 0) return '${h}h ${m}m';
      return '${m}m ${s}s';
    } catch (_) {
      return null;
    }
  }

  String _fmtTime(String t) {
    final parts = t.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final period = h >= 12 ? 'PM' : 'AM';
    final h12 = h > 12 ? h - 12 : h == 0 ? 12 : h;
    return '$h12:$m $period';
  }

  String _fmtBookingDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(context);
    final visibleYoga = _allYogaBookings.take(_yogaVisible).toList();
    final hasMoreYoga = _yogaVisible < _allYogaBookings.length;

    return RefreshIndicator(
      color: accent,
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
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.search,
                            color: isDark ? themeColor : Colors.black),
                        const SizedBox(width: 10),
                        Icon(Icons.notifications,
                            color: isDark ? themeColor : Colors.black),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const SettingHomePage())),
                          child: Icon(Icons.settings,
                              color: isDark ? themeColor : Colors.black),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Workout banner ──
              const SizedBox(height: 20),
              Container(
                height: 80,
                decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Image.asset("assets/home/fire.png",
                          width: 50, height: 50),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Workout Today",
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            const SizedBox(height: 2),
                            Text("let's achieve your target today",
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black.withOpacity(0.7))),
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
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),

              // Steps & Calories cards
              Row(
                children: [
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 160,
                          padding:
                              const EdgeInsets.fromLTRB(16, 36, 16, 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[200]
                                : const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                      "assets/icons/steps_icon.svg",
                                      width: 16,
                                      height: 16,
                                      colorFilter: ColorFilter.mode(
                                          isDark
                                              ? Colors.black
                                              : Colors.white,
                                          BlendMode.srcIn)),
                                  const SizedBox(width: 6),
                                  Text("Steps",
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.black
                                              : Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("5000",
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? const Color.fromARGB(
                                                      255, 210, 231, 16)
                                                  : themeColor)),
                                      Text("/10000",
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: isDark
                                                  ? Colors.black
                                                  : Colors.white)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          SvgPicture.asset(
                                              "assets/icons/clock_icon.svg",
                                              width: 12,
                                              height: 12,
                                              colorFilter: ColorFilter.mode(
                                                  isDark
                                                      ? Colors.black
                                                      : Colors.white,
                                                  BlendMode.srcIn)),
                                          const SizedBox(width: 4),
                                          Text("Last",
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.black
                                                      : Colors.white)),
                                        ],
                                      ),
                                      Text("7 Days",
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? Colors.black
                                                  : Colors.white)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -30,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
                                  shape: BoxShape.circle),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                    color: themeColor,
                                    shape: BoxShape.circle),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                      "assets/home/container-1-icon.png",
                                      height: 36,
                                      width: 36,
                                      fit: BoxFit.contain),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 160,
                          padding:
                              const EdgeInsets.fromLTRB(16, 36, 16, 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[200]
                                : const Color(0xFF2C2C2C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                      "assets/icons/calories_icon.svg",
                                      width: 16,
                                      height: 16,
                                      colorFilter: ColorFilter.mode(
                                          isDark
                                              ? Colors.black
                                              : Colors.white,
                                          BlendMode.srcIn)),
                                  const SizedBox(width: 6),
                                  Text("Calories",
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.black
                                              : Colors.white)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("1500",
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? const Color.fromARGB(
                                                      255, 210, 231, 16)
                                                  : themeColor)),
                                      Text("2000 Days",
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? Colors.black
                                                  : Colors.white)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Row(
                                        children: [
                                          SvgPicture.asset(
                                              "assets/icons/clock_icon.svg",
                                              width: 12,
                                              height: 12,
                                              colorFilter: ColorFilter.mode(
                                                  isDark
                                                      ? Colors.black
                                                      : Colors.white,
                                                  BlendMode.srcIn)),
                                          const SizedBox(width: 4),
                                          Text("Last",
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark
                                                      ? Colors.black
                                                      : Colors.white)),
                                        ],
                                      ),
                                      Text("7 Days",
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? Colors.black
                                                  : Colors.white)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: -30,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
                                  shape: BoxShape.circle),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: const BoxDecoration(
                                    color: themeColor,
                                    shape: BoxShape.circle),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                      "assets/home/container-2-icon.png",
                                      height: 36,
                                      width: 36,
                                      fit: BoxFit.contain),
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

              // ── Yoga promo banner ──
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () => widget.onTabSwitch(2),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 194,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: themeColor,
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Next Upcoming Class",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            const Text("Yoga",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 25)),
                            const Text("Time: 2h:20m",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 17)),
                            const Spacer(),
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () => widget.onTabSwitch(2),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                ),
                                child: const Text("Join Now",
                                    style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -23,
                      left: 0,
                      right: -75,
                      child: Image.asset("assets/home/yoga-girl.png",
                          height: 223, width: 150),
                    ),
                  ],
                ),
              ),

              // ── Trainer promo banner ──
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => widget.onTabSwitch(1),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C2C2C)
                        : Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 100, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Next Training Session",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Fitness Trainer",
                                style: TextStyle(
                                    color: themeColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Personal & Group Sessions",
                                style: TextStyle(
                                    color:
                                        Colors.white.withOpacity(0.6),
                                    fontSize: 14)),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: 110,
                              height: 38,
                              child: ElevatedButton(
                                onPressed: () =>
                                    widget.onTabSwitch(1),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20)),
                                ),
                                child: const Text("Book Now",
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -48,
                        right: -15,
                        left: 0,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Image.asset(
                              "assets/home/trainer-man.png",
                              height: 240,
                              width: 250),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ══════════════════════════════════════
              // UPCOMING CLASSES & BOOKINGS SECTION
              // ══════════════════════════════════════
              const SizedBox(height: 28),
              Text("Upcoming Classes & Bookings",
                  style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),

              // ── YOGA SESSIONS ──────────────────────
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.self_improvement_outlined,
                      color: accent, size: 16),
                  const SizedBox(width: 6),
                  Text("Yoga Sessions",
                      style: TextStyle(
                          color: accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${_allYogaBookings.length} booked',
                      style: TextStyle(
                          color: accent.withOpacity(0.7),
                          fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),

              if (_loadingYoga)
                _buildYogaSkeleton(context, accent)
              else if (_allYogaBookings.isEmpty)
                GestureDetector(
                  onTap: () => widget.onTabSwitch(2),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.self_improvement_outlined,
                            color: accent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                              "No upcoming yoga sessions. Book one!",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                  fontSize: 13)),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: accent, size: 14),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ...visibleYoga.map((booking) {
                      final instructor = booking['yoga_instructors']
                          as Map<String, dynamic>?;
                      final insName =
                          instructor?['name'] ?? 'Instructor';
                      final insImage =
                          instructor?['image_url'] ?? '';
                      final insSpecialty =
                          instructor?['specialty'] ?? '';
                      final startDate =
                          booking['start_date'] as String?;
                      final numSessions =
                          booking['num_sessions'] ?? 0;
                      final status =
                          booking['status'] ?? 'pending';
                      final timeLeft = _timeLeft(startDate);
                      final timeColor = _timeLeftColor(startDate);
                      final countdown = _yogaCountdown(startDate);
                      final isToday = timeLeft == 'Today';

                      return GestureDetector(
                        onTap: () {
                          final instructorData =
                              booking['yoga_instructors']
                                      as Map<String, dynamic>? ??
                                  {};
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SessionDetailPage(
                                booking: booking,
                                instructor: instructorData,
                              ),
                            ),
                          ).then((_) => _onRefresh());
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isToday
                                  ? accent.withOpacity(0.4)
                                  : accent.withOpacity(0.15),
                              width: isToday ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 26,
                                backgroundColor:
                                    accent.withOpacity(0.2),
                                backgroundImage: insImage.isNotEmpty
                                    ? NetworkImage(insImage)
                                    : null,
                                child: insImage.isEmpty
                                    ? Icon(Icons.person,
                                        color: accent, size: 22)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(insName,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                            fontWeight:
                                                FontWeight.bold,
                                            fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(insSpecialty,
                                        style: TextStyle(
                                            color: accent,
                                            fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      const Icon(
                                          Icons.event_outlined,
                                          size: 11,
                                          color: Colors.grey),
                                      const SizedBox(width: 3),
                                      Text(startDate ?? '',
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11)),
                                      const SizedBox(width: 10),
                                      const Icon(
                                          Icons.layers_outlined,
                                          size: 11,
                                          color: Colors.grey),
                                      const SizedBox(width: 3),
                                      Text('$numSessions sessions',
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11)),
                                    ]),
                                    // Countdown for today
                                    if (countdown != null &&
                                        isToday) ...[
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const Icon(
                                            Icons.timer_outlined,
                                            size: 11,
                                            color: Colors.orange),
                                        const SizedBox(width: 3),
                                        Text(
                                          countdown == 'Today'
                                              ? 'Today'
                                              : 'In $countdown',
                                          style: const TextStyle(
                                              color: Colors.orange,
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.bold),
                                        ),
                                      ]),
                                    ],
                                  ],
                                ),
                              ),
                              // Right badges
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3),
                                    decoration: BoxDecoration(
                                      color: timeColor.withOpacity(
                                          0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(timeLeft,
                                        style: TextStyle(
                                            color: timeColor,
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3),
                                    decoration: BoxDecoration(
                                      color: status == 'confirmed' ||
                                              status == 'active'
                                          ? Colors.green
                                              .withOpacity(0.12)
                                          : themeColor
                                              .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: status ==
                                                    'confirmed' ||
                                                status == 'active'
                                            ? Colors.green
                                            : accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Icon(Icons.arrow_forward_ios,
                                      size: 11,
                                      color:
                                          accent.withOpacity(0.5)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Load more / collapse
                    if (hasMoreYoga)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _yogaVisible += 3),
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: accent.withOpacity(0.4)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.expand_more,
                                  color: accent, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Load ${(_allYogaBookings.length - _yogaVisible).clamp(0, 3)} more',
                                style: TextStyle(
                                    color: accent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_allYogaBookings.length > 3)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _yogaVisible = 3),
                        child: Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color:
                                    Colors.grey.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.expand_less,
                                  color: Colors.grey, size: 18),
                              const SizedBox(width: 6),
                              const Text('Show less',
                                  style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

              // ── TRAINER SLOT BOOKINGS ──────────────
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.fitness_center_outlined,
                      color: accent, size: 16),
                  const SizedBox(width: 6),
                  Text("Trainer Sessions",
                      style: TextStyle(
                          color: accent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${_trainerBookings.length} upcoming',
                      style: TextStyle(
                          color: accent.withOpacity(0.7),
                          fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),

              if (_loadingTrainer)
                Center(
                    child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                      color: accent, strokeWidth: 2),
                ))
              else if (_trainerBookings.isEmpty)
                GestureDetector(
                  onTap: () => widget.onTabSwitch(1),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.fitness_center,
                            color: accent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                              "No upcoming sessions. Book a trainer!",
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                  fontSize: 13)),
                        ),
                        Icon(Icons.arrow_forward_ios,
                            color: accent, size: 14),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: _trainerBookings.take(3).map((booking) {
                    final trainer =
                        booking['fitness_trainers']
                                as Map<String, dynamic>? ??
                            {};
                    final imageUrl =
                        trainer['image_url'] as String? ?? '';
                    final dateStr =
                        booking['booking_date'] as String? ?? '';
                    final startTime =
                        booking['start_time'] as String? ?? '';
                    final endTime =
                        booking['end_time'] as String? ?? '';
                    final price =
                        (booking['price'] as num?)?.toDouble() ??
                            0.0;
                    final status =
                        booking['status'] as String? ?? 'confirmed';
                    final countdown = _trainerCountdown(booking);
                    final isLive = _isTrainerSlotLive(booking);

                    Color statusColor;
                    String statusLabel;
                    if (isLive) {
                      statusColor = Colors.green;
                      statusLabel = 'LIVE';
                    } else if (status == 'attended') {
                      statusColor = Colors.green;
                      statusLabel = 'ATTENDED';
                    } else {
                      statusColor = accent;
                      statusLabel = 'UPCOMING';
                    }

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TrainerBookingDetailPage(
                            booking: booking,
                            trainer: trainer,
                          ),
                        ),
                      ).then((_) => _onRefresh()),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isLive
                                ? Colors.green.withOpacity(0.5)
                                : accent.withOpacity(0.15),
                            width: isLive ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: themeColor,
                              backgroundImage: imageUrl.isNotEmpty
                                  ? NetworkImage(imageUrl)
                                  : null,
                              child: imageUrl.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.black, size: 22)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      trainer['name'] ?? 'Trainer',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                      trainer['training_type'] ?? '',
                                      style: TextStyle(
                                          color: accent,
                                          fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(
                                        Icons.calendar_today,
                                        color: Colors.grey,
                                        size: 11),
                                    const SizedBox(width: 3),
                                    Text(_fmtBookingDate(dateStr),
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11)),
                                  ]),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    const Icon(Icons.access_time,
                                        color: Colors.grey, size: 11),
                                    const SizedBox(width: 3),
                                    Text(
                                        '${_fmtTime(startTime)} → ${_fmtTime(endTime)}',
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11)),
                                  ]),
                                  // Countdown
                                  if (countdown != null) ...[
                                    const SizedBox(height: 4),
                                    Row(children: [
                                      Icon(
                                        isLive
                                            ? Icons
                                                .radio_button_checked
                                            : Icons.timer_outlined,
                                        size: 11,
                                        color: isLive
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        isLive
                                            ? 'Live Now — tap to join'
                                            : 'Starts in $countdown',
                                        style: TextStyle(
                                          color: isLive
                                              ? Colors.green
                                              : Colors.orange,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ]),
                                  ],
                                ],
                              ),
                            ),
                            // Right side
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: themeColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(
                                        isLive ? 0.2 : 0.12),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: isLive
                                        ? Border.all(
                                            color: Colors.green
                                                .withOpacity(0.5))
                                        : null,
                                  ),
                                  child: Text(statusLabel,
                                      style: TextStyle(
                                          color: statusColor,
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight.bold)),
                                ),
                                const SizedBox(height: 6),
                                Icon(Icons.arrow_forward_ios,
                                    size: 11,
                                    color: accent.withOpacity(0.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYogaSkeleton(BuildContext context, Color accent) {
    return Column(
      children: List.generate(
          2,
          (_) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xff3a3a3a)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                ),
              )),
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
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  static const int _pageSize = 9;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _page = 0;
      _hasMore = true;
      _trainers = [];
    });
    final data =
        await SupabaseService.getTrainers(page: 0, pageSize: _pageSize);
    if (mounted) setState(() {
      _trainers = data;
      _isLoading = false;
      _hasMore = data.length == _pageSize;
      _page = 1;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    final data = await SupabaseService.getTrainers(
        page: _page, pageSize: _pageSize);
    if (mounted) setState(() {
      _trainers.addAll(data);
      _isLoadingMore = false;
      _hasMore = data.length == _pageSize;
      _page++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _accent(context);
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Fitness Trainers',
                  style: TextStyle(
                      color: isDark ? themeColor : Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: _isLoading
                ? _buildSkeleton(context, isDark)
                : RefreshIndicator(
                    color: accent,
                    backgroundColor: Theme.of(context).cardColor,
                    onRefresh: _load,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _trainers.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _trainers.length) {
                          if (_isLoadingMore) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20),
                              child: Center(
                                  child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                    color: accent, strokeWidth: 2.5),
                              )),
                            );
                          }
                          if (!_hasMore) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20),
                              child: Center(
                                  child: Text('All trainers loaded',
                                      style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13))),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 4),
                            child: OutlinedButton(
                              onPressed: _loadMore,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accent,
                                side: BorderSide(color: accent),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                              child: const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.expand_more, size: 18),
                                  SizedBox(width: 6),
                                  Text('Show More',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        }
                        final t = _trainers[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 6),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        FitnessTrainerDetailPage(
                                            trainer: t))),
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius:
                                      BorderRadius.circular(16)),
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: themeColor,
                                    backgroundImage:
                                        (t['image_url'] ?? '')
                                                .isNotEmpty
                                            ? NetworkImage(
                                                t['image_url'])
                                            : null,
                                    child: (t['image_url'] ?? '')
                                            .isEmpty
                                        ? const Icon(Icons.person,
                                            color: Colors.black,
                                            size: 30)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(t['name'] ?? '',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color,
                                                fontSize: 17,
                                                fontWeight:
                                                    FontWeight.bold)),
                                        const SizedBox(height: 3),
                                        Text(
                                            t['training_type'] ?? '',
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color,
                                                fontSize: 13)),
                                        const SizedBox(height: 3),
                                        Text(
                                            '${t['experience']} experience',
                                            style: TextStyle(
                                                color: accent,
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w500)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons.people_outline,
                                                size: 13,
                                                color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                                '${t['active_clients'] ?? 0} clients',
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12)),
                                            const SizedBox(width: 12),
                                            const Icon(
                                                Icons
                                                    .check_circle_outline,
                                                size: 13,
                                                color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                                '${t['training_completed'] ?? 0} sessions',
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                            color: themeColor,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    8)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star,
                                                size: 12,
                                                color: Colors.black),
                                            const SizedBox(width: 3),
                                            Text(
                                                t['rating'].toString(),
                                                style: const TextStyle(
                                                    color: Colors.black,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Icon(Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color),
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
                color: isDark
                    ? const Color(0xff3a3a3a)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xff4a4a4a)
                          : Colors.grey.shade400,
                      shape: BoxShape.circle),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 130,
                      height: 14,
                      decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xff4a4a4a)
                              : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 90,
                      height: 10,
                      decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xff4a4a4a)
                              : Colors.grey.shade400,
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

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _animation, child: widget.child);
}