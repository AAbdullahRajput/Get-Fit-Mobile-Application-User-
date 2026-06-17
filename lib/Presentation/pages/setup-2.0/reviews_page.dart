import 'package:flutter/material.dart';
import 'package:get_fit/Presentation/pages/setup-2.0/write_review_page.dart';
import 'package:get_fit/Presentation/widgets/reuseable_button.dart';
import 'package:get_fit/Presentation/widgets/review_card.dart';
import 'package:get_fit/Utils/constants.dart';

class ReviewsPage extends StatefulWidget {
  final String rating;

  const ReviewsPage({super.key, required this.rating});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  int selectedIndex = 0;

  final List<String> categories = ['Recent', 'Critical', 'Favourables'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 56),
                // Category Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: context.cardBgColor,
                  ),
                  height: 45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 45,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIndex = index;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                decoration: BoxDecoration(
                                  color: selectedIndex == index
                                      ? themeColor
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Center(
                                  child: Text(
                                    categories[index],
                                    style: TextStyle(
                                      color: selectedIndex == index
                                          ? Colors.black
                                          : context.textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Rating Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      widget.rating,
                      style: TextStyle(
                      color: context.isDark ? themeColor : Colors.black87,
                      fontSize: 45,
                      fontWeight: FontWeight.bold,
                    ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ratingBar(context, 177),
                        _ratingBar(context, 145),
                        _ratingBar(context, 100),
                        _ratingBar(context, 50),
                        _ratingBar(context, 30),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Reviews List
                Expanded(
                  child: ListView.builder(
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        child: ReviewCard(),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 26),
                  child: ReuseableButton(
                    title: "Write a Review",
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => WriteReviewPage()));
                    },
                  ),
                ),
              ],
            ),
          ),

          // Back button overlay
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                    backgroundColor: Colors.black54,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingBar(BuildContext context, double width) {
    return Container(
      margin: const EdgeInsets.only(top: 5),
      color: context.isDark ? Colors.white : context.textColor,
      height: 5,
      width: width,
    );
  }
}