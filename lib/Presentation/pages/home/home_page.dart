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
import 'package:get_fit/Services/notification_service.dart';
import 'package:get_fit/Presentation/pages/setting/notifications_page.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_detail_page.dart';

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

  // ── Activity summary ──
  int _totalKcal7d = 0;
  bool _loadingActivity = true;

  // Live countdown ticker
  Timer? _ticker;

  // How many trainer bookings are currently shown (starts at 3, grows by 3)
  int _visibleBookingCount = 3;

  @override
void initState() {
  super.initState();
  _fetchUsername();
  _fetchTrainerBookings();
  _fetchActivitySummary();
  // Ticker fires every second — forces full rebuild of countdown text
  _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
    if (mounted) setState(() {}); // empty setState is enough — build() re-runs
  });
}

@override
void dispose() {
  _ticker?.cancel();
  _ticker = null;
  super.dispose();
}

  // ── Fetch trainer slot bookings (upcoming + confirmed only) ──
  Future<void> _fetchTrainerBookings() async {
  setState(() => _loadingTrainer = true);
  try {
    final res = await SupabaseService.getUpcomingTrainerAppointments();
    final now = DateTime.now();
    // Filter: keep only if appointment end time hasn't passed yet
    final filtered = res.where((booking) {
      try {
        final dateStr = booking['appointment_date'] as String;
        final endStr = booking['end_time'] as String;
        final parts = endStr.split(':');
        final d = DateTime.parse(dateStr);
        final end = DateTime(d.year, d.month, d.day,
            int.parse(parts[0]), int.parse(parts[1]));
        // Keep only if current time is before end time
        final isActive = now.isBefore(end);
        debugPrint('\x1B[33m[FILTER] $dateStr ${endStr} → active=$isActive (now: $now, end: $end)\x1B[0m');
        return isActive;
      } catch (e) {
        debugPrint('\x1B[31m[FILTER] Parse error: $e\x1B[0m');
        return false; // <-- FIX: discard broken data instead of keeping it
      }
    }).toList();
    if (mounted) setState(() {
      _trainerBookings = filtered;
      _loadingTrainer = false;
      _visibleBookingCount = 3;
    });
  } catch (_) {
    if (mounted) setState(() => _loadingTrainer = false);
  }
}

  Future<void> _fetchActivitySummary() async {
    setState(() => _loadingActivity = true);
    try {
      final raw = await SupabaseService.getActivityStats(days: 7);
      debugPrint('\x1B[33m[ACTIVITY] raw=${raw.length} rows: $raw\x1B[0m');
      int total = 0;
      for (final day in raw) {
        total += (day['challengeKcal'] as int) +
                 (day['gymKcal'] as int);
      }
      if (mounted) setState(() {
        _totalKcal7d = total;
        _loadingActivity = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingActivity = false);
    }
  }

  Future<void> _fetchUsername() async {
    final data = await SupabaseService.getUserProfile();
    if (mounted) setState(() {
      _username = data?['username'] ?? 'User';
    });
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _fetchUsername(),
      _fetchTrainerBookings(),
      _fetchActivitySummary(),
    ]);
  }

  /// Countdown string for a trainer slot booking
  /// Returns null if not today or already started
  String? _trainerCountdown(Map<String, dynamic> booking) {
    try {
      final dateStr = booking['appointment_date'] as String;
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
      if (diff.isNegative) return null;
      final days = diff.inDays;
      final h = diff.inHours % 24;
      final m = diff.inMinutes % 60;
      final s = diff.inSeconds % 60;
      if (days > 0) return '${days}d ${h}h';
      if (h > 0) return '${h}h ${m}m';
      return '${m}m ${s}s';
    } catch (_) {
      return null;
    }
  }

void _handleBannerTap(BuildContext context) {
    if (_trainerBookings.isEmpty) {
      widget.onTabSwitch(1); // no appointment — go to Yoga tab as before
      return;
    }
    final booking = _trainerBookings.first;
    final trainer =
        booking['fitness_trainers'] as Map<String, dynamic>? ?? {};
    final dateStr = booking['appointment_date'] as String? ?? '';
    final startTime = booking['start_time'] as String? ?? '';
    final endTime = booking['end_time'] as String? ?? '';
    final price = (booking['price'] as num?)?.toDouble() ?? 0.0;
    final isLive = _isTrainerSlotLive(booking);
    final countdown = _trainerCountdown(booking);
    _showBookingSummary(
      context: context,
      booking: booking,
      trainer: trainer,
      accent: _accent(context),
      statusColor: isLive ? Colors.green : _accent(context),
      statusLabel: isLive ? 'LIVE' : 'UPCOMING',
      countdown: countdown,
      isLive: isLive,
      dateStr: dateStr,
      startTime: startTime,
      endTime: endTime,
      price: price,
    );
  }

  /// Countdown text for the very next upcoming appointment (any day),
  /// used in the Yoga promo banner. Returns 'Live now' if in progress,
  /// or null if there's no upcoming appointment at all.
  String? _nextAppointmentCountdownText() {
    if (_trainerBookings.isEmpty) return null;
    try {
      final booking = _trainerBookings.first; // list is sorted ascending
      final dateStr = booking['appointment_date'] as String;
      final startStr = booking['start_time'] as String;
      final endStr = booking['end_time'] as String;
      final d = DateTime.parse(dateStr);
      final now = DateTime.now();
      final startParts = startStr.split(':');
      final endParts = endStr.split(':');
      final start = DateTime(d.year, d.month, d.day,
          int.parse(startParts[0]), int.parse(startParts[1]));
      final end = DateTime(d.year, d.month, d.day,
          int.parse(endParts[0]), int.parse(endParts[1]));

      if (now.isAfter(start) && now.isBefore(end)) return 'Live now';

      final diff = start.difference(now);
      if (diff.isNegative) return null;
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final mins = diff.inMinutes % 60;
      if (days > 0) return '${days}d ${hours}h';
      if (hours > 0) return '${hours}h ${mins}m';
      return '${mins}m ${diff.inSeconds % 60}s';
    } catch (_) {
      return null;
    }
  }

  bool _isTrainerSlotLive(Map<String, dynamic> booking) {
    try {
      final dateStr = booking['appointment_date'] as String;
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
      final year = dt.year.toString().substring(2); // "26" or "27"
      return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}\'$year';
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
                        InkWell(
                          onTap: () => showDialog(
                            context: context,
                            barrierColor: Colors.black87,
                            builder: (_) => _GlobalSearchDialog(
                              onTabSwitch: widget.onTabSwitch,
                            ),
                          ),
                          child: Icon(Icons.search,
                              color: isDark ? themeColor : Colors.black),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const NotificationsPage())),
                          child: Icon(Icons.notifications,
                              color: isDark ? themeColor : Colors.black),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const SettingHomePage())),
                          child: Icon(Icons.settings,
                              color: isDark ? themeColor : Colors.black),
                        ),
                        /* ───── TEST NOTIFICATION BUTTON (commented out) ─────
                           Uncomment this whole block anytime you want to test
                           notifications — it schedules one 2 minutes from now.
                           Don't forget to hot restart after uncommenting.

                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () async {
                            await NotificationService.scheduleTestReminder();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Test notification scheduled for 2 minutes from now')),
                              );
                            }
                          },
                          child: const Icon(Icons.bug_report, color: Colors.red),
                        ),
                        ──── END TEST NOTIFICATION BUTTON ───── */
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
                                      Text(
                                        _loadingActivity
                                            ? '0'
                                            : '${(_totalKcal7d* 0.1).round() < 100 ? 0 : (_totalKcal7d * 0.1).round()}',
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? const Color.fromARGB(
                                                      255, 210, 231, 16)
                                                  : themeColor)),
                                      Text('/${(_totalKcal7d * 0.1).round() > 10000 ? 140000 : 10000} steps',
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
                                      Text(
                                          _loadingActivity ? '0' : '${_totalKcal7d < 0 ? 0 : _totalKcal7d}',
                                          style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? const Color.fromARGB(
                                                      255, 210, 231, 16)
                                                  : themeColor)),
                                      Text('/${_totalKcal7d > 2000 ? '20000' : '2000'} kcal',
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
                onTap: () => _handleBannerTap(context),
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
                            Text(
                                _trainerBookings.isEmpty
                                    ? "Next Upcoming Your"
                                    : "Next Appointment",
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 5),
                            Text(
                                _trainerBookings.isEmpty
                                    ? "Appointment"
                                    : (_trainerBookings.first['fitness_trainers']
                                            as Map<String, dynamic>?)?['name'] ??
                                        "Trainer",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 25)),
                            Text(
                                _nextAppointmentCountdownText() == null
                                    ? "Explore Fitness classes"
                                    : _nextAppointmentCountdownText() ==
                                            'Live now'
                                        ? "Live now"
                                        : "Starts in ${_nextAppointmentCountdownText()}",
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 17)),
                            const Spacer(),
                            SizedBox(
                              width: 100,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () => _handleBannerTap(context),
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
                      right: -105,
                      child: Image.asset("assets/home/yoga-girl.png",
                          height: 223, width: 150),
                    ),
                  ],
                ),
              ),
              // ══════════════════════════════════════
              // UPCOMING CLASSES & BOOKINGS SECTION
              // ══════════════════════════════════════
              const SizedBox(height: 28),
              Text("Upcoming Appointments",
                  style: TextStyle(
                      color:
                          Theme.of(context).textTheme.bodyLarge?.color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),


              // ── TRAINER SLOT BOOKINGS ──────────────
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.fitness_center_outlined,
                      color: accent, size: 16),
                  const SizedBox(width: 6),
                  Text("Your Schedule",
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
                              "No upcoming Appointments. Book an appointment.",
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
                    ..._trainerBookings.take(_visibleBookingCount).map((booking) {
                    final trainer =
                        booking['fitness_trainers']
                                as Map<String, dynamic>? ??
                            {};
                    final imageUrl =
                        trainer['image_url'] as String? ?? '';
                    final dateStr =
                        booking['appointment_date'] as String? ?? '';
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
                      onTap: () => _showBookingSummary(
                        context: context,
                        booking: booking,
                        trainer: trainer,
                        accent: accent,
                        statusColor: statusColor,
                        statusLabel: statusLabel,
                        countdown: countdown,
                        isLive: isLive,
                        dateStr: dateStr,
                        startTime: startTime,
                        endTime: endTime,
                        price: price,
                      ),
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
                  }),
                    if (_trainerBookings.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_visibleBookingCount < _trainerBookings.length)
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  _visibleBookingCount =
                                      (_visibleBookingCount + 3)
                                          .clamp(0, _trainerBookings.length);
                                }),
                                icon: Icon(Icons.expand_more, color: accent, size: 18),
                                label: Text('Show more',
                                    style: TextStyle(
                                        color: accent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                            if (_visibleBookingCount > 3)
                              TextButton.icon(
                                onPressed: () => setState(() => _visibleBookingCount = 3),
                                icon: Icon(Icons.expand_less, color: accent.withOpacity(0.7), size: 18),
                                label: Text('Show less',
                                    style: TextStyle(
                                        color: accent.withOpacity(0.7),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Booking summary dialog ──
  void _showBookingSummary({
    required BuildContext context,
    required Map<String, dynamic> booking,
    required Map<String, dynamic> trainer,
    required Color accent,
    required Color statusColor,
    required String statusLabel,
    required String? countdown,
    required bool isLive,
    required String dateStr,
    required String startTime,
    required String endTime,
    required double price,
  }) {
    final imageUrl = trainer['image_url'] as String? ?? '';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.cardBgColor,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: themeColor,
                backgroundImage:
                    imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl.isEmpty
                    ? const Icon(Icons.person,
                        color: Colors.black, size: 30)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(trainer['name'] ?? 'Trainer',
                  style: TextStyle(
                      color: context.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text(trainer['training_type'] ?? '',
                  style: TextStyle(color: accent, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(isLive ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: isLive
                      ? Border.all(color: Colors.green.withOpacity(0.5))
                      : null,
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              _summaryRow(context, Icons.calendar_today,
                  _fmtBookingDate(dateStr)),
              const SizedBox(height: 8),
              _summaryRow(context, Icons.access_time,
                  '${_fmtTime(startTime)} → ${_fmtTime(endTime)}'),
              const SizedBox(height: 8),
              _summaryRow(context, Icons.attach_money,
                  '\$${price.toStringAsFixed(2)}'),
              if (countdown != null) ...[
                const SizedBox(height: 8),
                _summaryRow(
                  context,
                  isLive ? Icons.radio_button_checked : Icons.timer_outlined,
                  isLive ? 'Live now' : 'Starts in $countdown',
                  color: isLive ? Colors.green : Colors.orange,
                ),
              ],
              const SizedBox(height: 24),
              if (isLive) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _joinCall(
                      context: context,
                      dialogContext: dialogContext,
                      trainerId:
                          (booking['trainer_id'] as String?) ??
                              trainer['id'] as String,
                      trainerName: trainer['name'] ?? 'Trainer',
                    ),
                    icon: const Icon(Icons.video_call, color: Colors.black),
                    label: const Text('Join Call',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openTrainerProfile(
                    context: context,
                    dialogContext: dialogContext,
                    trainerId:
                        (booking['trainer_id'] as String?) ??
                            trainer['id'] as String,
                    fallbackTrainer: trainer,
                  ),
                  icon: const Icon(Icons.person, color: Colors.black),
                  label: const Text('View Trainer Profile',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Close',
                      style: TextStyle(color: context.subtextColor)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTrainerProfile({
    required BuildContext context,
    required BuildContext dialogContext,
    required String trainerId,
    required Map<String, dynamic> fallbackTrainer,
  }) async {
    Navigator.pop(dialogContext);

    // Fetch the FULL trainer record (the booking join only carries a few
    // fields — bio, phone, bg_image_url, id etc. are missing from it).
    final fullTrainer = await SupabaseService.getTrainerById(trainerId);

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FitnessTrainerDetailPage(
          trainer: fullTrainer ?? fallbackTrainer,
        ),
      ),
    );
  }

  void _joinCall({
    required BuildContext context,
    required BuildContext dialogContext,
    required String trainerId,
    required String trainerName,
  }) {
    Navigator.pop(dialogContext);
    // TODO: wire this into the real video-call integration once it's built.
    // trainerId is already available here to pass straight into the call
    // session (e.g. as a channel/room identifier).
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.cardBgColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Icon(Icons.video_call, color: Colors.green, size: 40),
        content: Text(
          'Video call with $trainerName is coming soon.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.textColor, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                  color: themeColor, borderRadius: BorderRadius.circular(10)),
              child: const Text('OK',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(BuildContext context, IconData icon, String text,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? context.subtextColor),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                color: color ?? context.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      ],
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Fitness Trainers',
                    style: TextStyle(
                        color: isDark ? themeColor : Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    InkWell(
                      onTap: () => showDialog(
                        context: context,
                        barrierColor: Colors.black87,
                        builder: (_) => _GlobalSearchDialog(
                          onTabSwitch: (_) {},
                        ),
                      ),
                      child: Icon(Icons.search,
                          color: isDark ? themeColor : Colors.black),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const NotificationsPage())),
                      child: Icon(Icons.notifications,
                          color: isDark ? themeColor : Colors.black),
                    ),
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
                            onTap: () async {
  await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => FitnessTrainerDetailPage(trainer: t)));
  if (mounted) _load();
},
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

// ─────────────────────────────────────────────
// GLOBAL SEARCH DIALOG
// ─────────────────────────────────────────────
class _GlobalSearchDialog extends StatefulWidget {
  final Function(int) onTabSwitch;
  const _GlobalSearchDialog({required this.onTabSwitch});

  @override
  State<_GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<_GlobalSearchDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  bool _hasSearched = false;

  List<Map<String, dynamic>> _trainers = [];
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _yogaClasses = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

 Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _trainers = [];
        _exercises = [];
        _yogaClasses = [];
        _hasSearched = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    final q = query.trim().toLowerCase();

    final results = await Future.wait([
      SupabaseService.getTrainers(pageSize: 20),
      SupabaseService.getGymExercises(pageSize: 20),
      SupabaseService.searchYogaClasses(q),
    ]);

    final trainers = (results[0] as List<Map<String, dynamic>>)
        .where((t) =>
            (t['name'] ?? '').toString().toLowerCase().contains(q) ||
            (t['training_type'] ?? '').toString().toLowerCase().contains(q))
        .toList();

    final exercises = (results[1] as List<Map<String, dynamic>>)
        .where((e) =>
            (e['title'] ?? '').toString().toLowerCase().contains(q) ||
            (e['category'] ?? '').toString().toLowerCase().contains(q))
        .toList();

    if (mounted) {
      setState(() {
        _trainers = trainers;
        _exercises = exercises;
        _yogaClasses = results[2] as List<Map<String, dynamic>>;
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  bool get _hasResults =>
      _trainers.isNotEmpty ||
      _exercises.isNotEmpty ||
      _yogaClasses.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = screenHeight - keyboardHeight - 80;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 40),
      child: SizedBox(
        height: availableHeight.clamp(300.0, screenHeight * 0.88),
        child: Container(
          decoration: BoxDecoration(
            color: context.bgColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.cardBgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          style: TextStyle(color: context.textColor),
                          decoration: InputDecoration(
                            hintText: 'Search trainers, exercises, yoga...',
                            hintStyle: TextStyle(
                                color: context.subtextColor, fontSize: 13),
                            prefixIcon:
                                const Icon(Icons.search, color: themeColor),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onChanged: _search,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('Cancel',
                          style: TextStyle(
                              color: themeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Flexible(
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                            color: themeColor, strokeWidth: 2),
                      )
                    : !_hasSearched
                        ? Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search,
                                    color: themeColor, size: 44),
                                const SizedBox(height: 10),
                                Text('Search the entire app',
                                    style: TextStyle(
                                        color: context.subtextColor,
                                        fontSize: 14)),
                                const SizedBox(height: 6),
                                Text(
                                    'Trainers • Yoga • Gym Exercises • Classes',
                                    style: TextStyle(
                                        color: context.subtextColor
                                            .withOpacity(0.6),
                                        fontSize: 12)),
                              ],
                            ),
                          )
                        : !_hasResults
                            ? Padding(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.search_off,
                                        color: context.subtextColor, size: 44),
                                    const SizedBox(height: 10),
                                    Text('No results found',
                                        style: TextStyle(
                                            color: context.subtextColor,
                                            fontSize: 14)),
                                  ],
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // TRAINERS
                                    if (_trainers.isNotEmpty) ...[
                                      _sectionHeader(context,
                                          Icons.fitness_center, 'Trainers', 1),
                                      const SizedBox(height: 8),
                                      ..._trainers.take(3).map((t) =>
                                          _resultTile(
                                            context,
                                            imageUrl: t['image_url'] ?? '',
                                            title: t['name'] ?? '',
                                            subtitle:
                                                t['training_type'] ?? '',
                                            badge: t['rating']?.toString(),
                                            onTap: () {
                                              final nav = Navigator.of(context);
                                              nav.pop();
                                              widget.onTabSwitch(1);
                                              Future.delayed(
                                                  const Duration(milliseconds: 300),
                                                  () {
                                                nav.push(MaterialPageRoute(
                                                  builder: (_) =>
                                                      FitnessTrainerDetailPage(trainer: t),
                                                ));
                                              });
                                            },
                                          )),
                                      const SizedBox(height: 16),
                                    ],
                                    // GYM EXERCISES
                                    if (_exercises.isNotEmpty) ...[
                                      _sectionHeader(context,
                                          Icons.sports_gymnastics, 'Gym Exercises', 3),
                                      const SizedBox(height: 8),
                                      ..._exercises.take(3).map((e) =>
                                          _resultTile(
                                            context,
                                            imageUrl: e['image_url'] ?? '',
                                            title: e['title'] ?? '',
                                            subtitle: e['category'] ?? '',
                                            badge: e['level'],
                                            onTap: () {
                                              Navigator.pop(context);
                                              widget.onTabSwitch(3);
                                            },
                                          )),
                                      const SizedBox(height: 16),
                                    ],

                                    // YOGA CLASSES
                                    if (_yogaClasses.isNotEmpty) ...[
                                      _sectionHeader(
                                          context,
                                          Icons.class_,
                                          'Yoga Classes',
                                          2),
                                      const SizedBox(height: 8),
                                      ..._yogaClasses.take(3).map((y) =>
                                          _resultTile(
                                            context,
                                            imageUrl: y['image_url'] ?? '',
                                            title: y['title'] ?? '',
                                            subtitle:
                                                y['time_slot'] ?? '',
                                            badge: y['level'],
                                            onTap: () {
                                              final nav = Navigator.of(context);
                                              nav.pop();
                                              widget.onTabSwitch(2);
                                              Future.delayed(
                                                  const Duration(milliseconds: 300),
                                                  () {
                                                nav.push(MaterialPageRoute(
                                                  builder: (_) =>
                                                      YogaDetailPage(yoga: y),
                                                ));
                                              });
                                            },
                                          )),
                                    ],
                                  ],
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
      BuildContext context, IconData icon, String label, int tabIndex) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: themeColor, size: 14),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: context.textColor,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        const Spacer(),
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            widget.onTabSwitch(tabIndex);
          },
          child: Text('See all',
              style: TextStyle(
                  color: themeColor, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _resultTile(
    BuildContext context, {
    required String imageUrl,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      width: 62,
                      height: 62,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgFallback())
                  : _imgFallback(),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: context.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: context.subtextColor, fontSize: 12)),
                  if (badge != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(badge,
                          style: const TextStyle(
                              color: themeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _imgFallback() => Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xff3a3a3a),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.image, color: Colors.white38, size: 26),
      );
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