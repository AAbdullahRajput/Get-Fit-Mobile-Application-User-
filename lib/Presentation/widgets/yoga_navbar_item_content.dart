import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/newsfeed/newsfeed_page.dart';
import 'package:get_fit/Utils/constants.dart';

class YogaNavbarItemContent extends StatelessWidget {
  const YogaNavbarItemContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            "Today's Schedule",
            style: TextStyle(
              color: context.textColor,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _yogaContainers(context, "assets/home/yoga-img-1.png", "Pilates"),
            _yogaContainers(context, "assets/home/yoga-img-2.png", "HIT Express"),
            _yogaContainers(context, "assets/home/yoga-img-3.png", "Evening Yoga"),
          ],
        ),
        const SizedBox(height: 20),
        // Motivation Card
        Container(
          height: 194,
          width: double.infinity,
          decoration: BoxDecoration(
            color: themeColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Don't break the chain",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "You've done 3 of 5 workouts this week.",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.bubble_chart_rounded, color: Colors.black54),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: Image.asset(
                    "assets/home/yoga-handclosed-big-img.jpg",
                    height: 194,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // News Feed Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "News Feed",
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NewsfeedPage(),
                    ),
                  );
                },
                child: Icon(
                  Icons.add_circle_outline_rounded,
                  color: context.textColor,
                  size: 30,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _newsCard(context),
        const SizedBox(height: 16),
        _newsCard(context),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _newsCard(BuildContext context) {
    return Container(
      height: 168,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: context.cardBgColor,
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xff3a3a3a)
                    : Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Icon(
                Icons.image_outlined,
                size: 48,
                color: context.isDark ? themeColor : Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xff2f2f2f)
                    : const Color(0xff2a2a2a),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: const ListTile(
                title: Text(
                  "Workout of the Day (WOD)",
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  "Quick reels or carousels showing daily workout routines.",
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
                trailing: Icon(
                  Icons.arrow_circle_right_sharp,
                  color: themeColor,
                  size: 48,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _yogaContainers(BuildContext context, String imgPath, String title) {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: context.isDark ? const Color(0xff2f2f2f) : Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.textColor,
            ),
          ),
          Image.asset(
            imgPath,
            height: 55,
            width: 55,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.clock,
                size: 11,
                color: context.subtextColor,
              ),
              const SizedBox(width: 2),
              Text(
                "7:00AM",
                style: TextStyle(
                  fontSize: 11,
                  color: context.subtextColor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}