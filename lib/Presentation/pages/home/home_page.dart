import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setting/setting_home_page.dart';
import 'package:get_fit/Presentation/widgets/yoga_navbar_item_content.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Domain/models/fitness_trainer_model.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/fitness_tainer_detail_page.dart';
import 'package:get_fit/Presentation/pages/runner/runner_page.dart';
import 'package:get_fit/Presentation/pages/gym/gym_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _tabs = const [
    {'label': 'Overview', 'icon': Icons.grid_view_rounded},
    {'label': 'Fitness', 'icon': Icons.fitness_center_outlined},
    {'label': 'Yoga', 'icon': Icons.self_improvement_outlined},
    {'label': 'Gym', 'icon': Icons.sports_gymnastics_outlined},
    {'label': 'Running', 'icon': Icons.directions_run_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _isLoading = false);
  }

  Widget _getTabContent(BuildContext context) {
    if (_isLoading) return _buildSkeleton(context);

    switch (_selectedTab) {
      case 0:
        return const _OverviewTab();
      case 1:
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Fitness Trainers',
                  style: TextStyle(
                    color: context.isDark ? Colors.white : Colors.black,
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
                        color: context.cardBgColor,
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
                                color: context.textColor, fontSize: 18),
                          ),
                          subtitle: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trainer.trainingType,
                                style: TextStyle(
                                    color: context.subtextColor,
                                    fontSize: 14),
                              ),
                              Text(
                                '${trainer.experience} years experience',
                                style: TextStyle(
                                    color: context.textColor, fontSize: 14),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Icon(Icons.arrow_forward,
                                  color: context.textColor),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: themeColor,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(trainer.rating,
                                    style: const TextStyle(
                                        color: Colors.black)),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    FitnessTrainerDetailPage(
                                  bgImg: trainer.bg_img,
                                  trainerName: trainer.name,
                                  trainerExp: trainer.experience,
                                  trainerType: trainer.trainingType,
                                  trainerClients: trainer.active_clients,
                                  trainingCompleted:
                                      trainer.training_completed,
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
      case 2:
        return const SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: YogaNavbarItemContent(),
        );
      case 3:
        return const GymPage();
      case 4:
        return const RunnerPage();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSkeleton(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
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

          // Banner skeleton
          _skeletonBox(context, width: double.infinity, height: 77, radius: 20),
          const SizedBox(height: 30),

          // Activity summary title
          _skeletonBox(context, width: 160, height: 22),
          const SizedBox(height: 20),

          // Two stat cards skeleton
          Row(
            children: [
              Expanded(
                child: _skeletonBox(context,
                    width: double.infinity, height: 120, radius: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _skeletonBox(context,
                    width: double.infinity, height: 120, radius: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Upcoming class card skeleton
          _skeletonBox(context,
              width: double.infinity, height: 194, radius: 16),
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
          color: context.isDark
              ? const Color(0xff3a3a3a)
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: context.subtextColor,
          backgroundColor: context.cardBgColor,
          displacement: 100,
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  80,
              child: _getTabContent(context),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: context.navBgColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (i) {
            final isSelected = _selectedTab == i;
            return GestureDetector(
              onTap: () => setState(() {
                _selectedTab = i;
                _isLoading = true;
                _loadData();
              }),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _tabs[i]['icon'] as IconData,
                    color: isSelected
                        ? themeColor
                        : context.navUnselectedColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tabs[i]['label'] as String,
                    style: TextStyle(
                      color:
                          isSelected ? themeColor : context.subtextColor,
                      fontSize: 12,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 40,
                      height: 2,
                      color: themeColor,
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

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                        "Hi, Johns!",
                        style: TextStyle(
                            color:
                                context.isDark ? themeColor : Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "It's time to challenge your limits.",
                        style: TextStyle(
                            fontSize: 13, color: context.textColor),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.search,
                          color: context.isDark ? themeColor : Colors.black),
                      const SizedBox(width: 10),
                      Icon(Icons.notifications,
                          color: context.isDark ? themeColor : Colors.black),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const SettingHomePage(),
                          ));
                        },
                        child: Icon(Icons.settings,
                            color:
                                context.isDark ? themeColor : Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 77,
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                leading: Image.asset("assets/home/fire.png",
                    width: 50, height: 50),
                title: const Text("Workout Today",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: const Text(
                  "let's achieve your target today",
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text("Activity Summary",
                  style: TextStyle(
                      color: context.textColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 120,
                        padding:
                            const EdgeInsets.fromLTRB(16, 36, 16, 16),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? Colors.white
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text("10000",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                const SizedBox(width: 8),
                                Text("Steps",
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600])),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.refresh,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text("Last 7 Days",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600])),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.iconBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: themeColor,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  "assets/home/container-1-icon.png",
                                  height: 24,
                                  width: 24,
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
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 120,
                        padding:
                            const EdgeInsets.fromLTRB(16, 36, 16, 16),
                        decoration: BoxDecoration(
                          color: context.isDark
                              ? Colors.white
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text("1500",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                const SizedBox(width: 8),
                                Text("Calories",
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600])),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.refresh,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text("Last 7 Days",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600])),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: -20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.iconBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: themeColor,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  "assets/home/container-2-icon.png",
                                  height: 24,
                                  width: 24,
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        const Text("Yoga",
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        const Text("Time: 2h:20m"),
                        const Spacer(),
                        SizedBox(
                          width: 75,
                          height: 30,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text("Join",
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
    );
  }
}

// Shimmer animation widget
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