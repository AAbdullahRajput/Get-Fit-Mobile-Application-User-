import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/yoga/challenge/challenge_detail_page.dart';
import 'package:get_fit/Utils/constants.dart';

class WeeklyChallengeHomePage extends StatefulWidget {
  const WeeklyChallengeHomePage({super.key});

  @override
  State<WeeklyChallengeHomePage> createState() => _WeeklyChallengeHomePageState();
}

class _WeeklyChallengeHomePageState extends State<WeeklyChallengeHomePage> {
  static bool _hasLoaded = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> round1Challenges = [
    {'title': 'Sun Salutation', 'time': '00:30', 'repetitions': '3x', 'level': 'Beginner'},
    {'title': 'Warrior Pose', 'time': '00:45', 'repetitions': '4x', 'level': 'Intermediate'},
    {'title': 'Tree Pose', 'time': '00:20', 'repetitions': '3x', 'level': 'Beginner'},
  ];

  final List<Map<String, dynamic>> round2Challenges = [
    {'title': 'Plank Hold', 'time': '01:00', 'repetitions': '3x', 'level': 'Intermediate'},
    {'title': 'Cobra Pose', 'time': '00:30', 'repetitions': '4x', 'level': 'Beginner'},
    {'title': 'Boat Pose', 'time': '00:45', 'repetitions': '3x', 'level': 'Advanced'},
    {'title': 'Camel Pose', 'time': '00:30', 'repetitions': '3x', 'level': 'Intermediate'},
    {'title': 'Child Pose', 'time': '00:20', 'repetitions': '2x', 'level': 'Beginner'},
  ];

  @override
  void initState() {
    super.initState();
    _hasLoaded = true;
    _isLoading = false;
  }

  Future<void> _onRefresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Weekly Challenge',
          style: TextStyle(
            color: themeColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: context.textColor),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        color: themeColor,
        backgroundColor: context.cardBgColor,
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/challenge/bg.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: themeColor,
                        size: 50,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '7 Day Challenge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Complete all rounds to earn rewards!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildRoundSection(context, "Round 1", round1Challenges),
              const SizedBox(height: 24),
              _buildRoundSection(context, "Round 2", round2Challenges),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundSection(BuildContext context, String title, List<Map<String, dynamic>> challenges) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  color: themeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${challenges.length} exercises',
                style: TextStyle(
                  fontSize: 12,
                  color: context.subtextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...challenges.map((challenge) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(35),
              ),
              color: context.cardBgColor,
              elevation: context.isDark ? 0 : 2,
              child: ListTile(
                leading: const Icon(
                  Icons.play_circle_fill,
                  color: themeColor,
                  size: 40,
                ),
                title: Text(
                  challenge['title'],
                  style: TextStyle(
                    color: context.textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 12,
                      color: context.subtextColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      challenge['time'],
                      style: TextStyle(
                        color: context.subtextColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        challenge['level'],
                        style: TextStyle(
                          color: themeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  challenge['repetitions'],
                  style: TextStyle(
                    fontSize: 14,
                    color: context.subtextColor,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChallengeDetailPage(
                        title: challenge['title'],
                        time: challenge['time'],
                        repetitions: challenge['repetitions'],
                        level: challenge['level'],
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}