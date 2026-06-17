import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setting/setting_home_page.dart';
import 'package:get_fit/Presentation/widgets/yoga_navbar_item_content.dart';
import 'package:get_fit/Utils/constants.dart';
import 'package:get_fit/Domain/models/fitness_trainer_model.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/fitness_tainer_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0;

  final List<Map<String, dynamic>> _tabs = const [
    {'label': 'Overview', 'icon': Icons.grid_view_rounded},
    {'label': 'Fitness', 'icon': Icons.fitness_center_outlined},
    {'label': 'Yoga', 'icon': Icons.self_improvement_outlined},
    {'label': 'Gym', 'icon': Icons.sports_gymnastics_outlined},
    {'label': 'Running', 'icon': Icons.directions_run_outlined},
  ];

  Widget _getTabContent(BuildContext context) {
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
                        color: const Color(0xff2f2f2f),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          leading: CircleAvatar(
                            backgroundColor: themeColor,
                            radius: 30,
                            backgroundImage: NetworkImage(trainer.image),
                          ),
                          title: Text(
                            trainer.name,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18),
                          ),
                          subtitle: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trainer.trainingType,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 14),
                              ),
                              Text(
                                '${trainer.experience} years experience',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              const Icon(Icons.arrow_forward,
                                  color: Colors.white),
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
      case 2:
        return const SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: YogaNavbarItemContent(),
        );
      case 3:
        return Center(
            child: Text('Gym Coming Soon',
                style: TextStyle(color: context.textColor)));
      case 4:
        return Center(
            child: Text('Running Coming Soon',
                style: TextStyle(color: context.textColor)));
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: _getTabContent(context),
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
              onTap: () => setState(() => _selectedTab = i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _tabs[i]['icon'] as IconData,
                    color: isSelected ? themeColor : context.navUnselectedColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _tabs[i]['label'] as String,
                    style: TextStyle(
                      color: isSelected ? themeColor : context.subtextColor,
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
                            color: context.isDark ? themeColor : Colors.black,
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
                            color: context.isDark ? themeColor : Colors.black),
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
                        padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
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
                        padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
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
                            style:
                                TextStyle(fontWeight: FontWeight.bold)),
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