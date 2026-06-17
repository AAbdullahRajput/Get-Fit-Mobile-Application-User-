import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/newsfeed/newsfeed_detail_page.dart';
import 'package:get_fit/Utils/constants.dart';

class NewfeedCard extends StatelessWidget {
  const NewfeedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      width: 300,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.isDark ? Colors.white : Colors.grey[200],
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
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: context.isDark
                    ? const Color(0xff2f2f2f)
                    : const Color(0xff1A1A1A),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: ListTile(
                title: const Text(
                  "Workout of the Day (WOD)",
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  "Quick reels or carousels showing daily workout routines.",
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
                trailing: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NewsfeedDetailPage(),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.arrow_circle_right_sharp,
                    color: themeColor,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}