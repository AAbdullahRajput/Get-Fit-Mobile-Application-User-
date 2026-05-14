import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/challenge/challenge_detail_page.dart';
import 'package:get_fit/Utils/constants.dart';

class WeeklyChallengeHomePage extends StatelessWidget {
  const WeeklyChallengeHomePage({super.key});

  Widget _buildRoundSection(String title, int itemCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              color: themeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(35),
                ),
                color: Colors.white,
                child: ListTile(
                  leading: const Icon(
                    Icons.play_circle_fill,
                    color: Color(0xFFE53935),
                    size: 40,
                  ),
                  title: Text(
                    'Challenge ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: const Text(
                    '00:30',
                    style: TextStyle(color: Color(0xffA3A3A3)),
                  ),
                  trailing: const Text(
                    "Repetition 3x",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xffA3A3A3),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChallengeDetailPage(
                          title: 'Challenge ${index + 1}',
                          time: '00:30',
                          repetitions: '3x',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff232323),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Weekly Challenge',
          style: TextStyle(
            color: themeColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xff232323),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: themeColor),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/challenge/bg.jpg',
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 24),
            _buildRoundSection("Round 1", 3),
            const SizedBox(height: 24),
            _buildRoundSection("Round 2", 5),
          ],
        ),
      ),
    );
  }
}
