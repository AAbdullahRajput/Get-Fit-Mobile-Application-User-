import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
        const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text("Today's Schedule",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 20),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _yogaContainers("assets/home/yoga-img-1.png", "Plates"),
            _yogaContainers("assets/home/yoga-img-2.png", "HIT Express"),
            _yogaContainers("assets/home/yoga-img-3.png", "Evening Yoga"),
          ],
        ),
        const SizedBox(height: 20),
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
                      Text("Don't break the chain",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      // SizedBox(height: 10),
                      // Text(
                      //   "Yoga",
                      //   style: TextStyle(fontWeight: FontWeight.bold),
                      // ),
                      Text("You’ve done 3 of 5 workouts this week."),
                      Spacer(),
                      Icon(Icons.bubble_chart_rounded)
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: ClipRRect(
                    // Add this wrapper
                    borderRadius:
                        BorderRadius.circular(16), // Same radius as container
                    child: Image.asset(
                      "assets/home/yoga-handclosed-big-img.jpg",
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("News Feed",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold)),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NewsfeedPage(),
                    ),
                  );
                },
                child: const Icon(Icons.add_circle_outline_rounded,
                    color: Colors.white, size: 30),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 168,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child:
                      const Icon(Icons.image_outlined, size: 48, color: themeColor),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xff2f2f2f),
                    borderRadius: BorderRadius.only(
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
        ),
        const SizedBox(height: 20),
        Container(
          height: 168,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child:
                      const Icon(Icons.image_outlined, size: 48, color: themeColor),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xff2f2f2f),
                    borderRadius: BorderRadius.only(
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
        ),
      ],
    );
  }

  Widget _yogaContainers(String imgPath, String title) {
    return Container(
      height: 100,
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Image.asset(
            imgPath,
            height: 60,
            width: 60,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.clock, size: 12),
              Text("7:00AM",
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400)),
            ],
          ),
        ],
      ),
    );
  }
}
