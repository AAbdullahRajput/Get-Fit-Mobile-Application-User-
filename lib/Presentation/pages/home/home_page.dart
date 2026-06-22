import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setting/setting_home_page.dart';
import 'package:get_fit/Presentation/pages/yoga/yoga_tab_content.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Domain/models/fitness_trainer_model.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/fitness_tainer_detail_page.dart';
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
    {'label': 'Fitness', 'icon': Icons.fitness_center_outlined},
    {'label': 'Yoga', 'icon': Icons.self_improvement_outlined},
    {'label': 'Gym', 'icon': Icons.sports_gymnastics_outlined},
    {'label': 'Running', 'icon': Icons.directions_run_outlined},
  ];

  @override
  bool get wantKeepAlive => true;

  late final List<Widget> _pages = [
    const _OverviewTab(),
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
    return Builder(
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Fitness Trainers',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: contents.length,
                  itemBuilder: (context, index) {
                    final trainer = contents[index];
                    return Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Card(
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: themeColor,
                            radius: 30,
                            backgroundImage: NetworkImage(trainer.image),
                          ),
                          title: Text(
                            trainer.name,
                            style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 18),
                          ),
                          subtitle: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trainer.trainingType,
                                style: TextStyle(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                    fontSize: 14),
                              ),
                              Text(
                                '${trainer.experience} years experience',
                                style: TextStyle(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Icon(Icons.arrow_forward,
                                  color: Theme.of(context).textTheme.bodyLarge?.color),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(trainer.rating,
                                    style: const TextStyle(color: Colors.black)),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => FitnessTrainerDetailPage(
                                  bgImg: trainer.bg_img,
                                  trainerName: trainer.name,
                                  trainerExp: trainer.experience,
                                  trainerType: trainer.trainingType,
                                  trainerClients: trainer.active_clients,
                                  trainingCompleted: trainer.training_completed,
                                  trainerRating: trainer.rating,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
                    width: double.infinity, height: 160, radius: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _skeletonBox(context,
                    width: double.infinity, height: 160, radius: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _skeletonBox(context, width: double.infinity, height: 194, radius: 16),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _skeletonBox(
    BuildContext context, {
    required double width,
    required double height,
    double radius = 8,
  }) {
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
                  Icon(
                    _tabs[i]['icon'] as IconData,
                    color: isSelected
                        ? (isDark ? themeColor : Colors.black)
                        : unselectedColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tabs[i]['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? (isDark ? themeColor : Colors.black)
                          : unselectedColor,
                      fontSize: 12,
                    ),
                  ),
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

class _OverviewTab extends StatefulWidget {
  const _OverviewTab();

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  String _username = '';

  @override
  void initState() {
    super.initState();
    _fetchUsername();
  }

  Future<void> _fetchUsername() async {
    final data = await SupabaseService.getUserProfile();
    if (mounted) {
      setState(() {
        _username = data?['username'] ?? 'User';
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetchUsername();
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hi, $_username!",
                        style: TextStyle(
                            color: isDark ? themeColor : Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "It's time to challenge your limits.",
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).textTheme.bodyLarge?.color),
                      ),
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
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const SettingHomePage(),
                          ));
                        },
                        child: Icon(Icons.settings,
                            color: isDark ? themeColor : Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(20),
              ),
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
                          const Text(
                            "Workout Today",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "let's achieve your target today",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Activity Summary",
                style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
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
                                        const Color.fromARGB(255, 0, 0, 0)!, BlendMode.srcIn)),
                                const SizedBox(width: 6),
                                Text("Steps",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color.fromARGB(255, 0, 0, 0))),
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
                                            color: isDark
                                                ? const Color.fromARGB(255, 210, 231, 16)
                                                : Colors.black,)),
                                    Text("/10000",
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: const Color.fromARGB(255, 0, 0, 0))),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                            "assets/icons/clock_icon.svg",
                                            width: 12,
                                            height: 12,
                                            colorFilter: ColorFilter.mode(
                                                const Color.fromARGB(255, 0, 0, 0)!,
                                                BlendMode.srcIn)),
                                        const SizedBox(width: 4),
                                        Text("Last",
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: const Color.fromARGB(255, 0, 0, 0))),
                                      ],
                                    ),
                                    Text("7 Days",
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: const Color.fromARGB(255, 0, 0, 0))),
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
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: themeColor,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  "assets/home/container-1-icon.png",
                                  height: 36,
                                  width: 36,
                                  fit: BoxFit.contain,
                                ),
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
                                        const Color.fromARGB(255, 0, 0, 0)!, BlendMode.srcIn)),
                                const SizedBox(width: 6),
                                Text("Calories",
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color.fromARGB(255, 0, 0, 0))),
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
                                            color: isDark
                                                ? const Color.fromARGB(255, 192, 207, 50)
                                                : Colors.black)),
                                    Text("/20000",
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: const Color.fromARGB(255, 0, 0, 0))),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        SvgPicture.asset(
                                            "assets/icons/clock_icon.svg",
                                            width: 12,
                                            height: 12,
                                            colorFilter: ColorFilter.mode(
                                                const Color.fromARGB(255, 0, 0, 0)!,
                                                BlendMode.srcIn)),
                                        const SizedBox(width: 4),
                                        Text("Last",
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: const Color.fromARGB(255, 0, 0, 0))),
                                      ],
                                    ),
                                    Text("7 Days",
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: const Color.fromARGB(255, 0, 0, 0))),
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
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: themeColor,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  "assets/home/container-2-icon.png",
                                  height: 36,
                                  width: 36,
                                  fit: BoxFit.contain,
                                ),
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
            const SizedBox(height: 20),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 194,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                            style:
                                TextStyle(color: Colors.black, fontSize: 17)),
                        const Spacer(),
                        SizedBox(
                          width: 100,
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
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
            const SizedBox(height: 20),
          ],
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
    return FadeTransition(
      opacity: _animation,
      child: widget.child,
    );
  }
}