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
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            'Reviews',
            style: TextStyle(
              color: themeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xff232323),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Color(0xff2C2C2E),
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
                                      : Colors.white,
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
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  '${widget.rating}',
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      child: Column(
                        children: [
                          Container(
                              margin: EdgeInsets.only(top: 5),
                              color: Colors.white,
                              height: 5,
                              width: 177)
                        ],
                      ),
                    ),
                    Container(
                      child: Column(
                        children: [
                          Container(
                              margin: EdgeInsets.only(top: 5),
                              color: Colors.white,
                              height: 5,
                              width: 145)
                        ],
                      ),
                    ),
                    Container(
                      child: Column(
                        children: [
                          Container(
                              margin: EdgeInsets.only(top: 5),
                              color: Colors.white,
                              height: 5,
                              width: 100)
                        ],
                      ),
                    ),
                    Container(
                      child: Column(
                        children: [
                          Container(
                              margin: EdgeInsets.only(top: 5),
                              color: Colors.white,
                              height: 5,
                              width: 50)
                        ],
                      ),
                    ),
                    Container(
                      child: Column(
                        children: [
                          Container(
                              margin: EdgeInsets.only(top: 5),
                              color: Colors.white,
                              height: 5,
                              width: 30)
                        ],
                      ),
                    ),
                  ],
                )
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: const ReviewCard(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ReuseableButton(title: "Write a Review", onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => WriteReviewPage()));
                      }),
            ),
          ],
        ));
  }
}
