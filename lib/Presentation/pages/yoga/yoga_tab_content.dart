import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_motivation_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_schedule_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_challenge_card.dart';
import 'package:get_fit/Presentation/pages/yoga/widgets/yoga_feed_card.dart';
import 'package:get_fit/Presentation/pages/newsfeed/newsfeed_page.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaTabContent extends StatefulWidget {
  const YogaTabContent({super.key});

  @override
  State<YogaTabContent> createState() => _YogaTabContentState();
}

class _YogaTabContentState extends State<YogaTabContent> {
  int _selectedTimeSlot = 0;

  final List<String> _timeSlots = ['Morning', 'Afternoon', 'Evening'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildHeader(context),
              const SizedBox(height: 20),
              const YogaMotivationCard(),
              const SizedBox(height: 24),
              _buildTimeSlotTabs(context),
              const SizedBox(height: 16),
              YogaScheduleCard(timeSlot: _timeSlots[_selectedTimeSlot]),
              const SizedBox(height: 24),
              const YogaChallengeCard(),
              const SizedBox(height: 24),
              const YogaFeedCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Yoga',
          style: TextStyle(
            color: isDark ? themeColor : Colors.black,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.search,
                color: textColor,
                size: 28,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.notifications_outlined,
                color: textColor,
                size: 28,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(
                Icons.settings_outlined,
                color: textColor,
                size: 28,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSlotTabs(BuildContext context) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: context.cardBgColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: List.generate(_timeSlots.length, (index) {
          final isSelected = _selectedTimeSlot == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTimeSlot = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? themeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: Text(
                    _timeSlots[index],
                    style: TextStyle(
                      color: isSelected ? Colors.black : context.subtextColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}